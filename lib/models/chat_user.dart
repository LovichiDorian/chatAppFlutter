class ChatUser {
  final String id;
  final String displayName;
  final String email;
  final String bio;
  final String avatarUrl;
  
  // Statut en ligne
  final bool isOnline;
  final DateTime? lastSeen;
  
  // Indicateur de frappe
  final bool isTyping;
  final String? typingTo; // ID de l'utilisateur à qui on écrit

  const ChatUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.bio = '',
    this.avatarUrl = '',
    this.isOnline = false,
    this.lastSeen,
    this.isTyping = false,
    this.typingTo,
  });

  factory ChatUser.fromMap(Map<String, dynamic> data) {
    return ChatUser(
      id: data['id'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      bio: data['bio'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      isOnline: (data['isOnline'] ?? false) as bool,
      lastSeen: data['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastSeen'] as int)
          : null,
      isTyping: (data['isTyping'] ?? false) as bool,
      typingTo: data['typingTo'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'displayName': displayName,
    'email': email,
    'bio': bio,
    'avatarUrl': avatarUrl,
    'isOnline': isOnline,
    if (lastSeen != null) 'lastSeen': lastSeen!.millisecondsSinceEpoch,
    'isTyping': isTyping,
    if (typingTo != null) 'typingTo': typingTo,
  };
  
  /// Retourne le texte du statut (En ligne, Il y a X minutes, etc.)
  String get statusText {
    if (isOnline) return 'En ligne';
    if (lastSeen == null) return 'Hors ligne';
    
    final now = DateTime.now();
    final diff = now.difference(lastSeen!);
    
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    
    return 'Il y a longtemps';
  }
  
  ChatUser copyWith({
    String? id,
    String? displayName,
    String? email,
    String? bio,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isTyping,
    String? typingTo,
  }) {
    return ChatUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isTyping: isTyping ?? this.isTyping,
      typingTo: typingTo ?? this.typingTo,
    );
  }
}
