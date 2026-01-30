import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../viewmodel/auth_view_model.dart';
import '../viewmodel/group_view_model.dart';

class JoinGroupPage extends StatefulWidget {
  final String? initialCode;
  
  const JoinGroupPage({super.key, this.initialCode});

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  bool _isJoining = false;
  String? _error;
  
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _codeController.text = widget.initialCode!;
    }
    
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
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Entrez un code d\'invitation');
      return;
    }
    
    setState(() {
      _isJoining = true;
      _error = null;
    });
    
    try {
      final auth = context.read<AuthViewModel>();
      final groupVm = GroupViewModel(
        currentUserId: auth.currentUser!.id,
        currentUserName: auth.currentUser!.displayName,
      );
      
      final group = await groupVm.joinGroupByCode(code);
      
      if (!mounted) return;
      
      if (group == null) {
        setState(() => _error = 'Code invalide ou groupe introuvable');
        setState(() => _isJoining = false);
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous avez rejoint "${group.name}" !'),
          backgroundColor: AppColors.success,
        ),
      );
      
      // Retourner le groupe pour navigation
      Navigator.of(context).pop(group);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur: $e';
        _isJoining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildIcon(),
                            const SizedBox(height: AppSpacing.xl),
                            _buildCard(isDark),
                          ],
                        ),
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
            'Rejoindre un groupe',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: AppColors.gradientSecondary,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.4),
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
    );
  }

  Widget _buildCard(bool isDark) {
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Entrez le code d\'invitation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xs),
              
              Text(
                'Demandez le code à un membre du groupe',
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Champ de code
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  fontFamily: 'monospace',
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'XXXXXXXX',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white24 : AppColors.textLight,
                    letterSpacing: 4,
                  ),
                  errorText: _error,
                  prefixIcon: const Icon(Icons.vpn_key_rounded),
                ),
                onChanged: (_) {
                  if (_error != null) {
                    setState(() => _error = null);
                  }
                },
                onSubmitted: (_) => _joinGroup(),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Bouton rejoindre
              Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: _isJoining ? null : AppColors.gradientSecondary,
                  color: _isJoining ? Colors.grey.shade300 : null,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: _isJoining
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isJoining ? null : _joinGroup,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Center(
                      child: _isJoining
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
                                Icon(Icons.login_rounded, color: Colors.white),
                                SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Rejoindre',
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
          ),
        ),
      ),
    );
  }
}
