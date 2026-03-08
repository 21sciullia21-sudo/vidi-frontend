class UserModel {
  final String id;
  final String name;
  final String email;
  final String profilePicUrl;
  final String bio;
  final String skillLevel;
  final double hourlyRate;
  final String location;
  final String currentRole;
  final int followers;
  final int following;
  final int projectCount;
  final List<String> specializations;
  final bool isNew;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, String> socialLinks;
  final String portfolioLink;
  final String portfolioFile;
  final List<String> followingIds;
  final String? editingStyle;
  final List<String> gearBadges;
  final String? featuredReelUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicUrl = '',
    this.bio = '',
    this.skillLevel = 'Beginner',
    this.hourlyRate = 0,
    this.location = '',
    this.currentRole = 'freelancer',
    this.followers = 0,
    this.following = 0,
    this.projectCount = 0,
    this.specializations = const [],
    this.isNew = false,
    required this.createdAt,
    required this.updatedAt,
    this.socialLinks = const {},
    this.portfolioLink = '',
    this.portfolioFile = '',
    this.followingIds = const [],
    this.editingStyle,
    this.gearBadges = const [],
    this.featuredReelUrl,
    this.stripeAccountId,
  });

  final String? stripeAccountId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': name,
    'full_name': name,
    'email': email,
    'avatar_url': profilePicUrl,
    'bio': bio,
    'user_role': currentRole,
    'skill_level': skillLevel,
    'hourly_rate': hourlyRate,
    'location': location,
    'project_count': projectCount,
    'followers': followers,
    'following': following,
    'specializations': specializations,
    'following_ids': followingIds,
    'is_new': isNew,
    'instagram_url': socialLinks['instagram'] ?? '',
    'twitter_url': socialLinks['twitter'] ?? '',
    'youtube_url': socialLinks['youtube'] ?? '',
    'linkedin_url': socialLinks['linkedin'] ?? '',
    'website_url': socialLinks['website'] ?? '',
    'portfolio_url': portfolioLink,
    'portfolio_file': portfolioFile,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'editing_style': editingStyle,
    'gear_badges': gearBadges,
    'featured_reel_url': featuredReelUrl,
    'stripe_account_id': stripeAccountId,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final followingRaw = json['following_ids'];
    List<String> followingList = [];
    if (followingRaw is List) {
      followingList = List<String>.from(followingRaw);
    }
    
    return UserModel(
      id: json['id'] ?? '',
      name: json['username'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      profilePicUrl: json['avatar_url'] ?? '',
      bio: json['bio'] ?? '',
      skillLevel: json['skill_level'] ?? 'Beginner',
      hourlyRate: (json['hourly_rate'] is num)
          ? (json['hourly_rate'] as num).toDouble()
          : double.tryParse(json['hourly_rate']?.toString() ?? '0') ?? 0,
      location: json['location'] ?? '',
      projectCount: json['project_count'] is int ? json['project_count'] : int.tryParse(json['project_count']?.toString() ?? '0') ?? 0,
      currentRole: json['user_role'] ?? 'freelancer',
      followers: json['followers'] is int
          ? json['followers']
          : int.tryParse(json['followers']?.toString() ?? '0') ?? 0,
      following: json['following'] is int
          ? json['following']
          : int.tryParse(json['following']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      socialLinks: {
        'instagram': json['instagram_url'] ?? '',
        'twitter': json['twitter_url'] ?? '',
        'youtube': json['youtube_url'] ?? '',
        'linkedin': json['linkedin_url'] ?? '',
        'website': json['website_url'] ?? '',
      },
      portfolioLink: json['portfolio_url'] ?? '',
      portfolioFile: json['portfolio_file'] ?? '',
      specializations: (json['specializations'] is List)
          ? List<String>.from(json['specializations'])
          : <String>[],
      isNew: json['is_new'] ?? false,
      followingIds: followingList,
      editingStyle: json['editing_style'],
      gearBadges: (json['gear_badges'] is List)
          ? List<String>.from(json['gear_badges'])
          : <String>[],
      featuredReelUrl: json['featured_reel_url'],
      stripeAccountId: json['stripe_account_id'],
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePicUrl,
    String? bio,
    String? skillLevel,
    double? hourlyRate,
    String? location,
    String? currentRole,
    int? followers,
    int? following,
    int? projectCount,
    List<String>? specializations,
    bool? isNew,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, String>? socialLinks,
    String? portfolioLink,
    String? portfolioFile,
    List<String>? followingIds,
    String? editingStyle,
    List<String>? gearBadges,
    String? featuredReelUrl,
    String? stripeAccountId,
  }) => UserModel(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    profilePicUrl: profilePicUrl ?? this.profilePicUrl,
    bio: bio ?? this.bio,
    skillLevel: skillLevel ?? this.skillLevel,
    hourlyRate: hourlyRate ?? this.hourlyRate,
    location: location ?? this.location,
    currentRole: currentRole ?? this.currentRole,
    followers: followers ?? this.followers,
    following: following ?? this.following,
    projectCount: projectCount ?? this.projectCount,
    specializations: specializations ?? this.specializations,
    isNew: isNew ?? this.isNew,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    socialLinks: socialLinks ?? this.socialLinks,
    portfolioLink: portfolioLink ?? this.portfolioLink,
    portfolioFile: portfolioFile ?? this.portfolioFile,
    followingIds: followingIds ?? this.followingIds,
    editingStyle: editingStyle ?? this.editingStyle,
    gearBadges: gearBadges ?? this.gearBadges,
    featuredReelUrl: featuredReelUrl ?? this.featuredReelUrl,
    stripeAccountId: stripeAccountId ?? this.stripeAccountId,
  );
}
