import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../models/group.dart';
import '../viewmodel/auth_view_model.dart';
import '../viewmodel/group_view_model.dart';
import 'group_details_page.dart';

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({super.key});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  
  int _limit = 50;
  bool _showEmoji = false;
  bool _sendingImage = false;
  GroupMessage? _replyingTo;
  
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  
  GroupViewModel? _groupVm;

  void _scrollToBottomAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = ModalRoute.of(context)!.settings.arguments as Group;
    final auth = context.watch<AuthViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (auth.currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    _groupVm ??= GroupViewModel(
      currentUserId: auth.currentUser!.id,
      currentUserName: auth.currentUser!.displayName,
    );
    final groupVm = _groupVm!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.gradientDark : AppColors.gradientBackground,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                _buildAppBar(context, group, groupVm, isDark),
                Expanded(
                  child: _buildMessages(context, group, groupVm, auth, isDark),
                ),
                if (_replyingTo != null) _buildReplyBar(isDark),
                _buildInputArea(context, group, groupVm, isDark),
                if (_showEmoji) _buildEmojiPicker(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Group group, GroupViewModel groupVm, bool isDark) {
    return StreamBuilder<Group?>(
      stream: groupVm.groupStream(group.id),
      builder: (context, snapshot) {
        final liveGroup = snapshot.data ?? group;
        
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GroupDetailsPage(group: liveGroup),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientAccent,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Center(
                          child: Text(
                            liveGroup.name.isEmpty
                                ? '?'
                                : liveGroup.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              liveGroup.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${liveGroup.memberCount} membres',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GroupDetailsPage(group: liveGroup),
                  ),
                ),
                icon: Icon(
                  Icons.info_outline_rounded,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessages(
    BuildContext context,
    Group group,
    GroupViewModel groupVm,
    AuthViewModel auth,
    bool isDark,
  ) {
    return StreamBuilder<List<GroupMessage>>(
      stream: groupVm.messagesStream(group.id, limit: _limit),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final messages = snap.data!;
        
        if (messages.isEmpty) {
          return _buildEmptyChat(context, group, isDark);
        }
        
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels <= 200) {
              setState(() => _limit += 30);
            }
            return false;
          },
          child: GroupedListView<GroupMessage, DateTime>(
            controller: _scrollController,
            elements: messages,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            groupBy: (m) => DateTime(
              m.timestamp.year,
              m.timestamp.month,
              m.timestamp.day,
            ),
            order: GroupedListOrder.ASC,
            itemComparator: (a, b) => a.timestamp.compareTo(b.timestamp),
            groupComparator: (a, b) => a.compareTo(b),
            useStickyGroupSeparators: false,
            floatingHeader: false,
            groupSeparatorBuilder: (date) => _buildDateSeparator(date, isDark),
            itemBuilder: (_, m) => _GroupMessageItem(
              message: m,
              selfId: auth.currentUser!.id,
              isDark: isDark,
              onReply: () {
                setState(() => _replyingTo = m);
                _focusNode.requestFocus();
              },
              onReaction: (emoji) {
                groupVm.toggleReaction(
                  groupId: group.id,
                  messageId: m.id,
                  emoji: emoji,
                  currentlyHasReaction: m.hasReaction(emoji, auth.currentUser!.id),
                );
              },
              onDelete: m.from == auth.currentUser!.id
                  ? () => groupVm.deleteMessage(group.id, m.id)
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    String label;
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) {
      label = "Aujourd'hui";
    } else if (d == yesterday) {
      label = 'Hier';
    } else {
      label = DateFormat('EEEE d MMM', 'fr_FR').format(date);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChat(BuildContext context, Group group, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(
              Icons.celebration_rounded,
              size: 40,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Groupe créé !',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Envoyez le premier message dans ${group.name}',
            style: TextStyle(
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.accent.withValues(alpha: 0.05),
        border: Border(
          left: BorderSide(color: AppColors.accent, width: 4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, size: 20, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Réponse à ${_replyingTo?.fromName}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                Text(
                  _replyingTo?.content ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _replyingTo = null),
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, Group group, GroupViewModel groupVm, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _InputIconButton(
            icon: _sendingImage ? null : Icons.add_rounded,
            isLoading: _sendingImage,
            isDark: isDark,
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
                      await groupVm.sendImage(
                        groupId: group.id,
                        data: data,
                        fileName: img.name,
                      );
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('Image envoyée'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      _scrollToBottomAfterBuild();
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _sendingImage = false);
                    }
                  },
          ),
          
          const SizedBox(width: AppSpacing.xs),
          
          _InputIconButton(
            icon: _showEmoji ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
            isDark: isDark,
            isActive: _showEmoji,
            onPressed: () {
              setState(() => _showEmoji = !_showEmoji);
              if (_showEmoji) {
                _focusNode.unfocus();
              } else {
                _focusNode.requestFocus();
              }
            },
          ),
          
          const SizedBox(width: AppSpacing.sm),
          
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) async {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  await groupVm.sendMessage(
                    groupId: group.id,
                    content: text,
                    replyTo: _replyingTo,
                  );
                  _controller.clear();
                  setState(() => _replyingTo = null);
                  _scrollToBottomAfterBuild();
                  _focusNode.requestFocus();
                },
                onTap: () {
                  if (_showEmoji) setState(() => _showEmoji = false);
                },
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Message au groupe...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : AppColors.textLight,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: AppSpacing.sm),
          
          _SendButton(
            onPressed: () async {
              final text = _controller.text.trim();
              if (text.isEmpty) return;
              await groupVm.sendMessage(
                groupId: group.id,
                content: text,
                replyTo: _replyingTo,
              );
              _controller.clear();
              setState(() => _replyingTo = null);
              _scrollToBottomAfterBuild();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker(bool isDark) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
          ),
        ),
      ),
      child: EmojiPicker(
        onEmojiSelected: (cat, emoji) {
          _controller
            ..text = _controller.text + emoji.emoji
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
        },
        config: Config(
          height: 280,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            columns: 8,
            emojiSizeMax: 28,
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            indicatorColor: AppColors.accent,
            iconColorSelected: AppColors.accent,
            iconColor: isDark ? Colors.white38 : AppColors.textLight,
          ),
          bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
        ),
      ),
    );
  }
}

// Widget pour afficher un message de groupe
class _GroupMessageItem extends StatelessWidget {
  final GroupMessage message;
  final String selfId;
  final bool isDark;
  final VoidCallback onReply;
  final Function(String emoji) onReaction;
  final VoidCallback? onDelete;

  const _GroupMessageItem({
    required this.message,
    required this.selfId,
    required this.isDark,
    required this.onReply,
    required this.onReaction,
    this.onDelete,
  });

  static const _quickReactions = ['❤️', '😂', '😮', '😢', '👍'];

  @override
  Widget build(BuildContext context) {
    final mine = message.from == selfId;
    final isSystem = message.type == 'system';
    final time = DateFormat('HH:mm').format(message.timestamp);

    if (isSystem) {
      return _buildSystemMessage(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Réponse citée
          if (message.replyToContent != null)
            _buildReplyPreview(mine),
          
          // Nom de l'expéditeur (si pas le mien)
          if (!mine)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Text(
                message.fromName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getSenderColor(message.fromName),
                ),
              ),
            ),
          
          // Bulle de message
          GestureDetector(
            onLongPress: () => _showContextMenu(context, mine),
            onDoubleTap: () => onReaction('❤️'),
            child: _buildBubble(context, mine),
          ),
          
          // Réactions
          if (message.reactions.isNotEmpty)
            _buildReactionsDisplay(mine),
          
          // Heure
          Padding(
            padding: EdgeInsets.only(
              left: mine ? 0 : 8,
              right: mine ? 8 : 0,
              top: 2,
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSenderColor(String name) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
    ];
    final index = name.isEmpty ? 0 : name.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(bool mine) {
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
            left: BorderSide(color: AppColors.accent, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.replyToFrom ?? '',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
            Text(
              message.replyToContent ?? '',
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

  Widget _buildBubble(BuildContext context, bool mine) {
    if (message.isDeleted) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_rounded, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              'Message supprimé',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white38 : AppColors.textLight,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final bubbleDecoration = mine
        ? BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.lg),
              topRight: const Radius.circular(AppRadius.lg),
              bottomLeft: const Radius.circular(AppRadius.lg),
              bottomRight: const Radius.circular(AppRadius.xs),
            ),
          )
        : BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.lg),
              topRight: const Radius.circular(AppRadius.lg),
              bottomLeft: const Radius.circular(AppRadius.xs),
              bottomRight: const Radius.circular(AppRadius.lg),
            ),
            boxShadow: isDark ? null : AppShadows.small,
          );

    final textColor = mine ? Colors.white : (isDark ? Colors.white : AppColors.textPrimary);

    if (message.type == 'image' && message.mediaUrl != null) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 250),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Image.network(
            message.mediaUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return Container(
                width: 200,
                height: 150,
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),
      );
    }

    return Container(
      decoration: bubbleDecoration,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      constraints: const BoxConstraints(maxWidth: 280),
      child: Text(
        message.content,
        style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
      ),
    );
  }

  Widget _buildReactionsDisplay(bool mine) {
    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        left: mine ? 0 : 8,
        right: mine ? 8 : 0,
      ),
      child: Wrap(
        spacing: 4,
        children: message.reactions.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          if (users.isEmpty) return const SizedBox.shrink();
          
          final hasMyReaction = users.contains(selfId);
          
          return GestureDetector(
            onTap: () => onReaction(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasMyReaction
                    ? AppColors.accent.withValues(alpha: 0.2)
                    : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(AppRadius.full),
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

  void _showContextMenu(BuildContext context, bool mine) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF2D2D44) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre de réactions rapides
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _quickReactions.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onReaction(emoji);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Répondre'),
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            if (message.content.isNotEmpty && !message.isDeleted)
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copier'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message copié')),
                  );
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: Text('Supprimer', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }
}

// Widgets réutilisables
class _InputIconButton extends StatelessWidget {
  final IconData? icon;
  final bool isDark;
  final bool isLoading;
  final bool isActive;
  final VoidCallback? onPressed;

  const _InputIconButton({
    this.icon,
    required this.isDark,
    this.isLoading = false,
    this.isActive = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent.withValues(alpha: 0.1)
              : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.surface),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
                )
              : Icon(
                  icon,
                  size: 22,
                  color: isActive
                      ? AppColors.accent
                      : (isDark ? Colors.white54 : AppColors.textSecondary),
                ),
        ),
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _SendButton({required this.onPressed});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        transform: Matrix4.identity()..scale(_isPressed ? 0.9 : 1.0),
        decoration: BoxDecoration(
          gradient: AppColors.gradientAccent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
