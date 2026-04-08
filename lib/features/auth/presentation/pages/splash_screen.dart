import 'package:flutter/material.dart';
import 'package:monitoring_jamur/core/theme/app_theme.dart';
import 'package:monitoring_jamur/core/session/user_session.dart';
import 'package:monitoring_jamur/features/auth/presentation/pages/login_page.dart';
import 'package:monitoring_jamur/features/home/presentation/pages/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _logoController.forward();

    // Navigate to next screen after animation
    Future.delayed(const Duration(milliseconds: 3500), () {
      _checkSessionAndNavigate();
    });
  }

  void _checkSessionAndNavigate() {
    if (!mounted) return;
    
    Widget nextScreen = UserSession.isLoggedIn ? const MainScreen() : const LoginPage();
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _logoScale,
              child: FadeTransition(
                opacity: _logoOpacity,
                child: Image.asset(
                  'lib/assets/mushroom.png',
                  height: 150,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildAnimatedTextLine("mushrooms", 1000),
            const SizedBox(height: 8),
            _buildAnimatedTextLine("monitoring apps", 1800, isSecondary: true),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTextLine(String text, int startDelayMs, {bool isSecondary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: text.split('').asMap().entries.map((entry) {
        return AnimatedCharacter(
          char: entry.value,
          delay: Duration(milliseconds: startDelayMs + (entry.key * 70)),
          isSecondary: isSecondary,
        );
      }).toList(),
    );
  }
}

class AnimatedCharacter extends StatefulWidget {
  final String char;
  final Duration delay;
  final bool isSecondary;

  const AnimatedCharacter({
    super.key,
    required this.char,
    required this.delay,
    this.isSecondary = false,
  });

  @override
  State<AnimatedCharacter> createState() => _AnimatedCharacterState();
}

class _AnimatedCharacterState extends State<AnimatedCharacter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(3.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Text(
          widget.char == ' ' ? '\u00A0' : widget.char,
          style: TextStyle(
            fontSize: widget.isSecondary ? 18 : 32,
            fontWeight: widget.isSecondary ? FontWeight.w500 : FontWeight.bold,
            color: widget.isSecondary ? AppTheme.textLight : AppTheme.primaryGreen,
            letterSpacing: widget.isSecondary ? 1.5 : 2.0,
          ),
        ),
      ),
    );
  }
}
