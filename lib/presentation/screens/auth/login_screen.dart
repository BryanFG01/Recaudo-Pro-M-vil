import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
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
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Cargar credenciales guardadas
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNumber = prefs.getString('saved_number');
      final savedPassword = prefs.getString('saved_password');
      final rememberMe = prefs.getBool('remember_credentials') ?? false;

      if (rememberMe && savedNumber != null && savedPassword != null) {
        setState(() {
          _numberController.text = savedNumber;
          _passwordController.text = savedPassword;
          _rememberCredentials = true;
        });
      }
    } catch (e) {
      // Si hay error al cargar, continuar sin credenciales guardadas
    }
  }

  // Guardar credenciales
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberCredentials) {
        await prefs.setString('saved_number', _numberController.text.trim());
        await prefs.setString('saved_password', _passwordController.text);
        await prefs.setBool('remember_credentials', true);
      } else {
        await prefs.remove('saved_number');
        await prefs.remove('saved_password');
        await prefs.setBool('remember_credentials', false);
      }
    } catch (e) {
      // Si hay error al guardar, continuar sin guardar
    }
  }

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
        // Guardar credenciales si el usuario marcó la opción
        await _saveCredentials();
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

    return Scaffold(
      backgroundColor: AppColors.background,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 24),
                // Business Name (si está seleccionado)
                if (selectedBusiness != null) ...[
                  Text(
                    selectedBusiness.name,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Welcome Text
                const Text(
                  AppStrings.welcomeBack,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedBusiness != null
                      ? 'Inicia sesión en ${selectedBusiness.name}'
                      : AppStrings.loginSubtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                // Siempre mostrar opción para ir a selección de negocio (visible con o sin negocio seleccionado)
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => context.go('/business-selection'),
                  icon: const Icon(Icons.business, color: AppColors.primary),
                  label: Text(
                    selectedBusiness == null
                        ? 'Seleccionar negocio'
                        : 'Cambiar negocio',
                    style: const TextStyle(color: AppColors.primary),
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
                      color: AppColors.textSecondary,
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
                  children: [
                    Checkbox(
                      value: _rememberCredentials,
                      onChanged: (value) {
                        setState(() {
                          _rememberCredentials = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                      checkColor: Colors.white,
                    ),
                    const Text(
                      'Recordar número y contraseña',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
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
                    child: const Text(
                      AppStrings.noAccount,
                      style: TextStyle(color: AppColors.primary),
                      textAlign: TextAlign.center,
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
}
