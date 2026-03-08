import 'package:flutter/material.dart';

class StripeEmbeddedCheckoutImpl extends StatelessWidget {
  final String clientSecret;
  final String publishableKey;
  final VoidCallback? onComplete;

  const StripeEmbeddedCheckoutImpl({
    super.key,
    required this.clientSecret,
    required this.publishableKey,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Stripe Embedded Checkout is only available on Web'));
  }
}
