import 'package:flutter/material.dart';

import '../models/chat_user.dart';

class ChatListItem extends StatelessWidget {
  final ChatUser user;
  final VoidCallback? onTap;
  const ChatListItem({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        child: Text(
          user.displayName.isEmpty ? '?' : user.displayName[0].toUpperCase(),
        ),
      ),
      title: Text(user.displayName),
      subtitle: Text(user.email),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
