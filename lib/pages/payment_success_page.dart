import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidi/pages/main_page.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/supabase/supabase_config.dart';

enum _PaymentStatus { loading, success, failed, timeout }

class PaymentSuccessPage extends StatefulWidget {
  final String? sessionId;

  const PaymentSuccessPage({super.key, this.sessionId});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  _PaymentStatus _status = _PaymentStatus.loading;
  String? _errorMessage;
  String? _resolvedSessionId;

  @override
  void initState() {
    super.initState();
    _verifyPayment();
  }

  String? _extractSessionId() {
    final widgetSession = widget.sessionId?.trim();
    final querySession = Uri.base.queryParameters['session_id']?.trim();

    Uri? fragmentUri;
    if (Uri.base.fragment.isNotEmpty) {
      fragmentUri = Uri.tryParse(
        Uri.base.fragment.startsWith('/') ? Uri.base.fragment : '/${Uri.base.fragment}',
      );
    }

    final fragmentSession = fragmentUri?.queryParameters['session_id']?.trim();
    final sessionId = (widgetSession?.isNotEmpty ?? false)
        ? widgetSession
        : (querySession?.isNotEmpty ?? false)
            ? querySession
            : fragmentSession;

    debugPrint(
      'PaymentSuccessPage: session_id sources -> widget=$widgetSession query=$querySession fragment=$fragmentSession resolved=$sessionId',
    );

    return sessionId?.isNotEmpty == true ? sessionId : null;
  }

  Future<void> _verifyPayment() async {
    final sessionId = _extractSessionId();
    if (sessionId == null) {
      setState(() {
        _status = _PaymentStatus.failed;
        _errorMessage = 'Missing payment session_id in the redirect. Please contact support if you were charged.';
      });
      return;
    }

    _resolvedSessionId = sessionId;
    final startedAt = DateTime.now();
    final currentUser = SupabaseConfig.auth.currentUser;

    while (mounted && _status == _PaymentStatus.loading) {
      try {
        final response = await SupabaseConfig.client
            .from('purchases')
            .select('id,user_id,status')
            .eq('stripe_session_id', sessionId)
            .limit(1)
            .maybeSingle();

        debugPrint('PaymentSuccessPage: poll result for $sessionId -> $response');

        if (response != null) {
          final ownerId = response['user_id']?.toString();
          final status = (response['status'] ?? '').toString().toLowerCase();

          if (currentUser != null && ownerId != null && ownerId != currentUser.id) {
            setState(() {
              _status = _PaymentStatus.failed;
              _errorMessage = 'This payment belongs to another account. Please sign in with the correct user.';
            });
            return;
          }

          if (status.isEmpty || status == 'paid') {
            if (mounted) {
              context.read<AppProvider>().clearCart();
              setState(() => _status = _PaymentStatus.success);
            }
            return;
          }

          setState(() {
            _status = _PaymentStatus.failed;
            _errorMessage = 'Payment found but not marked paid (status: $status).';
          });
          return;
        }
      } catch (e, stack) {
        debugPrint('PaymentSuccessPage: polling error for $sessionId -> $e');
        debugPrintStack(stackTrace: stack);
        setState(() {
          _status = _PaymentStatus.failed;
          _errorMessage = 'Unable to verify payment right now. Please try again.';
        });
        return;
      }

      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed >= const Duration(seconds: 15)) {
        if (!mounted) return;
        setState(() {
          _status = _PaymentStatus.timeout;
          _errorMessage = 'Payment confirmation not found yet. If you received a Stripe receipt, retry in a moment or contact support.';
        });
        return;
      }

      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_status) {
      case _PaymentStatus.loading:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Verifying your payment...',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please keep this tab open while we confirm your purchase.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case _PaymentStatus.success:
        return _buildSuccessState(context);
      case _PaymentStatus.failed:
        return _buildErrorState(context, isTimeout: false);
      case _PaymentStatus.timeout:
        return _buildErrorState(context, isTimeout: true);
    }
  }

  Widget _buildSuccessState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.1),
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Payment Successful!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your purchase has been confirmed.\nYou will receive a confirmation email with download links shortly.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainPage()),
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Return to Home'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, {required bool isTimeout}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isTimeout ? Colors.orange : Colors.red).withOpacity(0.1),
          ),
          child: Icon(
            isTimeout ? Icons.access_time : Icons.error_outline,
            color: isTimeout ? Colors.orange : Colors.red,
            size: 48,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isTimeout ? 'Verification Delayed' : 'Verification Failed',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage ?? 'Something went wrong confirming your payment.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _status = _PaymentStatus.loading;
                    _errorMessage = null;
                  });
                  _verifyPayment();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Retry'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainPage()),
                  (route) => false,
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Go Home'),
              ),
            ),
          ],
        ),
        if (_resolvedSessionId != null) ...[
          const SizedBox(height: 12),
          Text(
            'Session: $_resolvedSessionId',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white38),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}