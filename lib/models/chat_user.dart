class ChatUser {
  final String id;
  final String displayName;
  final String email;
  final String bio;
  final String avatarUrl;

  const ChatUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.bio = '',
    this.avatarUrl = '',
  });

  factory ChatUser.fromMap(Map<String, dynamic> data) {
    return ChatUser(
      id: data['id'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      bio: data['bio'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'email': email,
        'bio': bio,
        'avatarUrl': avatarUrl,
      };
}
