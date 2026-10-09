import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberCredentials = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedNumber();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionEndedNotice());
  }

  /// Si se llegó aquí porque la sesión venció o se revocó, se avisa una vez.
  void _showSessionEndedNotice() {
    if (!mounted || !ref.read(sessionEndedNoticeProvider)) return;
    ref.read(sessionEndedNoticeProvider.notifier).state = false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tu sesión terminó. Vuelve a iniciar sesión para continuar.')),
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Número recordado del último login (la contraseña nunca se guarda).
  Future<void> _loadRememberedNumber() async {
    final number = await ref.read(authRepositoryProvider).getRememberedNumber();
    if (!mounted || number == null) return;
    setState(() {
      _numberController.text = number;
      _rememberCredentials = true;
    });
  }

  Future<void> _saveRememberedNumber() => ref
      .read(authRepositoryProvider)
      .setRememberedNumber(_rememberCredentials ? _numberController.text.trim() : null);

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Verificar que hay un negocio seleccionado
    final selectedBusiness = ref.read(selectedBusinessProvider);
    if (selectedBusiness == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un negocio primero'),
          backgroundColor: AppColors.error,
        ),
      );
      context.go('/business-selection');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final useCase = ref.read(signInWithNumberUseCaseProvider);
      final user = await useCase(
        selectedBusiness.id,
        _numberController.text.trim(),
        _passwordController.text,
      );

      if (user != null && mounted) {
        // Validar is_active: si la API devuelve is_active: false, no permitir login
        if (!user.isActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.userInactiveMessage),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 5),
            ),
          );
          return;
        }
        await _saveRememberedNumber();
        if (!mounted) return;
        ref.read(currentUserProvider.notifier).setUser(user);
        context.go('/dashboard');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Credenciales inválidas o usuario no pertenece a este negocio'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedBusiness = ref.watch(selectedBusinessProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/business-selection');
      },
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        body: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Logo/Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.onPrimary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 24),
                // Business Name (si está seleccionado)
                if (selectedBusiness != null) ...[
                  Text(
                    selectedBusiness.name,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Welcome Text
                Text(
                  AppStrings.welcomeBack,
                  style: GoogleFonts.barlowCondensed(
                    color: AppColors.textPrimary(context),
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedBusiness != null
                      ? 'Inicia sesión en ${selectedBusiness.name}'
                      : AppStrings.loginSubtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 16,
                  ),
                ),
                // Siempre mostrar opción para ir a selección de negocio (visible con o sin negocio seleccionado)
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => context.go('/business-selection'),
                  icon: Icon(Icons.business, color: AppColors.textPrimary(context)),
                  label: Text(
                    selectedBusiness == null
                        ? 'Seleccionar negocio'
                        : 'Cambiar negocio',
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Número de usuario (acepta números y letras)
                CustomTextField(
                  label: AppStrings.userNumber,
                  hint: AppStrings.enterUserNumber,
                  prefixIcon: Icons.badge_outlined,
                  controller: _numberController,
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tu número de usuario';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Password Field
                CustomTextField(
                  label: AppStrings.password,
                  hint: AppStrings.enterPassword,
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  controller: _passwordController,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary(context),
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contraseña';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Remember Credentials Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _rememberCredentials,
                      onChanged: (value) {
                        setState(() {
                          _rememberCredentials = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                      checkColor: AppColors.onPrimary,
                    ),
                    Expanded(
                      child: Text(
                        'Recordar mi número',
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Forgot Password
                // Align(
                //   alignment: Alignment.centerRight,
                //   child: TextButton(
                //     onPressed: () {
                //       // TODO: Implementar recuperación de contraseña
                //     },
                //     child: const Text(
                //       AppStrings.forgotPassword,
                //       style: TextStyle(color: AppColors.primary),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 24),
                // Login Button
                CustomButton(
                  text: AppStrings.login,
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 32),

                // Register Link
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      AppStrings.noAccount,
                      style: TextStyle(color: AppColors.textSecondary(context)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
