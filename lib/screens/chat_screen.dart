// =============================================================
//  Chat Screen — Flutter UI with Full AI Pipeline Integration
//
//  Features:
//    - Asynchronous ONNX model inference
//    - Message history with scroll management
//    - Typing/loading indicator during AI processing
//    - Assessment context banner
//    - Smooth, natural chat experience
//    - Crisis detection with immediate response
//    - Chat session persistence via SQLite
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../chat/chat_service.dart';
import '../providers/auth_provider.dart';
import '../database/db_helper.dart';
import '../models/chat_session.dart';

class ChatScreen extends StatefulWidget {
  final String? initialMessage;
  final int? assessmentScore;
  final String? assessmentType;
  final String? severityLevel;

  const ChatScreen({
    Key? key,
    this.initialMessage,
    this.assessmentScore,
    this.assessmentType,
    this.severityLevel,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  late ChatService _chatService;
  bool _isInitializing = true;
  bool _isTyping = false;

  // DB session tracking
  int? _sessionID;
  int? _userID;

  @override
  void initState() {
    super.initState();
    _initializeChatService();
  }

  Future<void> _initializeChatService() async {
    // Grab the current user so we can persist messages
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _userID = auth.currentUser?.userID;

    // Create the appropriate chat service
    if (widget.assessmentType != null) {
      _chatService = ChatService.fromAssessment(
        assessmentType: widget.assessmentType!,
        score: widget.assessmentScore ?? 0,
        severityLevel: widget.severityLevel ?? 'Unknown',
      );
    } else {
      _chatService = ChatService();
    }

    // Initialize the AI model
    await _chatService.initialize();

    if (!mounted) return;

    // NOTE: We do NOT create a DB session here.
    // The session is created lazily on the first user message,
    // so empty sessions are never stored.

    // Add the greeting message to UI only (not persisted yet)
    final greeting = _chatService.getGreeting();
    setState(() {
      _messages.insert(0, greeting);
      _isInitializing = false;
    });

    // If launched from assessment, auto-send the initial message
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      _processUserMessage(widget.initialMessage!);
    }
  }

  /// Creates the DB session on the very first user message (lazy init).
  Future<void> _ensureSessionExists(String firstUserMessage) async {
    if (_sessionID != null || _userID == null) return;
    final now = DateTime.now().toIso8601String();
    // Use the first user message as the conversation preview/title
    final preview = firstUserMessage.length > 80
        ? '${firstUserMessage.substring(0, 80)}…'
        : firstUserMessage;
    final session = await DatabaseHelper.instance.createChatSession(
      ChatSession(
        userID: _userID!,
        startedAt: now,
        lastMessageAt: now,
        preview: preview,
      ),
    );
    _sessionID = session.sessionID;

    // Persist the greeting bot message that is already shown in UI
    final greetingRecord = _messages.lastOrNull;
    if (greetingRecord != null && !greetingRecord.isUser) {
      await DatabaseHelper.instance.createChatMessage(ChatMessageRecord(
        sessionID: _sessionID!,
        isUser: false,
        text: greetingRecord.text,
        sentAt: now,
      ));
    }
  }

  /// Save a single [ChatMessage] to the database under the current session.
  /// Does nothing if no session has been created yet (i.e., no user message sent).
  Future<void> _persistMessage(ChatMessage msg) async {
    if (_sessionID == null || _userID == null) return;
    final now = msg.timestamp?.toIso8601String() ?? DateTime.now().toIso8601String();
    await DatabaseHelper.instance.createChatMessage(ChatMessageRecord(
      sessionID: _sessionID!,
      isUser: msg.isUser,
      text: msg.text,
      sentAt: now,
      emotion: msg.diagnosis?.label,
      confidence: msg.diagnosis?.confidence,
    ));
    // Keep the session's lastMessageAt fresh so history list sorts correctly
    await DatabaseHelper.instance.updateChatSession(
      _sessionID!,
      lastMessageAt: now,
    );
  }

  Future<void> _processUserMessage(String text) async {
    // Add user message to UI
    final userMsg = ChatMessage(text: text, isUser: true);
    setState(() {
      _messages.insert(0, userMsg);
      _isTyping = true;
    });

    // Lazily create the session on the very first user message
    await _ensureSessionExists(text);

    // Persist user message
    _persistMessage(userMsg);

    // Scroll to bottom
    _scrollToBottom();

    // Process through AI pipeline (runs asynchronously)
    final response = await _chatService.processMessage(text);

    if (!mounted) return;

    // Add bot response to UI
    setState(() {
      _isTyping = false;
      _messages.insert(0, response);
    });

    // Persist bot response
    _persistMessage(response);

    _scrollToBottom();

    // ── CRISIS ALERT ──────────────────────────────────────────
    // Show a prominent alert dialog when dangerous/crisis content
    // is detected so the user cannot miss the safety resources.
    if (response.diagnosis?.isCrisis == true ||
        _chatService.context.crisisDetected) {
      _showCrisisAlert();
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

    _messageController.clear();
    _processUserMessage(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Shows a prominent crisis alert dialog with emergency contacts.
  void _showCrisisAlert() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: Colors.red.shade600, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'We Care About You',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'It sounds like you may be going through a really difficult time. '
              'You deserve support from someone who can truly help.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _crisisContactRow(Icons.phone, 'KSA Ministry of Health',
                      '920033360'),
                  const SizedBox(height: 8),
                  _crisisContactRow(
                      Icons.language, 'Find a Helpline', 'findahelpline.com'),
                  const SizedBox(height: 8),
                  _crisisContactRow(Icons.textsms, 'Crisis Text Line',
                      'Text HOME to 741741'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A trained counselor can provide the support you need right now.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  Widget _crisisContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.red.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Support Chat'),
        automaticallyImplyLeading: true,
        actions: [
          if (!_isInitializing)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _chatService.isInitialized
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Context banner when launched from assessment results
            if (widget.assessmentType != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Discussing your ${widget.assessmentType} results — '
                        'Score: ${widget.assessmentScore} (${widget.severityLevel})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Disclaimer banner
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.amber.withOpacity(0.1),
              child: Text(
                'AI companion, not a medical professional. '
                'In crisis? Visit findahelpline.com or call KSA: 920033360.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.amber.shade800,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Messages list
            Expanded(
              child: _isInitializing
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading AI model...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isTyping && index == 0) {
                          return _buildTypingIndicator();
                        }
                        final msgIndex = _isTyping ? index - 1 : index;
                        return _buildChatBubble(_messages[msgIndex]);
                      },
                    ),
            ),

            // Input area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // ── Chat Bubble ──────────────────────────────────────────────

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
              child: Icon(
                Icons.psychology_alt,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Typing Indicator ─────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.15),
            child: Icon(
              Icons.psychology_alt,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.4),
            ),
          ),
        );
      },
    );
  }

  // ── Input Area ───────────────────────────────────────────────

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_isInitializing,
              decoration: InputDecoration(
                hintText: _isInitializing
                    ? 'Loading...'
                    : 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: (_isTyping || _isInitializing)
                ? Colors.grey
                : Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: (_isTyping || _isInitializing) ? null : _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: Icon(
                  Icons.send_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
