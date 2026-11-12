/// Represents a single chat session (conversation) between the user and the AI.
class ChatSession {
  final int? sessionID;
  final int userID;
  final String startedAt;
  final String? lastMessageAt;
  final String? preview; // First user message snippet for the history list

  ChatSession({
    this.sessionID,
    required this.userID,
    required this.startedAt,
    this.lastMessageAt,
    this.preview,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionID': sessionID,
      'userID': userID,
      'startedAt': startedAt,
      'lastMessageAt': lastMessageAt,
      'preview': preview,
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      sessionID: map['sessionID'] as int?,
      userID: map['userID'] as int,
      startedAt: map['startedAt'] as String,
      lastMessageAt: map['lastMessageAt'] as String?,
      preview: map['preview'] as String?,
    );
  }

  ChatSession copyWith({
    int? sessionID,
    int? userID,
    String? startedAt,
    String? lastMessageAt,
    String? preview,
  }) {
    return ChatSession(
      sessionID: sessionID ?? this.sessionID,
      userID: userID ?? this.userID,
      startedAt: startedAt ?? this.startedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      preview: preview ?? this.preview,
    );
  }
}

/// Represents a single message within a [ChatSession].
class ChatMessageRecord {
  final int? messageID;
  final int sessionID;
  final bool isUser;  // true = user sent, false = bot sent
  final String text;
  final String sentAt;
  final String? emotion; // detected emotion label, if any
  final double? confidence; // AI confidence score (0.0 – 1.0)

  ChatMessageRecord({
    this.messageID,
    required this.sessionID,
    required this.isUser,
    required this.text,
    required this.sentAt,
    this.emotion,
    this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageID': messageID,
      'sessionID': sessionID,
      'isUser': isUser ? 1 : 0,
      'text': text,
      'sentAt': sentAt,
      'emotion': emotion,
      'confidence': confidence,
    };
  }

  factory ChatMessageRecord.fromMap(Map<String, dynamic> map) {
    return ChatMessageRecord(
      messageID: map['messageID'] as int?,
      sessionID: map['sessionID'] as int,
      isUser: (map['isUser'] as int) == 1,
      text: map['text'] as String,
      sentAt: map['sentAt'] as String,
      emotion: map['emotion'] as String?,
      confidence: (map['confidence'] as num?)?.toDouble(),
    );
  }
}
