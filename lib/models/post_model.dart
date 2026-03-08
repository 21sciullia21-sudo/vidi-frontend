class PostModel {
  final String id;
  final String userId;
  final String content;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final List<String> likes;
  final int commentCount;
  final DateTime createdAt;
  final Map<String, String>? cameraInfo;
  final int? clipLength;
  final bool isColorGraded;
  final String? videoFormat;
  // Image metadata
  final Map<String, String>? imageCameraInfo;
  final String? imageFormat;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.likes = const [],
    this.commentCount = 0,
    required this.createdAt,
    this.cameraInfo,
    this.clipLength,
    this.isColorGraded = false,
    this.videoFormat,
    this.imageCameraInfo,
    this.imageFormat,
  });

  // Helper getters for before/after posts
  // Convention: if imageFormat == "BEFORE_AFTER" and imageUrls has 2 items,
  // then imageUrls[0] is before and imageUrls[1] is after
  bool get isBeforeAfter => imageFormat == 'BEFORE_AFTER' && imageUrls.length == 2;
  String? get beforeImageUrl => isBeforeAfter ? imageUrls[0] : null;
  String? get afterImageUrl => isBeforeAfter ? imageUrls[1] : null;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'content': content,
      'image_urls': imageUrls,
      'video_urls': videoUrls,
      'likes': likes,
      'comment_count': commentCount,
      'created_at': createdAt.toIso8601String(),
      'is_color_graded': isColorGraded,
    };
    
    // Only include optional fields if they have values
    if (cameraInfo != null) json['camera_info'] = cameraInfo!;
    if (clipLength != null) json['clip_length'] = clipLength!;
    if (videoFormat != null) json['video_format'] = videoFormat!;
    if (imageCameraInfo != null) json['image_camera_info'] = imageCameraInfo!;
    if (imageFormat != null) json['image_format'] = imageFormat!;
    
    return json;
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      content: json['content'] ?? '',
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      videoUrls: List<String>.from(json['video_urls'] ?? []),
      likes: List<String>.from(json['likes'] ?? []),
      commentCount: json['comment_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      cameraInfo: json['camera_info'] != null ? Map<String, String>.from(json['camera_info']) : null,
      clipLength: json['clip_length'],
      isColorGraded: json['is_color_graded'] ?? false,
      videoFormat: json['video_format'],
      imageCameraInfo: json['image_camera_info'] != null ? Map<String, String>.from(json['image_camera_info']) : null,
      imageFormat: json['image_format'],
    );
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? content,
    List<String>? imageUrls,
    List<String>? videoUrls,
    List<String>? likes,
    int? commentCount,
    DateTime? createdAt,
    Map<String, String>? cameraInfo,
    int? clipLength,
    bool? isColorGraded,
    String? videoFormat,
    Map<String, String>? imageCameraInfo,
    String? imageFormat,
  }) => PostModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    content: content ?? this.content,
    imageUrls: imageUrls ?? this.imageUrls,
    videoUrls: videoUrls ?? this.videoUrls,
    likes: likes ?? this.likes,
    commentCount: commentCount ?? this.commentCount,
    createdAt: createdAt ?? this.createdAt,
    cameraInfo: cameraInfo ?? this.cameraInfo,
    clipLength: clipLength ?? this.clipLength,
    isColorGraded: isColorGraded ?? this.isColorGraded,
    videoFormat: videoFormat ?? this.videoFormat,
    imageCameraInfo: imageCameraInfo ?? this.imageCameraInfo,
    imageFormat: imageFormat ?? this.imageFormat,
  );
}
