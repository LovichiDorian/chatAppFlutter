import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/chat_user.dart';
import '../viewmodel/auth_view_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser!;
    _name = TextEditingController(text: user.displayName);
    _bio = TextEditingController(text: user.bio);
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    final uid = auth.currentUser!.id;
    await FirebaseFirestore.instance
        .collection(FirestorePaths.users)
        .doc(uid)
        .update({'displayName': _name.text.trim(), 'bio': _bio.text.trim()});
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final self = context.watch<AuthViewModel>().currentUser!;
    final other = args is ChatUser ? args : null;
    final user = other ?? self;
    final isSelf = other == null || other.id == self.id;
    return Scaffold(
      appBar: AppBar(title: Text(isSelf ? 'Mon profil' : 'Profil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isSelf
            ? Form(
                key: _formKey,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      child: Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Nom requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bio,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        child: const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bio',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(user.bio.isEmpty ? '—' : user.bio),
                  ),
                ],
              ),
      ),
    );
  }
}
