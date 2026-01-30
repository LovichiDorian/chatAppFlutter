import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/chat_user.dart';
import '../models/group.dart';
import '../viewmodel/auth_view_model.dart';
import '../viewmodel/chat_view_model.dart';
import '../viewmodel/group_view_model.dart';
import 'create_group_page.dart';
import 'join_group_page.dart';
import 'group_chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  String _query = '';
  int _currentTab = 0; // 0 = Contacts, 1 = Groupes
  
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      setState(() => _query = _search.text.trim());
    });
    
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    _search.dispose();
    super.dispose();
  }

  void _showGroupOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF2D2D44) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.add_rounded, color: AppColors.primary),
              ),
              title: Text(
                'Créer un groupe',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Créez un nouveau groupe de discussion',
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGroupPage()),
                );
                if (result is Group && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GroupChatPage(),
                      settings: RouteSettings(arguments: result),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.login_rounded, color: AppColors.secondary),
              ),
              title: Text(
                'Rejoindre un groupe',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Utilisez un code d\'invitation',
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JoinGroupPage()),
                );
                if (result is Group && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GroupChatPage(),
                      settings: RouteSettings(arguments: result),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (auth.currentUser == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark ? AppColors.gradientDark : AppColors.gradientBackground,
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    final chatVm = ChatViewModel(currentUserId: auth.currentUser!.id);
    final groupVm = GroupViewModel(
      currentUserId: auth.currentUser!.id,
      currentUserName: auth.currentUser!.displayName,
    );
    final firstName = auth.currentUser!.displayName.split(' ').first;

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
                _buildHeader(context, auth, firstName, isDark),
                _buildSearchBar(context, isDark),
                _buildTabs(isDark),
                Expanded(
                  child: _currentTab == 0
                      ? _buildUsersList(context, chatVm, isDark)
                      : _buildGroupsList(context, groupVm, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _currentTab == 1
          ? FloatingActionButton(
              onPressed: _showGroupOptions,
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, AuthViewModel auth, String firstName, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour,',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  firstName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/profile'),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    auth.currentUser!.displayName.isEmpty
                        ? '?'
                        : auth.currentUser!.displayName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: AppSpacing.sm),
          
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') context.read<AuthViewModel>().signOut();
            },
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.small,
              ),
              child: Icon(
                Icons.more_vert_rounded,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: isDark ? null : AppShadows.small,
        ),
        child: TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: _currentTab == 0 ? 'Rechercher un contact...' : 'Rechercher un groupe...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : AppColors.textLight,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDark ? Colors.white54 : AppColors.textLight,
            ),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white54 : AppColors.textLight,
                    ),
                    onPressed: () {
                      _search.clear();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                label: 'Contacts',
                icon: Icons.person_outline_rounded,
                isActive: _currentTab == 0,
                isDark: isDark,
                onTap: () => setState(() => _currentTab = 0),
              ),
            ),
            Expanded(
              child: _TabButton(
                label: 'Groupes',
                icon: Icons.group_outlined,
                isActive: _currentTab == 1,
                isDark: isDark,
                onTap: () => setState(() => _currentTab = 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(BuildContext context, ChatViewModel chatVm, bool isDark) {
    return StreamBuilder<List<ChatUser>>(
      stream: chatVm.usersStream(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final all = snap.data!;
        final q = _query.toLowerCase();
        final users = q.isEmpty
            ? all
            : all.where((u) =>
                u.displayName.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q)).toList();

        if (users.isEmpty) {
          return _buildEmptyState(
            context,
            isDark,
            icon: Icons.person_search_rounded,
            title: 'Aucun contact trouvé',
            subtitle: 'Essayez un autre nom ou email',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          itemCount: users.length,
          itemBuilder: (_, i) {
            final u = users[i];
            return _UserCard(
              user: u,
              index: i,
              isDark: isDark,
              onTap: () => Navigator.of(context).pushNamed('/chat', arguments: u),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupsList(BuildContext context, GroupViewModel groupVm, bool isDark) {
    return StreamBuilder<List<Group>>(
      stream: groupVm.myGroupsStream(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final all = snap.data!;
        final q = _query.toLowerCase();
        final groups = q.isEmpty
            ? all
            : all.where((g) =>
                g.name.toLowerCase().contains(q) ||
                g.description.toLowerCase().contains(q)).toList();

        if (groups.isEmpty) {
          return _buildEmptyGroupsState(context, isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            100, // Espace pour le FAB
          ),
          itemCount: groups.length,
          itemBuilder: (_, i) {
            final g = groups[i];
            return _GroupCard(
              group: g,
              index: i,
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GroupChatPage(),
                  settings: RouteSettings(arguments: g),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Icon(
              icon,
              size: 40,
              color: isDark ? Colors.white38 : AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? Colors.white70 : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? Colors.white38 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGroupsState(BuildContext context, bool isDark) {
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
            child: Icon(
              Icons.group_outlined,
              size: 40,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Aucun groupe',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? Colors.white70 : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Créez ou rejoignez un groupe pour commencer',
            style: TextStyle(
              color: isDark ? Colors.white38 : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JoinGroupPage()),
                  );
                  if (result is Group && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GroupChatPage(),
                        settings: RouteSettings(arguments: result),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.login_rounded),
                label: const Text('Rejoindre'),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateGroupPage()),
                  );
                  if (result is Group && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GroupChatPage(),
                        settings: RouteSettings(arguments: result),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Créer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: isActive && !isDark ? AppShadows.small : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? AppColors.primary
                  : (isDark ? Colors.white54 : AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? AppColors.primary
                    : (isDark ? Colors.white54 : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatefulWidget {
  final ChatUser user;
  final int index;
  final bool isDark;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.index,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 50).clamp(0, 200)),
      vsync: this,
    );
    
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _slideIn = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    final avatarColor = _getAvatarColor(widget.user.displayName);
    
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: widget.isDark ? null : AppShadows.small,
                border: widget.isDark
                    ? Border.all(color: Colors.white.withValues(alpha: 0.08))
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            avatarColor,
                            avatarColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Center(
                        child: Text(
                          widget.user.displayName.isEmpty
                              ? '?'
                              : widget.user.displayName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: AppSpacing.md),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.user.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.isDark ? Colors.white54 : AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: avatarColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: avatarColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatefulWidget {
  final Group group;
  final int index;
  final bool isDark;
  final VoidCallback onTap;

  const _GroupCard({
    required this.group,
    required this.index,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 50).clamp(0, 200)),
      vsync: this,
    );
    
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _slideIn = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: widget.isDark ? null : AppShadows.small,
                border: widget.isDark
                    ? Border.all(color: Colors.white.withValues(alpha: 0.08))
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    // Avatar du groupe
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientAccent,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Center(
                        child: Text(
                          widget.group.name.isEmpty
                              ? '?'
                              : widget.group.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: AppSpacing.md),
                    
                    // Infos groupe
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.group.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.group_rounded,
                                size: 14,
                                color: widget.isDark ? Colors.white38 : AppColors.textLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.group.memberCount} membres',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isDark ? Colors.white38 : AppColors.textLight,
                                ),
                              ),
                              if (widget.group.lastMessage != null) ...[
                                Text(
                                  ' • ',
                                  style: TextStyle(
                                    color: widget.isDark ? Colors.white38 : AppColors.textLight,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    widget.group.lastMessage!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.isDark ? Colors.white54 : AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Icône
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.accent,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
