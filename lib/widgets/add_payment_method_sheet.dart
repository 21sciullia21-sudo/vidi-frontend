import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vidi/models/payment_method_model.dart';
import 'package:vidi/providers/app_provider.dart';

class AddPaymentMethodSheet extends StatefulWidget {
  const AddPaymentMethodSheet({super.key});

  @override
  State<AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<AddPaymentMethodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter card number';
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 12 || digits.length > 19) {
      return 'Card number must be 12-19 digits';
    }
    return null;
  }

  String? _validateExpiry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter expiry MM/YY';
    }
    final parts = value.split('/');
    if (parts.length != 2) {
      return 'Use format MM/YY';
    }
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1].length == 2 ? '20${parts[1]}' : parts[1]);
    if (month == null || month < 1 || month > 12) {
      return 'Invalid month';
    }
    if (year == null) {
      return 'Invalid year';
    }
    final now = DateTime.now();
    final expiry = DateTime(year, month + 1);
    if (!expiry.isAfter(DateTime(now.year, now.month))) {
      return 'Card expired';
    }
    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    setState(() => _isSaving = true);

    try {
      final digits = _cardNumberController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final expParts = _expiryController.text.split('/');
      final expMonth = int.parse(expParts[0]);
      final expYear = expParts[1].length == 2
          ? int.parse('20${expParts[1]}')
          : int.parse(expParts[1]);

      final method = await provider.addPaymentMethod(
        cardNumber: digits,
        expMonth: expMonth,
        expYear: expYear,
      );

      if (!mounted) return;

      if (method != null) {
        Navigator.of(context).pop<PaymentMethodModel>(method);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save payment method. Try again.')),
        );
      }
    } catch (e) {
      debugPrint('Save payment method error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save payment method. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets + const EdgeInsets.all(16);
    return Padding(
      padding: padding,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Payment Method',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Card number',
                hintText: '1234 5678 9012 3456',
                prefixIcon: Icon(Icons.credit_card),
              ),
              autocorrect: false,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validateCardNumber,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _expiryController,
              decoration: const InputDecoration(
                labelText: 'Expiry',
                hintText: 'MM/YY',
                prefixIcon: Icon(Icons.calendar_month),
              ),
              keyboardType: TextInputType.datetime,
              validator: _validateExpiry,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save card'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}