import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/group.dart';
import '../models/chat_user.dart';

class GroupViewModel extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final String currentUserId;
  final String currentUserName;

  GroupViewModel({
    FirebaseFirestore? db,
    FirebaseStorage? storage,
    required this.currentUserId,
    required this.currentUserName,
  }) : _db = db ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  // ============ COLLECTIONS ============
  
  CollectionReference get _groupsCollection => _db.collection('groups');
  
  CollectionReference _messagesCollection(String groupId) =>
      _db.collection('groups').doc(groupId).collection('messages');

  // ============ GROUPES ============

  /// Créer un nouveau groupe
  Future<Group> createGroup({
    required String name,
    String description = '',
    List<String> initialMembers = const [],
  }) async {
    final docRef = _groupsCollection.doc();
    final inviteCode = Group.generateInviteCode();
    
    final allMembers = [currentUserId, ...initialMembers].toSet().toList();
    
    final group = Group(
      id: docRef.id,
      name: name,
      description: description,
      createdBy: currentUserId,
      createdAt: DateTime.now(),
      members: allMembers,
      admins: [currentUserId], // Le créateur est admin
      inviteCode: inviteCode,
      isPublic: false,
    );
    
    await docRef.set(group.toMap());
    
    // Envoyer un message système
    await _sendSystemMessage(
      groupId: docRef.id,
      content: '$currentUserName a créé le groupe',
    );
    
    return group;
  }

  /// Stream des groupes de l'utilisateur
  Stream<List<Group>> myGroupsStream() {
    return _groupsCollection
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .map((snap) {
          final groups = snap.docs
              .map((d) => Group.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();
          // Tri côté client pour éviter l'index composite Firestore
          groups.sort((a, b) {
            final aTime = a.lastMessageAt ?? a.createdAt;
            final bTime = b.lastMessageAt ?? b.createdAt;
            return bTime.compareTo(aTime); // Ordre décroissant
          });
          return groups;
        });
  }

  /// Obtenir un groupe par son ID
  Future<Group?> getGroup(String groupId) async {
    final doc = await _groupsCollection.doc(groupId).get();
    if (!doc.exists) return null;
    return Group.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Stream d'un groupe spécifique
  Stream<Group?> groupStream(String groupId) {
    return _groupsCollection.doc(groupId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Group.fromMap(snap.id, snap.data() as Map<String, dynamic>);
    });
  }

  /// Rejoindre un groupe via code d'invitation
  Future<Group?> joinGroupByCode(String inviteCode) async {
    final query = await _groupsCollection
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();
    
    if (query.docs.isEmpty) return null;
    
    final doc = query.docs.first;
    final group = Group.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    
    // Vérifier si déjà membre
    if (group.isMember(currentUserId)) {
      return group;
    }
    
    // Ajouter comme membre
    await _groupsCollection.doc(doc.id).update({
      'members': FieldValue.arrayUnion([currentUserId]),
    });
    
    // Message système
    await _sendSystemMessage(
      groupId: doc.id,
      content: '$currentUserName a rejoint le groupe',
    );
    
    return group.copyWith(
      members: [...group.members, currentUserId],
    );
  }

  /// Quitter un groupe
  Future<void> leaveGroup(String groupId) async {
    final group = await getGroup(groupId);
    if (group == null) return;
    
    // Si c'est le créateur et le seul admin, on ne peut pas quitter
    if (group.isCreator(currentUserId) && group.admins.length == 1) {
      throw Exception('Le créateur doit désigner un autre admin avant de quitter');
    }
    
    await _groupsCollection.doc(groupId).update({
      'members': FieldValue.arrayRemove([currentUserId]),
      'admins': FieldValue.arrayRemove([currentUserId]),
    });
    
    await _sendSystemMessage(
      groupId: groupId,
      content: '$currentUserName a quitté le groupe',
    );
  }

  /// Ajouter un membre
  Future<void> addMember(String groupId, String userId, String userName) async {
    await _groupsCollection.doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
    
    await _sendSystemMessage(
      groupId: groupId,
      content: '$currentUserName a ajouté $userName au groupe',
    );
  }

  /// Retirer un membre (admin seulement)
  Future<void> removeMember(String groupId, String userId, String userName) async {
    await _groupsCollection.doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
      'admins': FieldValue.arrayRemove([userId]),
    });
    
    await _sendSystemMessage(
      groupId: groupId,
      content: '$currentUserName a retiré $userName du groupe',
    );
  }

  /// Promouvoir un membre en admin
  Future<void> promoteToAdmin(String groupId, String userId, String userName) async {
    await _groupsCollection.doc(groupId).update({
      'admins': FieldValue.arrayUnion([userId]),
    });
    
    await _sendSystemMessage(
      groupId: groupId,
      content: '$userName est maintenant administrateur',
    );
  }

  /// Révoquer les droits d'admin
  Future<void> demoteAdmin(String groupId, String userId, String userName) async {
    await _groupsCollection.doc(groupId).update({
      'admins': FieldValue.arrayRemove([userId]),
    });
    
    await _sendSystemMessage(
      groupId: groupId,
      content: '$userName n\'est plus administrateur',
    );
  }

  /// Mettre à jour les infos du groupe
  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? description,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    
    if (updates.isNotEmpty) {
      await _groupsCollection.doc(groupId).update(updates);
    }
  }

  /// Régénérer le code d'invitation
  Future<String> regenerateInviteCode(String groupId) async {
    final newCode = Group.generateInviteCode();
    await _groupsCollection.doc(groupId).update({
      'inviteCode': newCode,
    });
    return newCode;
  }

  /// Supprimer le groupe (créateur seulement)
  Future<void> deleteGroup(String groupId) async {
    // Supprimer tous les messages
    final messages = await _messagesCollection(groupId).get();
    final batch = _db.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    
    // Supprimer le groupe
    await _groupsCollection.doc(groupId).delete();
  }

  // ============ MESSAGES ============

  /// Stream des messages du groupe
  Stream<List<GroupMessage>> messagesStream(String groupId, {int limit = 50}) {
    return _messagesCollection(groupId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => GroupMessage.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  /// Envoyer un message
  Future<void> sendMessage({
    required String groupId,
    required String content,
    GroupMessage? replyTo,
  }) async {
    final docRef = _messagesCollection(groupId).doc();
    
    final message = GroupMessage(
      id: docRef.id,
      groupId: groupId,
      from: currentUserId,
      fromName: currentUserName,
      content: content.trim(),
      timestamp: DateTime.now(),
      type: 'text',
      replyToId: replyTo?.id,
      replyToContent: replyTo?.content,
      replyToFrom: replyTo?.fromName,
    );
    
    await docRef.set(message.toMap());
    
    // Mettre à jour le dernier message du groupe
    await _groupsCollection.doc(groupId).update({
      'lastMessage': content.trim(),
      'lastMessageFrom': currentUserId,
      'lastMessageAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Envoyer une image
  Future<void> sendImage({
    required String groupId,
    required Uint8List data,
    required String fileName,
    String caption = '',
  }) async {
    final safeName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final storageRef = _storage.ref('groups/$groupId/$safeName');
    
    final lower = fileName.toLowerCase();
    String contentType = 'image/jpeg';
    if (lower.endsWith('.png')) contentType = 'image/png';
    else if (lower.endsWith('.webp')) contentType = 'image/webp';
    else if (lower.endsWith('.gif')) contentType = 'image/gif';
    
    await storageRef.putData(data, SettableMetadata(contentType: contentType));
    final url = await storageRef.getDownloadURL();
    
    final docRef = _messagesCollection(groupId).doc();
    final message = GroupMessage(
      id: docRef.id,
      groupId: groupId,
      from: currentUserId,
      fromName: currentUserName,
      content: caption.trim(),
      timestamp: DateTime.now(),
      type: 'image',
      mediaUrl: url,
    );
    
    await docRef.set(message.toMap());
    
    await _groupsCollection.doc(groupId).update({
      'lastMessage': '📷 Photo',
      'lastMessageFrom': currentUserId,
      'lastMessageAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Envoyer un message système
  Future<void> _sendSystemMessage({
    required String groupId,
    required String content,
  }) async {
    final docRef = _messagesCollection(groupId).doc();
    
    final message = GroupMessage(
      id: docRef.id,
      groupId: groupId,
      from: 'system',
      fromName: 'Système',
      content: content,
      timestamp: DateTime.now(),
      type: 'system',
    );
    
    await docRef.set(message.toMap());
    
    await _groupsCollection.doc(groupId).update({
      'lastMessage': content,
      'lastMessageFrom': 'system',
      'lastMessageAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Supprimer un message
  Future<void> deleteMessage(String groupId, String messageId) async {
    await _messagesCollection(groupId).doc(messageId).update({
      'isDeleted': true,
      'content': '',
      'mediaUrl': null,
    });
  }

  /// Ajouter/retirer une réaction
  Future<void> toggleReaction({
    required String groupId,
    required String messageId,
    required String emoji,
    required bool currentlyHasReaction,
  }) async {
    final docRef = _messagesCollection(groupId).doc(messageId);
    
    if (currentlyHasReaction) {
      await docRef.update({
        'reactions.$emoji': FieldValue.arrayRemove([currentUserId]),
      });
    } else {
      await docRef.update({
        'reactions.$emoji': FieldValue.arrayUnion([currentUserId]),
      });
    }
  }

  // ============ MEMBRES ============

  /// Stream des membres du groupe
  Stream<List<ChatUser>> membersStream(String groupId) {
    return groupStream(groupId).asyncMap((group) async {
      if (group == null) return [];
      
      final List<ChatUser> members = [];
      for (final memberId in group.members) {
        final doc = await _db.collection('users').doc(memberId).get();
        if (doc.exists) {
          members.add(ChatUser.fromMap(doc.data()!));
        }
      }
      return members;
    });
  }

  /// Obtenir les infos d'un utilisateur
  Future<ChatUser?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return ChatUser.fromMap(doc.data()!);
  }
}
