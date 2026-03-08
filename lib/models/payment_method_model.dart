class PaymentMethodModel {
  final String id;
  final String userId;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final bool isDefault;
  final DateTime createdAt;

  const PaymentMethodModel({
    required this.id,
    required this.userId,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.isDefault,
    required this.createdAt,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return PaymentMethodModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      brand: json['brand'] ?? '',
      last4: json['last4'] ?? '',
      expMonth: _asInt(json['exp_month']),
      expYear: _asInt(json['exp_year']),
      isDefault: (json['is_default'] ?? false) as bool,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'brand': brand,
      'last4': last4,
      'exp_month': expMonth,
      'exp_year': expYear,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PaymentMethodModel copyWith({
    String? id,
    String? userId,
    String? brand,
    String? last4,
    int? expMonth,
    int? expYear,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      brand: brand ?? this.brand,
      last4: last4 ?? this.last4,
      expMonth: expMonth ?? this.expMonth,
      expYear: expYear ?? this.expYear,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}