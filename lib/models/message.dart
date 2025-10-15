class Message {
  final String id;
  final String from;
  final String to;
  final String content;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.from,
    required this.to,
    required this.content,
    required this.timestamp,
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
    );
  }

  Map<String, dynamic> toMap() => {
        'from': from,
        'to': to,
        'content': content,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };
}
