import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // This replaces flutter_stripe
import 'package:vidi/config/stripe_config.dart';

class StripePaymentService {
  /// Creates a Stripe Checkout Session via Vercel Serverless Function
  /// Returns the checkout URL (taking the place of the old client secret)
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
        // We grab the 'url' from Vercel, but return it as a string 
        // so your existing UI code doesn't break
        if (data['url'] != null) {
          return data['url'] as String;
        }
      }
      
      print('Failed to create checkout session: ${response.body}');
      return null;
    } catch (e) {
      print('Error creating checkout session: $e');
      return null;
    }
  }
  
  /// Opens the Stripe web checkout instead of the native payment sheet
  static Future<bool> presentPaymentSheet({
    required String clientSecret, // This variable now secretly holds the URL
    required String customerEmail, // Kept so your UI doesn't throw an error
  }) async {
    try {
      // Launch the URL in the device's default browser
      final Uri url = Uri.parse(clientSecret);
      
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        print('Could not launch Stripe Checkout at $clientSecret');
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error opening checkout browser: $e');
      return false;
    }
  }
}