import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/group.dart';
import '../models/chat_user.dart';
import '../viewmodel/auth_view_model.dart';
import '../viewmodel/group_view_model.dart';

class GroupDetailsPage extends StatefulWidget {
  final Group group;
  
  const GroupDetailsPage({super.key, required this.group});

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  
  bool _isLeaving = false;
  bool _isRegeneratingCode = false;

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
    super.dispose();
  }

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Code copié !'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareInvite(Group group) {
    final text = group.shareableInviteText;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Lien d\'invitation copié !'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _regenerateCode(GroupViewModel groupVm, String groupId) async {
    setState(() => _isRegeneratingCode = true);
    try {
      await groupVm.regenerateInviteCode(groupId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nouveau code généré !'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isRegeneratingCode = false);
    }
  }

  Future<void> _leaveGroup(GroupViewModel groupVm, String groupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter le groupe ?'),
        content: const Text('Vous ne pourrez plus voir les messages de ce groupe.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isLeaving = true);
    try {
      await groupVm.leaveGroup(groupId);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
      setState(() => _isLeaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (auth.currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final groupVm = GroupViewModel(
      currentUserId: auth.currentUser!.id,
      currentUserName: auth.currentUser!.displayName,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.gradientDark : AppColors.gradientBackground,
        ),
        child: StreamBuilder<Group?>(
          stream: groupVm.groupStream(widget.group.id),
          builder: (context, snapshot) {
            final group = snapshot.data ?? widget.group;
            final isAdmin = group.isAdmin(auth.currentUser!.id);
            final isCreator = group.isCreator(auth.currentUser!.id);
            
            return SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: CustomScrollView(
                  slivers: [
                    // AppBar
                    SliverToBoxAdapter(
                      child: _buildAppBar(context, isDark),
                    ),
                    
                    // Header du groupe
                    SliverToBoxAdapter(
                      child: _buildGroupHeader(context, group, isDark),
                    ),
                    
                    // Section invitation
                    SliverToBoxAdapter(
                      child: _buildInviteSection(context, group, groupVm, isAdmin, isDark),
                    ),
                    
                    // Liste des membres
                    SliverToBoxAdapter(
                      child: _buildMembersHeader(context, group, isDark),
                    ),
                    
                    // Membres
                    StreamBuilder<List<ChatUser>>(
                      stream: groupVm.membersStream(group.id),
                      builder: (context, memberSnap) {
                        final members = memberSnap.data ?? [];
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final member = members[index];
                              return _MemberTile(
                                member: member,
                                group: group,
                                currentUserId: auth.currentUser!.id,
                                isDark: isDark,
                                groupVm: groupVm,
                              );
                            },
                            childCount: members.length,
                          ),
                        );
                      },
                    ),
                    
                    // Actions
                    SliverToBoxAdapter(
                      child: _buildActions(context, group, groupVm, isCreator, isDark),
                    ),
                    
                    // Espace en bas
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 40),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Détails du groupe',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(BuildContext context, Group group, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Avatar du groupe
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.gradientAccent,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                group.name.isEmpty ? '?' : group.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Nom du groupe
          Text(
            group.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.xs),
          
          // Nombre de membres
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group_rounded, size: 16, color: AppColors.accent),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${group.memberCount} membres',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          
          if (group.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              group.description,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInviteSection(
    BuildContext context,
    Group group,
    GroupViewModel groupVm,
    bool isAdmin,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.5),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(Icons.link_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inviter des membres',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Partagez le code ou le lien',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Code d'invitation
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Code d\'invitation',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              group.inviteCode,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 2,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copyInviteCode(group.inviteCode),
                        icon: Icon(
                          Icons.copy_rounded,
                          color: AppColors.primary,
                        ),
                        tooltip: 'Copier',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareInvite(group),
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Partager'),
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        onPressed: _isRegeneratingCode
                            ? null
                            : () => _regenerateCode(groupVm, group.id),
                        icon: _isRegeneratingCode
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                Icons.refresh_rounded,
                                color: isDark ? Colors.white54 : AppColors.textSecondary,
                              ),
                        tooltip: 'Nouveau code',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMembersHeader(BuildContext context, Group group, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.people_outline_rounded,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Membres (${group.memberCount})',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    Group group,
    GroupViewModel groupVm,
    bool isCreator,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Quitter le groupe
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLeaving ? null : () => _leaveGroup(groupVm, group.id),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Center(
                  child: _isLeaving
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout_rounded, color: AppColors.error),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Quitter le groupe',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final ChatUser member;
  final Group group;
  final String currentUserId;
  final bool isDark;
  final GroupViewModel groupVm;

  const _MemberTile({
    required this.member,
    required this.group,
    required this.currentUserId,
    required this.isDark,
    required this.groupVm,
  });

  Color _getAvatarColor(String name) {
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

  @override
  Widget build(BuildContext context) {
    final isAdmin = group.isAdmin(member.id);
    final isCreator = group.isCreator(member.id);
    final isCurrentUser = member.id == currentUserId;
    final canManage = group.isAdmin(currentUserId) && !isCurrentUser && !isCreator;
    final avatarColor = _getAvatarColor(member.displayName);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: isDark ? null : AppShadows.small,
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [avatarColor, avatarColor.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Center(
            child: Text(
              member.displayName.isEmpty ? '?' : member.displayName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                member.displayName + (isCurrentUser ? ' (vous)' : ''),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          member.email,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCreator)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                    const SizedBox(width: 2),
                    Text(
                      'Créateur',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              )
            else if (isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            if (canManage) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
                onSelected: (action) async {
                  switch (action) {
                    case 'promote':
                      await groupVm.promoteToAdmin(
                        group.id,
                        member.id,
                        member.displayName,
                      );
                      break;
                    case 'demote':
                      await groupVm.demoteAdmin(
                        group.id,
                        member.id,
                        member.displayName,
                      );
                      break;
                    case 'remove':
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Retirer ce membre ?'),
                          content: Text('${member.displayName} sera retiré du groupe.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Annuler'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                              ),
                              child: const Text('Retirer'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await groupVm.removeMember(
                          group.id,
                          member.id,
                          member.displayName,
                        );
                      }
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  if (!isAdmin)
                    const PopupMenuItem(
                      value: 'promote',
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Promouvoir admin'),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'demote',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 20),
                          SizedBox(width: 8),
                          Text('Révoquer admin'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove_outlined, size: 20, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text('Retirer', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
