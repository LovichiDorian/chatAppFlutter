import 'package:flutter/material.dart';

import '../models/message.dart';

class MessageItem extends StatelessWidget {
  final Message message;
  final String selfId;
  const MessageItem({super.key, required this.message, required this.selfId});

  @override
  Widget build(BuildContext context) {
    final mine = message.from == selfId;
    final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = mine ? Colors.deepPurple : Colors.grey.shade300;
    final textColor = mine ? Colors.white : Colors.black87;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Text(message.content, style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }
}
