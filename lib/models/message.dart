class Message {
  final String id;
  final String from;
  final String to;
  final String content; // text content or caption
  final DateTime timestamp;

  // New fields for additional features
  final String type; // 'text' | 'image' | 'audio' | 'file'
  final String? mediaUrl; // download URL for media
  final bool isDeleted; // globally deleted (tombstone)
  final List<String> deletedFor; // hidden for specific users (local delete)

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
  });

  factory Message.fromMap(String id, Map<String, dynamic> data) {
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
  };
}
