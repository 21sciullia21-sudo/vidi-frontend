import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vidi/config/stripe_config.dart';

class StripePaymentService {
  /// Creates a payment intent via Vercel Serverless Function
  /// Returns the client secret needed to confirm the payment
  static Future<String?> createPaymentIntent({
    required double amount,
    required String currency,
    required String userId,
    required List<String> assetIds,
    required String sellerStripeAccountId,
  }) async {
    try {
      // Convert amount to cents (Stripe uses smallest currency unit)
      final amountInCents = (amount * 100).round();
      
      // Call Vercel Serverless Function to create payment intent
      // TODO: Replace with your actual Vercel project domain
      final url = Uri.parse('https://vidi-backend-ivory.vercel.app/api/checkout');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amountInCents,
          'currency': currency.toLowerCase(),
          'buyerId': userId,
          'assetIds': assetIds,
          'sellerStripeAccountId': sellerStripeAccountId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['clientSecret'] != null) {
          return data['clientSecret'] as String;
        }
      }
      
      print('Failed to create payment intent: ${response.body}');
      return null;
    } catch (e) {
      print('Error creating payment intent: $e');
      return null;
    }
  }
  
  /// Presents the Stripe payment sheet and processes payment
  static Future<bool> presentPaymentSheet({
    required String clientSecret,
    required String customerEmail,
  }) async {
    try {
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: StripeConfig.merchantDisplayName,
          style: ThemeMode.dark,
        ),
      );
      
      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();
      
      return true;
    } on StripeException catch (e) {
      print('Stripe error: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      print('Error presenting payment sheet: $e');
      return false;
    }
  }
}
