class PurchaseModel {
  final String id;
  final String userId;
  final String assetId;
  final String? stripeSessionId;
  final double amount;
  final DateTime purchasedAt;

  PurchaseModel({
    required this.id,
    required this.userId,
    required this.assetId,
    this.stripeSessionId,
    required this.amount,
    required this.purchasedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'asset_id': assetId,
    'stripe_session_id': stripeSessionId,
    'amount': amount,
    'purchased_at': purchasedAt.toIso8601String(),
  };

  factory PurchaseModel.fromJson(Map<String, dynamic> json) => PurchaseModel(
    id: json['id'] ?? '',
    userId: json['user_id'] ?? '',
    assetId: json['asset_id'] ?? '',
    stripeSessionId: json['stripe_session_id'],
    amount: (json['amount'] ?? 0).toDouble(),
    purchasedAt: DateTime.parse(json['purchased_at'] ?? DateTime.now().toIso8601String()),
  );

  PurchaseModel copyWith({
    String? id,
    String? userId,
    String? assetId,
    String? stripeSessionId,
    double? amount,
    DateTime? purchasedAt,
  }) => PurchaseModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    assetId: assetId ?? this.assetId,
    stripeSessionId: stripeSessionId ?? this.stripeSessionId,
    amount: amount ?? this.amount,
    purchasedAt: purchasedAt ?? this.purchasedAt,
  );
}
