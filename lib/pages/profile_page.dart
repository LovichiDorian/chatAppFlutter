import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/chat_user.dart';
import '../viewmodel/auth_view_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _bio;
  bool _isSaving = false;
  
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser!;
    _name = TextEditingController(text: user.displayName);
    _bio = TextEditingController(text: user.bio);
    
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final auth = context.read<AuthViewModel>();
      final uid = auth.currentUser!.id;
      await FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .doc(uid)
          .update({
        'displayName': _name.text.trim(),
        'bio': _bio.text.trim(),
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil mis à jour'),
          backgroundColor: AppColors.success,
        ),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
    final args = ModalRoute.of(context)?.settings.arguments;
    final self = context.watch<AuthViewModel>().currentUser!;
    final other = args is ChatUser ? args : null;
    final user = other ?? self;
    final isSelf = other == null || other.id == self.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarColor = _getAvatarColor(user.displayName);

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
                // AppBar
                _buildAppBar(context, isSelf, isDark),
                
                // Contenu
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: isSelf
                        ? _buildEditProfile(context, user, avatarColor, isDark)
                        : _buildViewProfile(context, user, avatarColor, isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isSelf, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
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
                boxShadow: isDark ? null : AppShadows.small,
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            isSelf ? 'Mon profil' : 'Profil',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfile(BuildContext context, ChatUser user, Color avatarColor, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Avatar avec effet de héro
          _buildAvatarSection(user, avatarColor, isDark, true),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Formulaire dans une carte glassmorphism
          ClipRRect(
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
                  boxShadow: AppShadows.medium,
                ),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Champ nom
                    _buildTextField(
                      controller: _name,
                      label: 'Nom',
                      hint: 'Votre nom complet',
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Nom requis' : null,
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Champ bio
                    _buildTextField(
                      controller: _bio,
                      label: 'Bio',
                      hint: 'Parlez-nous de vous...',
                      icon: Icons.edit_note_rounded,
                      isDark: isDark,
                      maxLines: 4,
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Bouton sauvegarder
                    _buildSaveButton(isDark),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Info email (non modifiable)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: isDark ? Colors.white38 : AppColors.textLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewProfile(BuildContext context, ChatUser user, Color avatarColor, bool isDark) {
    return Column(
      children: [
        // Avatar avec effet de héro
        _buildAvatarSection(user, avatarColor, isDark, false),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Carte d'informations
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
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
                boxShadow: AppShadows.medium,
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Email
                  _buildInfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  Divider(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Section Bio
                  _buildInfoRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Bio',
                    value: user.bio.isEmpty ? 'Aucune bio' : user.bio,
                    isDark: isDark,
                    isMultiline: true,
                    isEmpty: user.bio.isEmpty,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Bouton envoyer un message
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.glow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                // Déjà sur la page de chat avec cet utilisateur
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'Envoyer un message',
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
        ),
      ],
    );
  }

  Widget _buildAvatarSection(ChatUser user, Color avatarColor, bool isDark, bool isEditable) {
    return Column(
      children: [
        // Grand avatar avec gradient
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    avatarColor,
                    avatarColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                boxShadow: [
                  BoxShadow(
                    color: avatarColor.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (isEditable)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppShadows.small,
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 20,
                    color: avatarColor,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Nom
        Text(
          user.displayName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        
        if (!isEditable) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'En ligne',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: maxLines == 1 ? Icon(icon) : null,
            alignLabelWithHint: maxLines > 1,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool isMultiline = false,
    bool isEmpty = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isEmpty ? FontWeight.normal : FontWeight.w500,
                  fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  color: isEmpty
                      ? (isDark ? Colors.white38 : AppColors.textLight)
                      : (isDark ? Colors.white : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: _isSaving ? null : AppColors.gradientPrimary,
        color: _isSaving ? Colors.grey.shade300 : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: _isSaving ? null : AppShadows.glow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSaving ? null : _save,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Center(
            child: _isSaving
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
                      Icon(Icons.check_rounded, color: Colors.white),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'Enregistrer',
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
