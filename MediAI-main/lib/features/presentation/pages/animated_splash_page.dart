import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/locale_service.dart';
import 'auth_page.dart';
import 'main_shell_page.dart';

class AnimatedSplashPage extends StatefulWidget {
  const AnimatedSplashPage({super.key});

  @override
  State<AnimatedSplashPage> createState() => _AnimatedSplashPageState();
}

class _AnimatedSplashPageState extends State<AnimatedSplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    _scheduleNextScreen();
  }

  void _scheduleNextScreen() {
    Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;

      final targetWidget = AuthService.isAuthenticated
          ? const MainShellPage()
          : const AuthPage();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => targetWidget,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.currentLocale,
      builder: (context, locale, _) {
        final isUrdu = locale.languageCode == 'ur';

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00332C),
                    Color(0xFF004D40),
                    Color(0xFF00695C),
                  ],
                ),
              ),
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [

                      Positioned(
                        top: 80,
                        right: -30,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF80CBC4).withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 60,
                        left: -40,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF80CBC4).withValues(alpha: 0.05),
                          ),
                        ),
                      ),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: _scaleAnimation.value * _pulseAnimation.value,
                            child: Opacity(
                              opacity: _fadeAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00796B).withValues(alpha: 0.4),
                                      blurRadius: 32,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: const Color(0xFF80CBC4).withValues(alpha: 0.45),
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Image.asset(
                                    'assets/icons/app_icon.png',
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                      Icons.local_hospital_rounded,
                                      size: 80,
                                      color: Color(0xFF80CBC4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Opacity(
                            opacity: _fadeAnimation.value,
                            child: Column(
                              children: [
                                Text(
                                  isUrdu ? 'میڈی اے آئی' : 'MediAI',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isUrdu
                                        ? 'کلینیکل ڈرمیٹولوجی اور اسمارٹ ٹرائیج'
                                        : 'Clinical Dermatology & Smart Triage',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      Positioned(
                        bottom: 36,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Column(
                            children: [
                              const SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF80CBC4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.lock_outline,
                                    size: 13,
                                    color: Colors.white60,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isUrdu
                                        ? 'مقامی محفوظ کلینیکل سسٹمز'
                                        : '100% Local On-Device Architecture',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white60,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}
}
