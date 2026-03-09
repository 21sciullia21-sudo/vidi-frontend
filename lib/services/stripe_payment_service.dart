import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart'; 

class StripePaymentService {
  /// Asks Vercel for the secret code to open the payment sheet
  static Future<String?> createPaymentIntent({
    required double amount,
    required String currency,
    required String userId,
    required List<String> assetIds,
    required String sellerStripeAccountId,
  }) async {
    try {
      final amountInCents = (amount * 100).round();
      
      // Pointing to your active vidi-upload domain
      final url = Uri.parse('https://vidi-upload.vercel.app/api/checkout');
      
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
  
  /// Opens the native Stripe Payment Sheet pop-up
  static Future<bool> presentPaymentSheet({
    required String clientSecret,
    required String customerEmail, 
  }) async {
    try {
      // 1. Initialize the Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Vidiplanet', 
          // testEnv: true has been removed to satisfy the v12.0.0 compiler
        ),
      );

      // 2. Present the pop-up
      await Stripe.instance.presentPaymentSheet();
      
      return true; 
      
    } on StripeException catch (e) {
      print('Stripe Error: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      print('Error presenting payment sheet: $e');
      return false;
    }
  }
}