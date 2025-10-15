class Chat {
  final String id;
  final List<String> members; // two user ids for 1-1 chat

  const Chat({required this.id, required this.members});

  factory Chat.fromMap(String id, Map<String, dynamic> data) =>
      Chat(id: id, members: List<String>.from(data['members'] ?? const []));

  Map<String, dynamic> toMap() => {'members': members};
}
