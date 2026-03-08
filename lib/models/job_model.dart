class JobModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final double budgetMin;
  final double budgetMax;
  final DateTime deadline;
  final String clientId;
  final String status;
  final String requirements;
  final List<String> referenceImages;
  final DateTime postedAt;
  final int bidCount;
  final String? assignedEditorId;

  JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.budgetMin,
    required this.budgetMax,
    required this.deadline,
    required this.clientId,
    this.status = 'open',
    this.requirements = '',
    this.referenceImages = const [],
    required this.postedAt,
    this.bidCount = 0,
    this.assignedEditorId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'budget_min': budgetMin,
    'budget_max': budgetMax,
    'deadline': deadline.toIso8601String(),
    'client_id': clientId,
    'status': status,
    'requirements': requirements,
    'reference_images': referenceImages,
    'posted_at': postedAt.toIso8601String(),
    'bid_count': bidCount,
    'assigned_editor_id': assignedEditorId,
  };

  factory JobModel.fromJson(Map<String, dynamic> json) => JobModel(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    category: json['category'] ?? '',
    budgetMin: (json['budget_min'] ?? 0).toDouble(),
    budgetMax: (json['budget_max'] ?? 0).toDouble(),
    deadline: DateTime.parse(json['deadline'] ?? DateTime.now().toIso8601String()),
    clientId: json['client_id'] ?? '',
    status: json['status'] ?? 'open',
    requirements: json['requirements'] ?? '',
    referenceImages: List<String>.from(json['reference_images'] ?? []),
    postedAt: DateTime.parse(json['posted_at'] ?? DateTime.now().toIso8601String()),
    bidCount: json['bid_count'] ?? 0,
    assignedEditorId: json['assigned_editor_id'],
  );

  JobModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? budgetMin,
    double? budgetMax,
    DateTime? deadline,
    String? clientId,
    String? status,
    String? requirements,
    List<String>? referenceImages,
    DateTime? postedAt,
    int? bidCount,
    String? assignedEditorId,
  }) => JobModel(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    budgetMin: budgetMin ?? this.budgetMin,
    budgetMax: budgetMax ?? this.budgetMax,
    deadline: deadline ?? this.deadline,
    clientId: clientId ?? this.clientId,
    status: status ?? this.status,
    requirements: requirements ?? this.requirements,
    referenceImages: referenceImages ?? this.referenceImages,
    postedAt: postedAt ?? this.postedAt,
    bidCount: bidCount ?? this.bidCount,
    assignedEditorId: assignedEditorId ?? this.assignedEditorId,
  );
}
