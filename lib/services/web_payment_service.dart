import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:js_util' as js_util;

import 'package:flutter/foundation.dart';
import 'package:vidi/config/stripe_config.dart';
import 'package:vidi/supabase/supabase_config.dart';

@JS('Stripe')
external JSFunction get _StripeConstructor;

@JS()
@staticInterop
class JSStripe {}

extension JSStripeExtension on JSStripe {
  external JSPromise confirmCardPayment(String clientSecret, JSObject? options);
}

class StripeCheckoutSession {
  const StripeCheckoutSession({
    required this.sessionId,
    this.sessionUrl,
    this.clientSecret,
  });

  final String sessionId;
  final String? sessionUrl;
  final String? clientSecret;
}

class WebPaymentService {
  /// Create a PaymentIntent via Supabase Edge Function
  static Future<String?> createPaymentIntent({
    required double amount,
    required String currency,
    required String userId,
    required List<String> assetIds,
    required String customerEmail,
  }) async {
    if (!kIsWeb) return null;

    try {
      final amountInCents = (amount * 100).round();

      if (kDebugMode) {
        print('📤 Calling Edge Function: create-payment-intent');
        print('📦 Payload: amount=$amountInCents, currency=$currency, userId=$userId');
      }

      final response = await SupabaseConfig.client.functions.invoke(
        'create-payment-intent',
        body: {
          'amount': amountInCents,
          'currency': currency.toLowerCase(),
          'userId': userId,
          'assetIds': assetIds,
        },
      );

      if (kDebugMode) {
        print('📥 Edge Function Response: ${response.data}');
        print('⚠️ Response Status: ${response.status}');
      }

      if (response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final clientSecret = (data['clientSecret'] ?? data['client_secret']) as String?;
        
        if (clientSecret == null && kDebugMode) {
          print('❌ No clientSecret in response. Full data: $data');
        }
        
        return clientSecret;
      }

      if (kDebugMode) {
        print('❌ Response data is null');
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating payment intent: $e');
      }
      rethrow;
    }
  }

  /// Create a Checkout Session via Supabase Edge Function
  static Future<StripeCheckoutSession?> createCheckoutSession({
    required double amount,
    required String currency,
    required String userId,
    required List<String> assetIds,
    required String customerEmail,
  }) async {
    if (!kIsWeb) return null;

    try {
      final amountInCents = (amount * 100).round();
      final uri = Uri.base;
      // Use only scheme/host/port to avoid passing long preview paths or query params to Stripe
      final frontendUrl = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';

      if (kDebugMode) {
        print('📤 Calling Edge Function: create-checkout-session');
        print('📦 Payload: amount=$amountInCents, currency=$currency, userId=$userId, email=$customerEmail, frontendUrl=$frontendUrl');
      }

      final response = await SupabaseConfig.client.functions.invoke(
        'create-checkout-session',
        body: {
          'amount': amountInCents,
          'currency': currency.toLowerCase(),
          'userId': userId,
          'assetIds': assetIds,
          'customerEmail': customerEmail,
          'frontendUrl': frontendUrl,
        },
      );

      if (kDebugMode) {
        print('📥 Edge Function Response: ${response.data}');
        print('⚠️ Response Status: ${response.status}');
      }

      if (response.data != null) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final sessionId = data['sessionId'] as String?;
        final sessionUrl = (data['sessionUrl'] ?? data['url']) as String?;
        final clientSecret = (data['clientSecret'] ?? data['client_secret']) as String?;

        if (sessionId == null || sessionId.isEmpty) {
          if (kDebugMode) {
            print('❌ No sessionId in response. Full data: $data');
          }
          return null;
        }

        if (kDebugMode && sessionUrl == null && clientSecret == null) {
          print('ℹ️ No sessionUrl or clientSecret in response');
        }

        return StripeCheckoutSession(
          sessionId: sessionId,
          sessionUrl: sessionUrl,
          clientSecret: clientSecret,
        );
      }

      if (kDebugMode) {
        print('❌ Response data is null');
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating checkout session: $e');
      }
      rethrow;
    }
  }

  /// Redirect to Stripe Checkout
  ///
  /// Navigates the current tab to the Stripe Checkout session URL.
  static Future<void> redirectToCheckout({
    required String sessionId,
    String? sessionUrl,
  }) async {
    if (!kIsWeb) {
      throw Exception('Web payment only available on web platform');
    }

    // 1. Prefer the explicit session URL returned by Stripe
    String targetUrl = sessionUrl ?? '';
    
    // 2. Fallback to constructing the URL manually if missing
    if (targetUrl.isEmpty) {
      if (kDebugMode) {
        print('ℹ️ No sessionUrl provided. Constructing fallback URL...');
      }
      targetUrl = 'https://checkout.stripe.com/c/pay/$sessionId';
    }

    try {
      if (kDebugMode) {
        print('🔗 Opening Stripe Checkout: $targetUrl');
      }
      
      js_util.callMethod(js_util.globalThis, 'open', [targetUrl, '_self']);
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to open Stripe Checkout: $e');
      }
      rethrow;
    }
  }

  /// Confirm card payment with Stripe.js
  static Future<Map<String, dynamic>> confirmPayment({
    required String clientSecret,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
  }) async {
    if (!kIsWeb) {
      throw Exception('Web payment only available on web platform');
    }

    try {
      // Initialize Stripe
      final stripe = _StripeConstructor.callAsFunction(_StripeConstructor, StripeConfig.publishableKey.toJS) as JSStripe;

      // Create payment method data
      final paymentMethodData = {
        'card': {
          'number': cardNumber,
          'exp_month': int.parse(expMonth),
          'exp_year': int.parse(expYear),
          'cvc': cvc,
        }
      }.jsify() as JSObject;

      final options = {
        'payment_method': {
          'card': paymentMethodData,
        }
      }.jsify() as JSObject;

      if (kDebugMode) {
        print('💳 Confirming payment with Stripe...');
      }

      // Confirm the payment
      final result = await stripe.confirmCardPayment(clientSecret, options).toDart;
      final resultMap = (result as JSObject).dartify() as Map<String, dynamic>;

      if (kDebugMode) {
        print('✅ Payment result: $resultMap');
      }

      return resultMap;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error confirming payment: $e');
      }
      rethrow;
    }
  }
}
