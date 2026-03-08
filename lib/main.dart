import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:vidi/theme.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/pages/splash_page.dart';
import 'package:vidi/pages/payment_success_page.dart';
import 'package:vidi/pages/payment_cancelled_page.dart';
import 'package:vidi/supabase/supabase_config.dart';
import 'package:vidi/config/stripe_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  
  // Initialize Stripe (only on mobile - not supported on web)
  if (!kIsWeb) {
    Stripe.publishableKey = StripeConfig.publishableKey;
    Stripe.merchantIdentifier = StripeConfig.merchantDisplayName;
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'vidi',
        theme: AppTheme.darkTheme,
        home: const SplashPage(),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: (settings) {
          // Handle payment success/cancel routes from Stripe redirect
          if (settings.name?.startsWith('/payments/success') ?? false) {
            final uri = Uri.parse(settings.name!);
            final sessionId = uri.queryParameters['session_id'];
            return MaterialPageRoute(
              builder: (_) => PaymentSuccessPage(sessionId: sessionId),
            );
          }
          if (settings.name == '/payments/cancelled') {
            return MaterialPageRoute(
              builder: (_) => const PaymentCancelledPage(),
            );
          }
          return null;
        },
        onUnknownRoute: (_) => MaterialPageRoute(
          builder: (_) => const SplashPage(),
        ),
      ),
    );
  }
}
