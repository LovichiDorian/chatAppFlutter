import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/message.dart';

class MessageItem extends StatelessWidget {
  final Message message;
  final String selfId;
  final VoidCallback? onDeleteForMe;
  final VoidCallback? onDeleteForEveryone;
  const MessageItem({
    super.key,
    required this.message,
    required this.selfId,
    this.onDeleteForMe,
    this.onDeleteForEveryone,
  });

  @override
  Widget build(BuildContext context) {
    final mine = message.from == selfId;
    final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = mine ? Colors.deepPurple : Colors.grey.shade300;
    final textColor = mine ? Colors.white : Colors.black87;
    final time = DateFormat('HH:mm').format(message.timestamp);

    Widget content;
    if (message.isDeleted) {
      content = Text(
        'Message supprimé',
        style: TextStyle(
          color: textColor.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
        ),
      );
    } else if (message.type == 'image' && message.mediaUrl != null) {
      content = GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _FullScreenImage(url: message.mediaUrl!),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                message.mediaUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) => progress == null
                    ? child
                    : SizedBox(
                        width: 180,
                        height: 180,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                      (progress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        ),
                      ),
              ),
              if (message.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    message.content,
                    style: TextStyle(color: textColor),
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      content = Text(message.content, style: TextStyle(color: textColor));
    }

    final bubble = Container(
      decoration: BoxDecoration(
        color: message.type == 'image' ? Colors.transparent : bubbleColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: message.type == 'image'
          ? EdgeInsets.zero
          : const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 300),
      child: content,
    );

    final bubbleWithOptionalAvatar = Row(
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!mine)
          const CircleAvatar(radius: 10, child: Icon(Icons.person, size: 12)),
        if (!mine) const SizedBox(width: 6),
        GestureDetector(
          onLongPressStart: (details) async {
            final overlay =
                Overlay.of(context).context.findRenderObject() as RenderBox;
            final selected = await showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(
                details.globalPosition.dx,
                details.globalPosition.dy,
                overlay.size.width - details.globalPosition.dx,
                overlay.size.height - details.globalPosition.dy,
              ),
              items: [
                const PopupMenuItem(
                  value: 'me',
                  child: Text('Supprimer pour moi'),
                ),
                if (mine)
                  const PopupMenuItem(
                    value: 'all',
                    child: Text('Supprimer pour tous'),
                  ),
              ],
            );
            if (selected == 'me') {
              onDeleteForMe?.call();
            } else if (selected == 'all') {
              onDeleteForEveryone?.call();
            }
          },
          child: bubble,
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          bubbleWithOptionalAvatar,
          const SizedBox(height: 2),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: (mine ? Colors.white70 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String url;
  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Image.network(url),
        ),
      ),
    );
  }
}
