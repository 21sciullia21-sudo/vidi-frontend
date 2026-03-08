import 'package:vidi/models/payment_method_model.dart';
import 'package:vidi/supabase/supabase_config.dart';

class PaymentService {
  static const String _table = 'payment_methods';

  Future<List<PaymentMethodModel>> getPaymentMethods(String userId) async {
    try {
      final data = await SupabaseService.select(
        _table,
        filters: {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
      );
      return data.map(PaymentMethodModel.fromJson).toList();
    } catch (e) {
      print('Error fetching payment methods: $e');
      return [];
    }
  }

  Future<PaymentMethodModel?> insertPaymentMethod(
    PaymentMethodModel method,
  ) async {
    try {
      final inserted = await SupabaseService.insert(_table, method.toJson());
      if (inserted.isNotEmpty) {
        return PaymentMethodModel.fromJson(inserted.first);
      }
    } catch (e) {
      print('Error inserting payment method: $e');
    }
    return null;
  }

  Future<void> updateDefaultMethod(String userId, String methodId) async {
    try {
      // Clear current defaults
      await SupabaseService.update(
        _table,
        {'is_default': false},
        filters: {'user_id': userId},
      );

      // Set new default
      await SupabaseService.update(
        _table,
        {'is_default': true},
        filters: {'id': methodId},
      );
    } catch (e) {
      print('Error updating default payment method: $e');
    }
  }

  Future<void> deletePaymentMethod(String methodId) async {
    try {
      await SupabaseService.delete(
        _table,
        filters: {'id': methodId},
      );
    } catch (e) {
      print('Error deleting payment method: $e');
    }
  }
}