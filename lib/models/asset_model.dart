class AssetModel {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final String downloadUrl;
  final int downloads;
  final DateTime createdAt;

  AssetModel({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl = '',
    this.downloadUrl = '',
    this.downloads = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'seller_id': sellerId,
    'title': title,
    'description': description,
    'price': price,
    'category': category,
    'image_url': imageUrl,
    'download_url': downloadUrl,
    'downloads': downloads,
    'created_at': createdAt.toIso8601String(),
  };

  factory AssetModel.fromJson(Map<String, dynamic> json) => AssetModel(
    id: json['id'] ?? '',
    sellerId: json['seller_id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
    category: json['category'] ?? '',
    imageUrl: json['image_url'] ?? '',
    downloadUrl: json['download_url'] ?? '',
    downloads: json['downloads'] ?? 0,
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
  );

  AssetModel copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    String? downloadUrl,
    int? downloads,
    DateTime? createdAt,
  }) => AssetModel(
    id: id ?? this.id,
    sellerId: sellerId ?? this.sellerId,
    title: title ?? this.title,
    description: description ?? this.description,
    price: price ?? this.price,
    category: category ?? this.category,
    imageUrl: imageUrl ?? this.imageUrl,
    downloadUrl: downloadUrl ?? this.downloadUrl,
    downloads: downloads ?? this.downloads,
    createdAt: createdAt ?? this.createdAt,
  );
}
