import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';

class GameIntroScreen extends StatefulWidget {
  const GameIntroScreen({super.key});

  @override
  State<GameIntroScreen> createState() => _GameIntroScreenState();
}

class _GameIntroScreenState extends State<GameIntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final List<FallingCoin> _fallingCoins = [];
  late AnimationController _fallingCoinsController;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fallingCoinsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _generateFallingCoins();
  }

  void _generateFallingCoins() {
    final random = Random();
    // Generar 8 monedas con diferentes posiciones y delays para efecto continuo
    for (int i = 0; i < 8; i++) {
      _fallingCoins.add(FallingCoin(
        x: random.nextDouble() * 0.9 + 0.05, // Entre 5% y 95% del ancho
        speed: 0.6 + random.nextDouble() * 0.4,
        delay: (i / 8.0) + random.nextDouble() * 0.2, // Distribuir delays
        size: 25 + random.nextDouble() * 20,
      ));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fallingCoinsController.dispose();
    super.dispose();
  }

  void _goToBusinessSelection() {
    context.push('/business-selection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Monedas cayendo en el fondo
            ..._fallingCoins.map((coin) => _buildFallingCoin(coin)),
            // Contenido principal
            _buildIntroView(),
          ],
        ),
      ),
    );
  }

  Widget _buildFallingCoin(FallingCoin coin) {
    return AnimatedBuilder(
      animation: _fallingCoinsController,
      builder: (context, child) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Calcular progreso con delay
        final baseProgress = _fallingCoinsController.value;
        final progress = (baseProgress + coin.delay) % 1.0;
        
        // Posición Y (cae desde arriba)
        final y = -50 + progress * (screenHeight + 100);
        
        // Posición X (con ligera variación horizontal)
        final x = coin.x * screenWidth;
        
        // Rotación continua
        final rotation = progress * 4 * pi;
        
        // Opacidad basada en posición (más visible en el centro)
        final opacity = progress < 0.1 || progress > 0.9 
            ? 0.3 
            : 0.7;
        
        return Positioned(
          left: x - coin.size / 2,
          top: y,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: rotation,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: coin.size,
                  height: coin.size,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: coin.size * 0.65,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntroView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animado
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            // Título del juego
            const Text(
              'RecaudoPro',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recolector de Monedas',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            // Instrucciones
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Toca las monedas para recolectarlas',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        color: AppColors.accent,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Tienes 5 segundos para recolectar',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // Botón Jugar
            CustomButton(
              text: '🎮 JUGAR',
              onPressed: _goToBusinessSelection,
              backgroundColor: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class FallingCoin {
  final double x;
  final double speed;
  final double delay;
  final double size;

  FallingCoin({
    required this.x,
    required this.speed,
    required this.delay,
    required this.size,
  });
}
