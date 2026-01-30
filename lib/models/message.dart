class Message {
  final String id;
  final String from;
  final String to;
  final String content; // text content or caption
  final DateTime timestamp;

  // Type de message
  final String type; // 'text' | 'image' | 'audio' | 'file'
  final String? mediaUrl; // download URL for media
  
  // Suppression
  final bool isDeleted; // globally deleted (tombstone)
  final List<String> deletedFor; // hidden for specific users (local delete)
  
  // Réponse à un message
  final String? replyToId; // ID du message auquel on répond
  final String? replyToContent; // Contenu du message original (pour affichage)
  final String? replyToFrom; // ID de l'expéditeur du message original
  
  // Réactions (map: emoji -> liste des userIds)
  final Map<String, List<String>> reactions;
  
  // Statut de lecture
  final bool isRead;
  final DateTime? readAt;

  const Message({
    required this.id,
    required this.from,
    required this.to,
    required this.content,
    required this.timestamp,
    this.type = 'text',
    this.mediaUrl,
    this.isDeleted = false,
    this.deletedFor = const [],
    this.replyToId,
    this.replyToContent,
    this.replyToFrom,
    this.reactions = const {},
    this.isRead = false,
    this.readAt,
  });

  factory Message.fromMap(String id, Map<String, dynamic> data) {
    // Parse reactions
    Map<String, List<String>> reactionsMap = {};
    if (data['reactions'] is Map) {
      final raw = data['reactions'] as Map;
      raw.forEach((key, value) {
        if (value is List) {
          reactionsMap[key.toString()] = List<String>.from(value);
        }
      });
    }
    
    return Message(
      id: id,
      from: data['from'] ?? '',
      to: data['to'] ?? '',
      content: data['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (data['timestamp'] ?? 0) is int
            ? data['timestamp'] as int
            : int.tryParse('${data['timestamp']}') ?? 0,
      ),
      type: (data['type'] ?? 'text') as String,
      mediaUrl: (data['mediaUrl'] as String?)?.isEmpty == true
          ? null
          : data['mediaUrl'] as String?,
      isDeleted: (data['isDeleted'] ?? false) as bool,
      deletedFor: (data['deletedFor'] is List)
          ? List<String>.from(data['deletedFor'] as List)
          : const [],
      replyToId: data['replyToId'] as String?,
      replyToContent: data['replyToContent'] as String?,
      replyToFrom: data['replyToFrom'] as String?,
      reactions: reactionsMap,
      isRead: (data['isRead'] ?? false) as bool,
      readAt: data['readAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['readAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'from': from,
    'to': to,
    'content': content,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'type': type,
    if (mediaUrl != null) 'mediaUrl': mediaUrl,
    'isDeleted': isDeleted,
    'deletedFor': deletedFor,
    if (replyToId != null) 'replyToId': replyToId,
    if (replyToContent != null) 'replyToContent': replyToContent,
    if (replyToFrom != null) 'replyToFrom': replyToFrom,
    'reactions': reactions,
    'isRead': isRead,
    if (readAt != null) 'readAt': readAt!.millisecondsSinceEpoch,
  };
  
  /// Copie le message avec des modifications
  Message copyWith({
    String? id,
    String? from,
    String? to,
    String? content,
    DateTime? timestamp,
    String? type,
    String? mediaUrl,
    bool? isDeleted,
    List<String>? deletedFor,
    String? replyToId,
    String? replyToContent,
    String? replyToFrom,
    Map<String, List<String>>? reactions,
    bool? isRead,
    DateTime? readAt,
  }) {
    return Message(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedFor: deletedFor ?? this.deletedFor,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToFrom: replyToFrom ?? this.replyToFrom,
      reactions: reactions ?? this.reactions,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }
  
  /// Vérifie si l'utilisateur a réagi avec un emoji spécifique
  bool hasReaction(String emoji, String userId) {
    return reactions[emoji]?.contains(userId) ?? false;
  }
  
  /// Compte total des réactions
  int get totalReactions {
    int count = 0;
    reactions.forEach((_, users) => count += users.length);
    return count;
  }
}
