import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:vidi/models/asset_model.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/services/stripe_payment_service.dart';
import 'package:vidi/services/web_payment_service.dart';
import 'package:vidi/config/stripe_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vidi/services/user_service.dart';

import 'package:vidi/widgets/stripe_embedded_checkout.dart';

class CheckoutPage extends StatefulWidget {
  final List<AssetModel> items;

  const CheckoutPage({super.key, required this.items});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _emailController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AppProvider>().currentUser;
      final email = user?.email;
      if (email != null && email.isNotEmpty && _emailController.text.isEmpty) {
        _emailController.text = email;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  double get _total => widget.items.fold(0, (sum, item) => sum + item.price);

  @override
  Widget build(BuildContext context) {
    debugPrint('CheckoutPage: building with \'${widget.items.length}\' items');
    for (final i in widget.items) {
      // High-signal debug for troubleshooting rendering issues
      debugPrint('CheckoutPage item => id=${i.id} title=${i.title} price=${i.price}');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16).copyWith(bottom: 120),
            children: [
              _buildOrderSummary(context),
              const SizedBox(height: 24),
              _buildPaymentSection(context),
              const SizedBox(height: 24),
              _buildContactSection(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(child: _buildTotalFooter(context)),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...widget.items.map((item) {
          final seller = context.read<AppProvider>().getUserById(item.sellerId);
          final rawImageUrl = item.imageUrl;
          final imageUrl = rawImageUrl.trim();
          final hasPreview = imageUrl.isNotEmpty;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF2A2A2A),
                      image: hasPreview
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hasPreview
                        ? null
                        : const Icon(Icons.archive_outlined, color: Colors.white54),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${seller?.name ?? 'Unknown'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${String.fromCharCode(36)}${item.price.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: const Color(0xFF8B5CF6)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (kIsWeb) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF1A1A1A),
              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF635BFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'STRIPE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Secure Checkout',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(Icons.lock_outline, color: Colors.green, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.credit_card, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Secure Stripe checkout opens right here in the app',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF1A1A1A),
              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF635BFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'STRIPE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Secure payment',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(Icons.lock_outline, color: Colors.green, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.credit_card, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Credit/Debit Cards, Apple Pay, Google Pay accepted',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Information',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'your@email.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You will receive download links via email after purchase',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(
          top: BorderSide(color: Color(0xFF2A2A2A)),
        ),
      ),
      child: Column(
        // IMPORTANT: Prevent the footer from expanding to fill the screen
        // inside Scaffold.bottomNavigationBar. If this Column takes the
        // maximum height, it will overlay the page content and you'll only
        // see the footer (appearing like a blank screen with a button).
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '${String.fromCharCode(36)}${_total.toStringAsFixed(2)}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: const Color(0xFF8B5CF6)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processCheckout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Complete Purchase',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AppProvider>();

    if (provider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to make a purchase.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (kIsWeb) {
        await _processWebPayment(provider);
      } else {
        await _processMobilePayment(provider);
      }
    } catch (e) {
      debugPrint('Checkout error: $e');
      if (!mounted) return;
      setState(() => _isProcessing = false);
      
      String errorMessage = 'Payment failed. Please try again.';
      if (e.toString().contains('at least \$0.50')) {
        errorMessage = 'Payment failed: Minimum purchase amount is \$0.50.';
      } else if (e.toString().contains('details: {error:')) {
        // Extract error message from FunctionException
        try {
          final start = e.toString().indexOf('details: {error: ') + 17;
          final end = e.toString().indexOf('}', start);
          if (start != -1 && end != -1) {
            errorMessage = e.toString().substring(start, end);
          }
        } catch (_) {}
      } else if (e.toString().contains('Unauthorized') || e.toString().contains('401')) {
        errorMessage = 'Your session expired. Please sign in and try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handlePurchaseSuccess({required bool recordClientPurchases}) async {
    final provider = context.read<AppProvider>();

    // For web (Stripe Checkout / Embedded Checkout), purchases are recorded by the webhook.
    // For native (PaymentSheet), record on the client.
    if (recordClientPurchases) {
      try {
        await provider.recordPurchases(widget.items);
      } catch (e) {
        debugPrint('recordPurchases failed: $e');
      }
    } else {
      debugPrint('Skipping client-side purchase recording; relying on webhook.');
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);
    _showSuccessDialog();
  }

  Future<void> _processWebPayment(AppProvider provider) async {
    try {
      // Create Stripe Checkout Session via Supabase Edge Function
      final session = await WebPaymentService.createCheckoutSession(
        amount: _total,
        currency: StripeConfig.currency,
        userId: provider.currentUser!.id,
        assetIds: widget.items.map((item) => item.id).toList(),
        customerEmail: _emailController.text,
      );

      if (session == null || session.sessionId.isEmpty) {
        throw Exception('Failed to create checkout session. Check console logs for details.');
      }

      final clientSecret = session.clientSecret;
      final sessionUrl = session.sessionUrl;

      if (clientSecret == null || clientSecret.isEmpty) {
        if (!mounted) return;
        setState(() => _isProcessing = false);

        // Store pending assets for recovery after redirect
        if (kIsWeb) {
           try {
             final prefs = await SharedPreferences.getInstance();
             await prefs.setStringList('pending_purchase_assets', widget.items.map((e) => e.id).toList());
           } catch (e) {
             debugPrint('Failed to save pending purchase: $e');
           }
        }

        try {
          await WebPaymentService.redirectToCheckout(
            sessionId: session.sessionId,
            sessionUrl: sessionUrl,
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to open Stripe Checkout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      setState(() => _isProcessing = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final size = MediaQuery.of(context).size;
          // Use up to 92% of the viewport height to ensure visibility on smaller screens
          final maxDialogHeight = size.height * 0.92;
          final maxDialogWidth = size.width.clamp(0, 1000).toDouble();
          // Allocate most of the dialog height to the checkout surface
          final checkoutHeight = (maxDialogHeight - 64).clamp(400, 1100);

          return Dialog(
            backgroundColor: const Color(0xFF1E1E1E),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxDialogWidth > 900 ? 900 : maxDialogWidth,
                // Let the dialog grow tall but stay within the viewport
                maxHeight: maxDialogHeight,
              ),
              child: SingleChildScrollView(
                // If content exceeds the max height, allow the whole dialog to scroll
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text(
                              'Secure Checkout',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Fixed-height container that allows the embedded content to scroll internally
                    SizedBox(
                      height: checkoutHeight.toDouble(),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        child: StripeEmbeddedCheckout(
                          clientSecret: clientSecret,
                          onComplete: () {
                            Navigator.of(context).pop();
                            // Web checkout success → rely on server webhook to record purchases
                            _handlePurchaseSuccess(recordClientPurchases: false);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      rethrow;
    }
  }

  Future<void> _processMobilePayment(AppProvider provider) async {
    // Fetch seller's stripeAccountId
    if (widget.items.isEmpty) return;
    
    String? sellerStripeAccountId;
    try {
      final sellerId = widget.items.first.sellerId;
      final seller = await UserService().getUserById(sellerId);
      sellerStripeAccountId = seller?.stripeAccountId;
    } catch (e) {
      debugPrint('Error fetching seller info: $e');
    }

    if (sellerStripeAccountId == null || sellerStripeAccountId.isEmpty) {
      throw Exception('This seller has not connected their Stripe account yet.');
    }

    // Create payment intent
    final clientSecret = await StripePaymentService.createPaymentIntent(
      amount: _total,
      currency: StripeConfig.currency,
      userId: provider.currentUser!.id,
      assetIds: widget.items.map((item) => item.id).toList(),
      sellerStripeAccountId: sellerStripeAccountId,
    );
    
    if (clientSecret == null) {
      throw Exception('Failed to initialize payment. Please check your Stripe configuration.');
    }
    
    // Present payment sheet
    final success = await StripePaymentService.presentPaymentSheet(
      clientSecret: clientSecret,
      customerEmail: _emailController.text,
    );
    
    if (!success) {
      throw Exception('Payment was cancelled or failed');
    }
    
    // Native flow → relying on webhook now to record purchase in DB
    await _handlePurchaseSuccess(recordClientPurchases: false);
  }

  void _showSuccessDialog() {
    final provider = context.read<AppProvider>();
    provider.clearCart();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Purchase Complete!'),
          ],
        ),
        content: Text(
          'Your purchase has been processed successfully. You will receive an email at ${_emailController.text} with download instructions.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              if (widget.items.length > 1) {
                Navigator.pop(context);
              }
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
