import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:vidi/services/auth_service.dart';
import 'package:vidi/pages/signin_page.dart';
import 'package:vidi/pages/main_page.dart';
import 'package:vidi/pages/payment_success_page.dart';
import 'package:vidi/pages/payment_cancelled_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if we're on a payment callback route (web only)
      if (kIsWeb) {
        final path = Uri.base.path;
        final fragment = Uri.base.fragment;

        debugPrint('🔎 Splash redirect check path=$path fragment=$fragment');

        Uri? fragmentUri;
        if (fragment.isNotEmpty) {
          fragmentUri = Uri.tryParse(fragment.startsWith('/') ? fragment : '/$fragment');
        }

        final isSuccessPath = path.startsWith('/payments/success');
        final isCancelPath = path == '/payments/cancelled';
        final isSuccessFragment = fragmentUri?.path.startsWith('/payments/success') ?? false;
        final isCancelFragment = fragmentUri?.path == '/payments/cancelled';

        final sessionId = isSuccessFragment
            ? fragmentUri?.queryParameters['session_id']
            : Uri.base.queryParameters['session_id'];

        if (isSuccessPath || isSuccessFragment) {
          _navigateTo(PaymentSuccessPage(sessionId: sessionId));
          return;
        }

        if (isCancelPath || isCancelFragment) {
          _navigateTo(const PaymentCancelledPage());
          return;
        }
      }
      
      // Normal auth flow
      final isLoggedIn = await _authService.isLoggedIn();
      _navigateTo(isLoggedIn ? const MainPage() : const SignInPage());
    } catch (e, stack) {
      debugPrint('Splash auth check failed: $e');
      debugPrintStack(stackTrace: stack);
      _navigateTo(const SignInPage());
    }
  }

  void _navigateTo(Widget page) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'vidi',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Where Creators Connect',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
