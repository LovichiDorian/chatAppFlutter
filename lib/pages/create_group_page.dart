import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/chat_user.dart';
import '../viewmodel/auth_view_model.dart';
import '../viewmodel/group_view_model.dart';
import '../viewmodel/chat_view_model.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  
  final Set<String> _selectedMembers = {};
  bool _isCreating = false;
  String _searchQuery = '';
  
  late AnimationController _animController;
  late Animation<double> _fadeIn;

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
    
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isCreating = true);
    
    try {
      final auth = context.read<AuthViewModel>();
      final groupVm = GroupViewModel(
        currentUserId: auth.currentUser!.id,
        currentUserName: auth.currentUser!.displayName,
      );
      
      final group = await groupVm.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        initialMembers: _selectedMembers.toList(),
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Groupe "${group.name}" créé !'),
          backgroundColor: AppColors.success,
        ),
      );
      
      // Retourner à la page d'accueil avec le groupe créé
      Navigator.of(context).pop(group);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (auth.currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final chatVm = ChatViewModel(currentUserId: auth.currentUser!.id);

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
                _buildAppBar(context, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Icône du groupe
                          _buildGroupIcon(isDark),
                          
                          const SizedBox(height: AppSpacing.xl),
                          
                          // Formulaire
                          _buildFormCard(isDark),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Sélection des membres
                          _buildMembersSection(chatVm, isDark),
                          
                          const SizedBox(height: AppSpacing.xl),
                          
                          // Bouton créer
                          _buildCreateButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            'Créer un groupe',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupIcon(bool isDark) {
    return Center(
      child: Container(
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
        child: const Icon(
          Icons.group_add_rounded,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFormCard(bool isDark) {
    return ClipRRect(
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
              Text(
                'Nom du groupe *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Équipe projet, Amis...',
                  prefixIcon: Icon(Icons.group_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().length < 2 ? 'Nom trop court' : null,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Text(
                'Description (optionnel)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Décrivez votre groupe...',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersSection(ChatViewModel chatVm, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.people_outline_rounded,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Ajouter des membres',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (_selectedMembers.isNotEmpty) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${_selectedMembers.length} sélectionné(s)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        // Barre de recherche
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: isDark ? null : AppShadows.small,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        // Liste des utilisateurs
        StreamBuilder<List<ChatUser>>(
          stream: chatVm.usersStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            final users = snapshot.data!
                .where((u) =>
                    _searchQuery.isEmpty ||
                    u.displayName.toLowerCase().contains(_searchQuery) ||
                    u.email.toLowerCase().contains(_searchQuery))
                .toList();
            
            if (users.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Aucun utilisateur trouvé',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }
            
            return Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: isDark ? null : AppShadows.small,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isSelected = _selectedMembers.contains(user.id);
                  
                  return _UserTile(
                    user: user,
                    isSelected: isSelected,
                    isDark: isDark,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedMembers.remove(user.id);
                        } else {
                          _selectedMembers.add(user.id);
                        }
                      });
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: _isCreating ? null : AppColors.gradientPrimary,
        color: _isCreating ? Colors.grey.shade300 : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: _isCreating ? null : AppShadows.glow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isCreating ? null : _createGroup,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Center(
            child: _isCreating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'Créer le groupe',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final ChatUser user;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
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
    final avatarColor = _getAvatarColor(user.displayName);
    
    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          Container(
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
                user.displayName.isEmpty
                    ? '?'
                    : user.displayName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        user.displayName,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        user.email,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white54 : AppColors.textSecondary,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppColors.success)
          : Icon(
              Icons.circle_outlined,
              color: isDark ? Colors.white38 : AppColors.textLight,
            ),
    );
  }
}
