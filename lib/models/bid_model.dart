class BidModel {
  final String id;
  final String jobId;
  final String editorId;
  final double amount;
  final int deliveryDays;
  final String proposal;
  final DateTime submittedAt;
  final String status;
  final DateTime? acceptedAt;

  BidModel({
    required this.id,
    required this.jobId,
    required this.editorId,
    required this.amount,
    required this.deliveryDays,
    required this.proposal,
    required this.submittedAt,
    this.status = 'pending',
    this.acceptedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'job_id': jobId,
    'editor_id': editorId,
    'amount': amount,
    'delivery_days': deliveryDays,
    'proposal': proposal,
    'submitted_at': submittedAt.toIso8601String(),
    'status': status,
    'accepted_at': acceptedAt?.toIso8601String(),
  };

  factory BidModel.fromJson(Map<String, dynamic> json) => BidModel(
    id: json['id'] ?? '',
    jobId: json['job_id'] ?? '',
    editorId: json['editor_id'] ?? '',
    amount: (json['amount'] ?? 0).toDouble(),
    deliveryDays: json['delivery_days'] ?? 0,
    proposal: json['proposal'] ?? '',
    submittedAt: DateTime.parse(json['submitted_at'] ?? DateTime.now().toIso8601String()),
    status: json['status'] ?? 'pending',
    acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']) : null,
  );

  BidModel copyWith({
    String? id,
    String? jobId,
    String? editorId,
    double? amount,
    int? deliveryDays,
    String? proposal,
    DateTime? submittedAt,
    String? status,
    DateTime? acceptedAt,
  }) => BidModel(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    editorId: editorId ?? this.editorId,
    amount: amount ?? this.amount,
    deliveryDays: deliveryDays ?? this.deliveryDays,
    proposal: proposal ?? this.proposal,
    submittedAt: submittedAt ?? this.submittedAt,
    status: status ?? this.status,
    acceptedAt: acceptedAt ?? this.acceptedAt,
  );
}
