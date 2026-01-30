import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../models/message.dart';

class MessageItem extends StatefulWidget {
  final Message message;
  final String selfId;
  final VoidCallback? onDeleteForMe;
  final VoidCallback? onDeleteForEveryone;
  final Function(Message)? onReply;
  final Function(String emoji)? onReaction;
  
  const MessageItem({
    super.key,
    required this.message,
    required this.selfId,
    this.onDeleteForMe,
    this.onDeleteForEveryone,
    this.onReply,
    this.onReaction,
  });

  @override
  State<MessageItem> createState() => _MessageItemState();
}

class _MessageItemState extends State<MessageItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleIn;
  late Animation<double> _fadeIn;
  bool _isPressed = false;
  bool _showReactionPicker = false;
  
  // Emojis rapides pour les réactions
  static const _quickReactions = ['❤️', '😂', '😮', '😢', '👍', '👎'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleIn = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    if (widget.message.content.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: widget.message.content));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Message copié'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = widget.message.from == widget.selfId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('HH:mm').format(widget.message.timestamp);

    return FadeTransition(
      opacity: _fadeIn,
      child: ScaleTransition(
        scale: _scaleIn,
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Afficher le message auquel on répond
              if (widget.message.replyToContent != null)
                _buildReplyPreview(mine, isDark),
              
              // Bubble de réactions rapides (si visible)
              if (_showReactionPicker)
                _buildReactionPicker(isDark),
              
              // Message principal
              GestureDetector(
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapUp: (_) => setState(() => _isPressed = false),
                onTapCancel: () => setState(() => _isPressed = false),
                onDoubleTap: () {
                  // Double-tap pour ajouter un ❤️
                  widget.onReaction?.call('❤️');
                },
                onLongPressStart: (details) => _showContextMenu(context, details, mine),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
                  child: _buildBubble(context, mine, isDark),
                ),
              ),
              
              // Réactions affichées sous le message
              if (widget.message.reactions.isNotEmpty)
                _buildReactionsDisplay(mine, isDark),
              
              // Heure et statut
              const SizedBox(height: AppSpacing.xxs),
              _buildTimeAndStatus(mine, time, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(bool mine, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(
        left: mine ? 60 : 0,
        right: mine ? 0 : 60,
        bottom: 4,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border(
            left: BorderSide(
              color: mine ? AppColors.primary : AppColors.secondary,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message.replyToFrom == widget.selfId ? 'Vous' : 'Réponse',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: mine ? AppColors.primary : AppColors.secondary,
              ),
            ),
            Text(
              widget.message.replyToContent ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionPicker(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D44) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: AppShadows.medium,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _quickReactions.map((emoji) {
            final hasReaction = widget.message.hasReaction(emoji, widget.selfId);
            return GestureDetector(
              onTap: () {
                widget.onReaction?.call(emoji);
                setState(() => _showReactionPicker = false);
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: hasReaction
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReactionsDisplay(bool mine, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        left: mine ? 0 : 12,
        right: mine ? 12 : 0,
      ),
      child: Wrap(
        spacing: 4,
        children: widget.message.reactions.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          if (users.isEmpty) return const SizedBox.shrink();
          
          final hasMyReaction = users.contains(widget.selfId);
          
          return GestureDetector(
            onTap: () => widget.onReaction?.call(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasMyReaction
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: hasMyReaction
                    ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  if (users.length > 1) ...[
                    const SizedBox(width: 2),
                    Text(
                      '${users.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeAndStatus(bool mine, String time, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(
        left: mine ? 0 : AppSpacing.xs,
        right: mine ? AppSpacing.xs : 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : AppColors.textLight,
            ),
          ),
          if (mine) ...[
            const SizedBox(width: 4),
            Icon(
              widget.message.isRead
                  ? Icons.done_all_rounded
                  : Icons.done_rounded,
              size: 14,
              color: widget.message.isRead
                  ? AppColors.primary
                  : (isDark ? Colors.white38 : AppColors.textLight),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, bool mine, bool isDark) {
    final bubbleDecoration = mine
        ? BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.lg),
              topRight: const Radius.circular(AppRadius.lg),
              bottomLeft: const Radius.circular(AppRadius.lg),
              bottomRight: const Radius.circular(AppRadius.xs),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          )
        : BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.lg),
              topRight: const Radius.circular(AppRadius.lg),
              bottomLeft: const Radius.circular(AppRadius.xs),
              bottomRight: const Radius.circular(AppRadius.lg),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                : null,
          );

    final textColor = mine
        ? Colors.white
        : (isDark ? Colors.white : AppColors.textPrimary);

    Widget content;
    
    if (widget.message.isDeleted) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block_rounded,
            size: 16,
            color: textColor.withValues(alpha: 0.6),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Message supprimé',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
        ],
      );
    } else if (widget.message.type == 'image' && widget.message.mediaUrl != null) {
      content = _buildImageContent(context, mine, isDark);
    } else {
      content = Text(
        widget.message.content,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          height: 1.4,
        ),
      );
    }

    if (widget.message.type == 'image' && !widget.message.isDeleted) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 280),
        child: content,
      );
    }

    return Container(
      decoration: bubbleDecoration,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      constraints: const BoxConstraints(maxWidth: 280),
      child: content,
    );
  }

  Widget _buildImageContent(BuildContext context, bool mine, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _FullScreenImage(url: widget.message.mediaUrl!),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.small,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.network(
                  widget.message.mediaUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    (progress.expectedTotalBytes ?? 1)
                                : null,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (ctx, error, stack) => Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          size: 40,
                          color: isDark ? Colors.white38 : AppColors.textLight,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Image non disponible',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : AppColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.message.content.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: mine
                      ? AppColors.primary
                      : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  widget.message.content,
                  style: TextStyle(
                    color: mine
                        ? Colors.white
                        : (isDark ? Colors.white : AppColors.textPrimary),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, LongPressStartDetails details, bool mine) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    // Afficher d'abord le sélecteur de réactions
    setState(() => _showReactionPicker = true);
    
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        overlay.size.width - details.globalPosition.dx,
        overlay.size.height - details.globalPosition.dy,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      color: isDark ? const Color(0xFF2D2D44) : Colors.white,
      items: [
        // Répondre
        PopupMenuItem(
          value: 'reply',
          child: Row(
            children: [
              Icon(
                Icons.reply_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Répondre',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // Copier
        if (widget.message.content.isNotEmpty && !widget.message.isDeleted)
          PopupMenuItem(
            value: 'copy',
            child: Row(
              children: [
                Icon(
                  Icons.copy_rounded,
                  size: 20,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Copier',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        // Supprimer pour moi
        PopupMenuItem(
          value: 'me',
          child: Row(
            children: [
              Icon(
                Icons.visibility_off_outlined,
                size: 20,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Supprimer pour moi',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // Supprimer pour tous
        if (mine)
          PopupMenuItem(
            value: 'all',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Supprimer pour tous',
                  style: TextStyle(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    
    setState(() => _showReactionPicker = false);
    
    switch (selected) {
      case 'reply':
        widget.onReply?.call(widget.message);
        break;
      case 'copy':
        _copyToClipboard();
        break;
      case 'me':
        widget.onDeleteForMe?.call();
        break;
      case 'all':
        widget.onDeleteForEveryone?.call();
        break;
    }
  }
}

class _FullScreenImage extends StatelessWidget {
  final String url;
  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.close_rounded, color: Colors.white),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.download_rounded, color: Colors.white),
            ),
            onPressed: () {
              // TODO: Implémenter le téléchargement
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Téléchargement bientôt disponible')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Image.network(
            url,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          (progress.expectedTotalBytes ?? 1)
                      : null,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
