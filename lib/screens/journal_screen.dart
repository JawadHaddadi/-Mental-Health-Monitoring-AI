import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../database/db_helper.dart';
import '../models/journal_entry.dart';
import '../models/nlp_result.dart';
import '../ai/diagnostic_service.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _textController = TextEditingController();
  bool _isSaving = false;
  List<JournalEntry> _entries = [];
  MentalHealthDiagnosticService? _diagnosticService;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _textController.dispose();
    _diagnosticService?.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      final results = await DatabaseHelper.instance.getUserJournalEntries(user.userID!);
      setState(() {
        _entries = results;
      });
    } else {
      setState(() {
        _entries = [];
      });
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _saveEntry() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSaving = true);
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    if (user != null) {
      final now = DateTime.now().toIso8601String();
      final entry = JournalEntry(
        userID: user.userID!,
        text: text,
        date: now,
      );

      final savedEntry = await DatabaseHelper.instance.createJournalEntry(entry);

      // Run real AI emotion analysis via ONNX model
      String detectedEmotion = 'Neutral';
      double detectedConfidence = 0.5;

      try {
        // Reuse a single diagnostic service instance across saves
        _diagnosticService ??= MentalHealthDiagnosticService();
        if (!_diagnosticService!.isReady) {
          await _diagnosticService!.initialize();
        }
        final result = await _diagnosticService!.diagnose(text);

        // Map diagnostic label to mood tracker emotion categories
        switch (result.dominantEmotion) {
          case 'stress':
          case 'anxiety':
            detectedEmotion = 'Anxiety';
            break;
          case 'depression':
            detectedEmotion = 'Sadness';
            break;
          case 'positive':
            detectedEmotion = 'Joy';
            break;
          case 'crisis':
            detectedEmotion = 'Sadness';
            break;
          default:
            detectedEmotion = 'Neutral';
        }
        detectedConfidence = result.confidence;
      } catch (e) {
        debugPrint('NLP analysis error: $e');
        // Fallback to neutral if model fails
      }

      await DatabaseHelper.instance.createNLPResult(NLPResult(
        entryID: savedEntry.entryID!,
        emotion: detectedEmotion,
        confidence: detectedConfidence,
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journal entry saved successfully!')),
      );
      _textController.clear();
      _loadEntries(); // Reload entries after saving
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Journal Entry'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'How are you feeling right now?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Write your thoughts here...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveEntry,
                    icon: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: Text(_isSaving ? 'Saving...' : 'Save Entry'),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Past Entries',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_entries.isEmpty)
                  const Text('No entries yet.')
                else
                  ...List.generate(_entries.length, (index) {
                    final entry = _entries[index];
                    final preview = entry.text.length > 60
                        ? '${entry.text.substring(0, 60)}...'
                        : entry.text;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(Icons.book, color: Colors.blue.shade700),
                        ),
                        title: Text(
                          preview,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          _formatDate(entry.date),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
