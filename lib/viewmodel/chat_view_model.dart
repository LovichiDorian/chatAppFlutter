import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
// Uint8List available via foundation

import '../constants.dart';
import '../models/chat_user.dart';
import '../models/message.dart';

class ChatViewModel extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final String currentUserId;

  ChatViewModel({
    FirebaseFirestore? db,
    FirebaseStorage? storage,
    required this.currentUserId,
  }) : _db = db ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

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

  String chatIdFor(String otherUserId) {
    final ids = [currentUserId, otherUserId]..sort();
    return ids.join('_');
  }

  Future<void> sendMessage({
    required String to,
    required String content,
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
    );
    await ref.set(msg.toMap());
    final chatDoc = _db.collection(FirestorePaths.chats).doc(chatId);
    await chatDoc.set({
      'members': [currentUserId, to]..sort(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
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
  }) async {
    final chatId = chatIdFor(to);
    // Ensure unique filename to avoid collisions
    final safeName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final storageRef = _storage.ref('chats/$chatId/$safeName');
    // Best-effort contentType detection
    final lower = fileName.toLowerCase();
    String contentType = 'image/jpeg';
    if (lower.endsWith('.png'))
      contentType = 'image/png';
    else if (lower.endsWith('.webp'))
      contentType = 'image/webp';
    else if (lower.endsWith('.gif'))
      contentType = 'image/gif';
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
      );
      await ref.set(msg.toMap());
      // create chat doc if not exists (metadata)
      final chatDoc = _db.collection(FirestorePaths.chats).doc(chatId);
      await chatDoc.set({
        'members': [currentUserId, to]..sort(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
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
      } catch (_) {
        // ignore delete errors
      }
    }
    await docRef.set({
      'isDeleted': true,
      'content': '',
      'mediaUrl': null,
      'type': 'text',
    }, SetOptions(merge: true));
  }

  // Pagination helper to fetch next page older than lastTimestamp
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
