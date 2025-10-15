import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../models/chat_user.dart';
import '../models/message.dart';

class ChatViewModel extends ChangeNotifier {
  final FirebaseFirestore _db;
  final String currentUserId;

  ChatViewModel({FirebaseFirestore? db, required this.currentUserId})
      : _db = db ?? FirebaseFirestore.instance;

  Stream<List<ChatUser>> usersStream() {
    return _db
        .collection(FirestorePaths.users)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatUser.fromMap(d.data()))
            .where((u) => u.id != currentUserId)
            .toList());
  }

  String chatIdFor(String otherUserId) {
    final ids = [currentUserId, otherUserId]..sort();
    return ids.join('_');
  }

  Stream<List<Message>> messagesStream(String otherUserId) {
    final chatId = chatIdFor(otherUserId);
    return _db
        .collection(FirestorePaths.messages(chatId))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Message.fromMap(d.id, d.data()))
            .toList());
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
    );
    await ref.set(msg.toMap());
    // create chat doc if not exists (metadata)
    final chatDoc = _db.collection(FirestorePaths.chats).doc(chatId);
    await chatDoc.set({
      'members': [currentUserId, to]..sort(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }
}
