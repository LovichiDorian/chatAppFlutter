import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../models/chat_user.dart';
import '../models/message.dart';

class ChatViewModel extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final String currentUserId;
  
  // Timer pour le debounce du typing indicator
  Timer? _typingTimer;

  ChatViewModel({
    FirebaseFirestore? db,
    FirebaseStorage? storage,
    required this.currentUserId,
  }) : _db = db ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  Stream<List<ChatUser>> usersStream() {
    return _db
        .collection(FirestorePaths.users)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ChatUser.fromMap(d.data()))
              .where((u) => u.id != currentUserId)
              .toList(),
        );
  }
  
  /// Stream pour un utilisateur spécifique (pour le statut en temps réel)
  Stream<ChatUser?> userStream(String userId) {
    return _db
        .collection(FirestorePaths.users)
        .doc(userId)
        .snapshots()
        .map((snap) => snap.exists ? ChatUser.fromMap(snap.data()!) : null);
  }

  String chatIdFor(String otherUserId) {
    final ids = [currentUserId, otherUserId]..sort();
    return ids.join('_');
  }

  Future<void> sendMessage({
    required String to,
    required String content,
    Message? replyTo,
  }) async {
    final chatId = chatIdFor(to);
    final ref = _db.collection(FirestorePaths.messages(chatId)).doc();
    final msg = Message(
      id: ref.id,
      from: currentUserId,
      to: to,
      content: content.trim(),
      timestamp: DateTime.now(),
      type: 'text',
      replyToId: replyTo?.id,
      replyToContent: replyTo?.content,
      replyToFrom: replyTo?.from,
    );
    await ref.set(msg.toMap());
    
    // Mettre à jour le document du chat
    final chatDoc = _db.collection(FirestorePaths.chats).doc(chatId);
    await chatDoc.set({
      'members': [currentUserId, to]..sort(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'lastMessage': content.trim(),
      'lastMessageFrom': currentUserId,
      'lastMessageAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
    
    // Arrêter l'indicateur de frappe
    await setTyping(to, false);
  }

  Stream<List<Message>> messagesStream(String otherUserId, {int limit = 50}) {
    final chatId = chatIdFor(otherUserId);
    return _db
        .collection(FirestorePaths.messages(chatId))
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
          final items = snap.docs
              .map((d) => Message.fromMap(d.id, d.data()))
              .toList();
          return items
              .where((m) => !m.deletedFor.contains(currentUserId))
              .toList();
        });
  }

  Future<void> sendImage({
    required String to,
    required Uint8List data,
    required String fileName,
    String caption = '',
    Message? replyTo,
  }) async {
    final chatId = chatIdFor(to);
    final safeName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final storageRef = _storage.ref('chats/$chatId/$safeName');
    
    final lower = fileName.toLowerCase();
    String contentType = 'image/jpeg';
    if (lower.endsWith('.png')) {
      contentType = 'image/png';
    } else if (lower.endsWith('.webp')) {
      contentType = 'image/webp';
    } else if (lower.endsWith('.gif')) {
      contentType = 'image/gif';
    }
    
    try {
      await storageRef.putData(
        data,
        SettableMetadata(contentType: contentType),
      );
      final url = await storageRef.getDownloadURL();
      final ref = _db.collection(FirestorePaths.messages(chatId)).doc();
      final msg = Message(
        id: ref.id,
        from: currentUserId,
        to: to,
        content: caption.trim(),
        timestamp: DateTime.now(),
        type: 'image',
        mediaUrl: url,
        replyToId: replyTo?.id,
        replyToContent: replyTo?.content,
        replyToFrom: replyTo?.from,
      );
      await ref.set(msg.toMap());
      
      final chatDoc = _db.collection(FirestorePaths.chats).doc(chatId);
      await chatDoc.set({
        'members': [currentUserId, to]..sort(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'lastMessage': '📷 Photo',
        'lastMessageFrom': currentUserId,
        'lastMessageAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('sendImage error: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteForMe({
    required String otherUserId,
    required String messageId,
  }) async {
    final chatId = chatIdFor(otherUserId);
    final doc = _db.collection(FirestorePaths.messages(chatId)).doc(messageId);
    await doc.set({
      'deletedFor': FieldValue.arrayUnion([currentUserId]),
    }, SetOptions(merge: true));
  }

  Future<void> deleteForEveryone({
    required String otherUserId,
    required String messageId,
  }) async {
    final chatId = chatIdFor(otherUserId);
    final docRef = _db
        .collection(FirestorePaths.messages(chatId))
        .doc(messageId);
    final existing = await docRef.get();
    final data = existing.data();
    final mediaUrl = data?['mediaUrl'] as String?;
    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(mediaUrl).delete();
      } catch (_) {}
    }
    await docRef.set({
      'isDeleted': true,
      'content': '',
      'mediaUrl': null,
      'type': 'text',
      'reactions': {},
    }, SetOptions(merge: true));
  }

  // ============ NOUVELLES FONCTIONNALITÉS ============

  /// Mettre à jour le statut en ligne
  Future<void> updateOnlineStatus(bool isOnline) async {
    await _db.collection(FirestorePaths.users).doc(currentUserId).set({
      'isOnline': isOnline,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  /// Définir l'indicateur de frappe avec debounce
  Future<void> setTyping(String toUserId, bool isTyping) async {
    _typingTimer?.cancel();
    
    await _db.collection(FirestorePaths.users).doc(currentUserId).set({
      'isTyping': isTyping,
      'typingTo': isTyping ? toUserId : null,
    }, SetOptions(merge: true));
    
    // Auto-désactiver après 5 secondes si toujours en train de taper
    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 5), () {
        setTyping(toUserId, false);
      });
    }
  }

  /// Ajouter une réaction à un message
  Future<void> addReaction({
    required String otherUserId,
    required String messageId,
    required String emoji,
  }) async {
    final chatId = chatIdFor(otherUserId);
    final docRef = _db.collection(FirestorePaths.messages(chatId)).doc(messageId);
    
    await docRef.set({
      'reactions.$emoji': FieldValue.arrayUnion([currentUserId]),
    }, SetOptions(merge: true));
  }

  /// Retirer une réaction d'un message
  Future<void> removeReaction({
    required String otherUserId,
    required String messageId,
    required String emoji,
  }) async {
    final chatId = chatIdFor(otherUserId);
    final docRef = _db.collection(FirestorePaths.messages(chatId)).doc(messageId);
    
    await docRef.set({
      'reactions.$emoji': FieldValue.arrayRemove([currentUserId]),
    }, SetOptions(merge: true));
  }

  /// Basculer une réaction (ajouter si absente, retirer si présente)
  Future<void> toggleReaction({
    required String otherUserId,
    required String messageId,
    required String emoji,
    required bool currentlyHasReaction,
  }) async {
    if (currentlyHasReaction) {
      await removeReaction(
        otherUserId: otherUserId,
        messageId: messageId,
        emoji: emoji,
      );
    } else {
      await addReaction(
        otherUserId: otherUserId,
        messageId: messageId,
        emoji: emoji,
      );
    }
  }

  /// Marquer les messages comme lus
  Future<void> markMessagesAsRead(String otherUserId) async {
    final chatId = chatIdFor(otherUserId);
    final batch = _db.batch();
    
    final unreadMessages = await _db
        .collection(FirestorePaths.messages(chatId))
        .where('from', isEqualTo: otherUserId)
        .where('isRead', isEqualTo: false)
        .get();
    
    for (final doc in unreadMessages.docs) {
      batch.set(doc.reference, {
        'isRead': true,
        'readAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    }
    
    await batch.commit();
  }

  /// Compter les messages non lus
  Stream<int> unreadCountStream(String otherUserId) {
    final chatId = chatIdFor(otherUserId);
    return _db
        .collection(FirestorePaths.messages(chatId))
        .where('from', isEqualTo: otherUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Pagination helper
  Future<List<Message>> fetchMore(
    String otherUserId, {
    required DateTime startAfter,
    int limit = 50,
  }) async {
    final chatId = chatIdFor(otherUserId);
    final snap = await _db
        .collection(FirestorePaths.messages(chatId))
        .orderBy('timestamp', descending: true)
        .startAfter([startAfter.millisecondsSinceEpoch])
        .limit(limit)
        .get();
    return snap.docs.map((d) => Message.fromMap(d.id, d.data())).toList();
  }
}
