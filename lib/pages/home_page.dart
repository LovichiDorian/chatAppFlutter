import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_user.dart';
import '../viewmodel/auth_view_model.dart';
import '../viewmodel/chat_view_model.dart';
import '../widgets/chat_list_item.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (auth.currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final chatVm = ChatViewModel(currentUserId: auth.currentUser!.id);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
            icon: CircleAvatar(
              radius: 12,
              child: Text(
                auth.currentUser!.displayName.isEmpty
                    ? '?'
                    : auth.currentUser!.displayName[0].toUpperCase(),
              ),
            ),
            tooltip: 'Mon profil',
          ),
          IconButton(
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: StreamBuilder<List<ChatUser>>(
        stream: chatVm.usersStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snap.data!;
          if (users.isEmpty) {
            return const Center(child: Text('Aucun autre utilisateur'));
          }
          return ListView.separated(
            itemBuilder: (_, i) => ChatListItem(
              user: users[i],
              onTap: () =>
                  Navigator.of(context).pushNamed('/chat', arguments: users[i]),
            ),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: users.length,
          );
        },
      ),
    );
  }
}
