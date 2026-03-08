import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;

class StripeEmbeddedCheckoutImpl extends StatefulWidget {
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
  State<StripeEmbeddedCheckoutImpl> createState() => _StripeEmbeddedCheckoutImplState();
}

class _StripeEmbeddedCheckoutImplState extends State<StripeEmbeddedCheckoutImpl> {
  late final String _divId;
  dynamic _checkout;
  static const String _activeCheckoutKey = '__stripeEmbeddedCheckout';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _divId = 'stripe-checkout-${DateTime.now().millisecondsSinceEpoch}';
    
    // Register the view factory
    ui_web.platformViewRegistry.registerViewFactory(
      _divId,
      (int viewId) {
        final document = js_util.getProperty(js_util.globalThis, 'document');
        final element = js_util.callMethod(document, 'createElement', ['div']);
        js_util.setProperty(element, 'id', _divId);
        js_util.setProperty(element.style, 'height', '100%');
        js_util.setProperty(element.style, 'width', '100%');
        // Ensure overflow content (long forms) remain scrollable within the container
        js_util.setProperty(element.style, 'overflow', 'auto');
        return element as Object;
      },
    );

    _initializeCheckout();
  }

  Future<void> _initializeCheckout() async {
    try {
      debugPrint('StripeEmbeddedCheckout: Initializing checkout...');
      await _cleanupCheckout();

      // Use js_util to get Stripe constructor and create instance
      final stripeConstructor = js_util.getProperty(js_util.globalThis, 'Stripe');
      if (stripeConstructor == null) {
        throw Exception('Stripe.js not loaded');
      }
      
      final stripe = js_util.callConstructor(stripeConstructor, [widget.publishableKey]);
      debugPrint('StripeEmbeddedCheckout: Stripe instance created');

      final options = js_util.newObject();
      js_util.setProperty(options, 'clientSecret', widget.clientSecret);

      // Add onComplete callback if provided
      if (widget.onComplete != null) {
        js_util.setProperty(
          options, 
          'onComplete', 
          js.allowInterop((_) {
            debugPrint('StripeEmbeddedCheckout: onComplete triggered');
            widget.onComplete!();
          })
        );
      }

      debugPrint('StripeEmbeddedCheckout: calling initEmbeddedCheckout');
      final promise = js_util.callMethod(stripe, 'initEmbeddedCheckout', [options]);
      _checkout = await js_util.promiseToFuture(promise);
      js_util.setProperty(js_util.globalThis, _activeCheckoutKey, _checkout);
      debugPrint('StripeEmbeddedCheckout: checkout initialized');
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Wait for the HtmlElementView to be rendered in the DOM
        debugPrint('StripeEmbeddedCheckout: waiting for element #$_divId');
        final element = await _waitForElement(_divId);
        
        if (element != null) {
          debugPrint('StripeEmbeddedCheckout: element found, mounting...');
          js_util.callMethod(_checkout, 'mount', ['#$_divId']);
          debugPrint('StripeEmbeddedCheckout: mount called');
        } else {
          throw Exception('Timeout waiting for checkout container element #$_divId');
        }
      }
    } catch (e) {
      debugPrint('Error initializing Stripe Embedded Checkout: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Object?> _waitForElement(String id, {int timeoutMs = 5000}) async {
    final document = js_util.getProperty(js_util.globalThis, 'document');
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime).inMilliseconds < timeoutMs) {
      final element = js_util.callMethod(document, 'getElementById', [id]);
      if (element != null) return element;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return null;
  }

  Future<void> _cleanupCheckout({bool onlyIfMatches = false}) async {
    final existingCheckout = js_util.getProperty(js_util.globalThis, _activeCheckoutKey);
    if (existingCheckout == null) return;
    if (onlyIfMatches && !identical(existingCheckout, _checkout)) return;

    try {
      final result = js_util.callMethod(existingCheckout, 'destroy', []);
      if (result != null) {
        try {
          await js_util.promiseToFuture(result);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error destroying checkout: $e');
    } finally {
      js_util.setProperty(js_util.globalThis, _activeCheckoutKey, null);
    }
  }

  @override
  void dispose() {
    unawaited(_cleanupCheckout(onlyIfMatches: true));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Failed to load checkout: $_error', 
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Stack(
      children: [
        HtmlElementView(viewType: _divId),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
