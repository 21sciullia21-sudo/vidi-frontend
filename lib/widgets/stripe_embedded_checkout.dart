import 'package:flutter/material.dart';
import 'package:vidi/config/stripe_config.dart';
import 'stripe_checkout_stub.dart' 
    if (dart.library.html) 'stripe_checkout_web.dart';

class StripeEmbeddedCheckout extends StatelessWidget {
  final String clientSecret;
  final VoidCallback? onComplete;

  const StripeEmbeddedCheckout({
    super.key,
    required this.clientSecret,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return StripeEmbeddedCheckoutImpl(
      clientSecret: clientSecret,
      publishableKey: StripeConfig.publishableKey,
      onComplete: onComplete,
    );
  }
}
