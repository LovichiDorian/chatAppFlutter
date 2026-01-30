import 'dart:math';

class Group {
  final String id;
  final String name;
  final String description;
  final String avatarUrl;
  final String createdBy; // ID du créateur
  final DateTime createdAt;
  final List<String> members; // Liste des IDs des membres
  final List<String> admins; // Liste des IDs des admins
  final String inviteCode; // Code d'invitation unique
  final bool isPublic; // Groupe public ou privé
  
  // Dernier message pour l'affichage dans la liste
  final String? lastMessage;
  final String? lastMessageFrom;
  final DateTime? lastMessageAt;

  const Group({
    required this.id,
    required this.name,
    this.description = '',
    this.avatarUrl = '',
    required this.createdBy,
    required this.createdAt,
    required this.members,
    required this.admins,
    required this.inviteCode,
    this.isPublic = false,
    this.lastMessage,
    this.lastMessageFrom,
    this.lastMessageAt,
  });

  /// Génère un code d'invitation unique
  static String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Génère le lien d'invitation interne
  String get inviteLink => 'chatapp://group/join/$inviteCode';
  
  /// Lien d'invitation pour le partage (format texte)
  String get shareableInviteText => 
      'Rejoins le groupe "$name" sur ChatApp !\n\n'
      'Code d\'invitation : $inviteCode\n'
      'Ou utilise ce lien : $inviteLink';

  /// Vérifie si un utilisateur est membre
  bool isMember(String userId) => members.contains(userId);

  /// Vérifie si un utilisateur est admin
  bool isAdmin(String userId) => admins.contains(userId);

  /// Vérifie si un utilisateur est le créateur
  bool isCreator(String userId) => createdBy == userId;

  /// Nombre de membres
  int get memberCount => members.length;

  factory Group.fromMap(String id, Map<String, dynamic> data) {
    return Group(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      members: List<String>.from(data['members'] ?? []),
      admins: List<String>.from(data['admins'] ?? []),
      inviteCode: data['inviteCode'] ?? '',
      isPublic: data['isPublic'] ?? false,
      lastMessage: data['lastMessage'] as String?,
      lastMessageFrom: data['lastMessageFrom'] as String?,
      lastMessageAt: data['lastMessageAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastMessageAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'avatarUrl': avatarUrl,
    'createdBy': createdBy,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'members': members,
    'admins': admins,
    'inviteCode': inviteCode,
    'isPublic': isPublic,
    if (lastMessage != null) 'lastMessage': lastMessage,
    if (lastMessageFrom != null) 'lastMessageFrom': lastMessageFrom,
    if (lastMessageAt != null) 'lastMessageAt': lastMessageAt!.millisecondsSinceEpoch,
  };

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarUrl,
    String? createdBy,
    DateTime? createdAt,
    List<String>? members,
    List<String>? admins,
    String? inviteCode,
    bool? isPublic,
    String? lastMessage,
    String? lastMessageFrom,
    DateTime? lastMessageAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
      admins: admins ?? this.admins,
      inviteCode: inviteCode ?? this.inviteCode,
      isPublic: isPublic ?? this.isPublic,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageFrom: lastMessageFrom ?? this.lastMessageFrom,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}

/// Message de groupe (similaire à Message mais pour les groupes)
class GroupMessage {
  final String id;
  final String groupId;
  final String from;
  final String fromName; // Nom de l'expéditeur (pour affichage)
  final String content;
  final DateTime timestamp;
  final String type; // 'text' | 'image' | 'system'
  final String? mediaUrl;
  final bool isDeleted;
  final Map<String, List<String>> reactions;
  
  // Réponse
  final String? replyToId;
  final String? replyToContent;
  final String? replyToFrom;

  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.from,
    required this.fromName,
    required this.content,
    required this.timestamp,
    this.type = 'text',
    this.mediaUrl,
    this.isDeleted = false,
    this.reactions = const {},
    this.replyToId,
    this.replyToContent,
    this.replyToFrom,
  });

  factory GroupMessage.fromMap(String id, Map<String, dynamic> data) {
    Map<String, List<String>> reactionsMap = {};
    if (data['reactions'] is Map) {
      final raw = data['reactions'] as Map;
      raw.forEach((key, value) {
        if (value is List) {
          reactionsMap[key.toString()] = List<String>.from(value);
        }
      });
    }

    return GroupMessage(
      id: id,
      groupId: data['groupId'] ?? '',
      from: data['from'] ?? '',
      fromName: data['fromName'] ?? '',
      content: data['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      type: data['type'] ?? 'text',
      mediaUrl: data['mediaUrl'] as String?,
      isDeleted: data['isDeleted'] ?? false,
      reactions: reactionsMap,
      replyToId: data['replyToId'] as String?,
      replyToContent: data['replyToContent'] as String?,
      replyToFrom: data['replyToFrom'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'groupId': groupId,
    'from': from,
    'fromName': fromName,
    'content': content,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'type': type,
    if (mediaUrl != null) 'mediaUrl': mediaUrl,
    'isDeleted': isDeleted,
    'reactions': reactions,
    if (replyToId != null) 'replyToId': replyToId,
    if (replyToContent != null) 'replyToContent': replyToContent,
    if (replyToFrom != null) 'replyToFrom': replyToFrom,
  };

  bool hasReaction(String emoji, String userId) {
    return reactions[emoji]?.contains(userId) ?? false;
  }
}
