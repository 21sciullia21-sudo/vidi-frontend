import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart'; // We are bringing the native Stripe UI back!

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
      // Convert amount to cents (Stripe uses smallest currency unit)
      final amountInCents = (amount * 100).round();
      
      // Pointing to your TRUE backend!
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
        
        // FIX: Grab the 'clientSecret' instead of the 'url'
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
      // 1. Initialize the Payment Sheet with the secret code from Vercel
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Vidiplanet', 
          // Set to true if you are using test keys:
          testEnv: true, 
        ),
      );

      // 2. Present the pop-up to the user
      await Stripe.instance.presentPaymentSheet();
      
      // If it reaches this line without crashing, the payment was successful!
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