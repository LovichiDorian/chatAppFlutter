import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../models/chat_user.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthViewModel({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance {
    _sub = _auth.authStateChanges().listen(_onAuthChange);
  }

  StreamSubscription<User?>? _sub;
  ChatUser? _currentUser;
  bool _busy = false;
  String? _error;

  ChatUser? get currentUser => _currentUser;
  bool get isBusy => _busy;
  String? get error => _error;

  Future<void> _onAuthChange(User? user) async {
    if (user == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }
    final doc = await _db.collection(FirestorePaths.users).doc(user.uid).get();
    if (doc.exists) {
      _currentUser = ChatUser.fromMap(doc.data()!);
    } else {
      final profile = ChatUser(
        id: user.uid,
        displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
        email: user.email ?? '',
      );
      await _db
          .collection(FirestorePaths.users)
          .doc(user.uid)
          .set(profile.toMap());
      _currentUser = profile;
    }
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setBusy(true);
    try {
      _error = null;
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(displayName);
      final profile = ChatUser(
        id: cred.user!.uid,
        displayName: displayName,
        email: email,
      );
      await _db
          .collection(FirestorePaths.users)
          .doc(profile.id)
          .set(profile.toMap());
    } on FirebaseAuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _setBusy(true);
    try {
      _error = null;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> signInWithGoogle() async {
    _setBusy(true);
    try {
      _error = null;
      final provider = GoogleAuthProvider();
      // Add required scopes if needed: provider.addScope('email');
      await _auth.signInWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
