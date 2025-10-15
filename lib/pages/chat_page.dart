import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';

import '../models/chat_user.dart';
import '../models/message.dart';
import '../viewmodel/auth_view_model.dart';
import '../viewmodel/chat_view_model.dart';
import '../widgets/message_item.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  int _limit = 50;
  bool _showEmoji = false; // Emoji picker toggle
  bool _sendingImage = false; // UI lock during image upload

  void _scrollToBottomAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final other = ModalRoute.of(context)!.settings.arguments as ChatUser;
    final auth = context.watch<AuthViewModel>();
    if (auth.currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final chatVm = ChatViewModel(currentUserId: auth.currentUser!.id);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () =>
              Navigator.of(context).pushNamed('/profile', arguments: other),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                child: Text(
                  other.displayName.isEmpty
                      ? '?'
                      : other.displayName[0].toUpperCase(),
                ),
              ),
              const SizedBox(width: 8),
              Text(other.displayName),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: chatVm.messagesStream(other.id, limit: _limit),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snap.data!;
                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    // Charger plus d'anciens messages quand on arrive près du haut
                    if (n.metrics.pixels <= 200) {
                      setState(() => _limit += 30);
                    }
                    return false;
                  },
                  child: GroupedListView<Message, DateTime>(
                    controller: _scrollController,
                    elements: messages,
                    // Grouper par jour (YYYY-MM-DD)
                    groupBy: (m) => DateTime(
                      m.timestamp.year,
                      m.timestamp.month,
                      m.timestamp.day,
                    ),
                    // Tri global ASC pour que le plus récent soit tout en bas
                    order: GroupedListOrder.ASC,
                    itemComparator: (a, b) =>
                        a.timestamp.compareTo(b.timestamp),
                    groupComparator: (a, b) => a.compareTo(b),
                    useStickyGroupSeparators: false,
                    floatingHeader: false,
                    // Séparateur de groupe (entête date)
                    groupSeparatorBuilder: (DateTime date) {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final yesterday = today.subtract(const Duration(days: 1));
                      String label;
                      final d = DateTime(date.year, date.month, date.day);
                      if (d == today) {
                        label = 'Aujourd\'hui';
                      } else if (d == yesterday) {
                        label = 'Hier';
                      } else {
                        label = DateFormat('EEEE d MMM', 'fr_FR').format(date);
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: Chip(
                            label: Text(
                              label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 0,
                            ),
                          ),
                        ),
                      );
                    },
                    // Rendu d'un message
                    itemBuilder: (_, m) => MessageItem(
                      message: m,
                      selfId: auth.currentUser!.id,
                      onDeleteForMe: () => chatVm.deleteForMe(
                        otherUserId: other.id,
                        messageId: m.id,
                      ),
                      onDeleteForEveryone: () => chatVm.deleteForEveryone(
                        otherUserId: other.id,
                        messageId: m.id,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Row(
              children: [
                IconButton(
                  icon: _sendingImage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file),
                  tooltip: _sendingImage
                      ? 'Envoi en cours…'
                      : 'Joindre une image',
                  onPressed: _sendingImage
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final picker = ImagePicker();
                            final img = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            if (img == null) return;
                            setState(() => _sendingImage = true);
                            final data = await img.readAsBytes();
                            await chatVm.sendImage(
                              to: other.id,
                              data: data,
                              fileName: img.name,
                              caption: '',
                            );
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Image envoyée')),
                            );
                            _scrollToBottomAfterBuild();
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(content: Text('Erreur envoi image: $e')),
                            );
                          } finally {
                            if (mounted) setState(() => _sendingImage = false);
                          }
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: () => setState(() => _showEmoji = !_showEmoji),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Votre message...',
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    await chatVm.sendMessage(to: other.id, content: text);
                    _controller.clear();
                    _scrollToBottomAfterBuild();
                  },
                ),
              ],
            ),
          ),
          if (_showEmoji)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (cat, emoji) {
                  _controller
                    ..text = _controller.text + emoji.emoji
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: _controller.text.length),
                    );
                },
              ),
            ),
        ],
      ),
    );
  }
}
