import 'package:vidi/models/user_model.dart';
import 'package:vidi/supabase/supabase_config.dart';

class UserService {
  Future<List<UserModel>> getUsers() async {
    try {
      final data = await SupabaseService.select('users');
      return data.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final authUser = SupabaseConfig.auth.currentUser;
      if (authUser == null) {
        return null;
      }

      final existingUser = await getUserById(authUser.id);
      if (existingUser != null) {
        return existingUser;
      }

      final now = DateTime.now();
      final inferredName = (authUser.userMetadata?['full_name'] as String?)
              ?.trim()
              .replaceAll(RegExp(r'\s+'), ' ')
          ?? authUser.email?.split('@').first
          ?? 'Creator';

      final newUser = UserModel(
        id: authUser.id,
        name: inferredName,
        email: authUser.email ?? '',
        profilePicUrl: authUser.userMetadata?['avatar_url'] as String? ?? '',
        bio: '',
        skillLevel: 'Beginner',
        hourlyRate: 0,
        location: '',
        currentRole: 'freelancer',
        followers: 0,
        following: 0,
        projectCount: 0,
        specializations: const [],
        isNew: true,
        createdAt: now,
        updatedAt: now,
        socialLinks: const {},
        portfolioLink: '',
        portfolioFile: '',
        followingIds: const [],
      );

      await createUser(newUser);
      return newUser;
    } catch (e) {
      print('Error fetching current user: $e');
      return null;
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      await SupabaseService.insert('users', user.toJson());
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  Future<void> updateCurrentUser(UserModel user) async {
    try {
      await SupabaseService.update(
        'users',
        user.copyWith(updatedAt: DateTime.now()).toJson(),
        filters: {'id': user.id},
      );
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  Future<void> switchRole(String newRole) async {
    final user = await getCurrentUser();
    if (user != null) {
      final updated = user.copyWith(
        currentRole: newRole,
        updatedAt: DateTime.now(),
      );
      await updateCurrentUser(updated);
    }
  }

  Future<UserModel?> getUserById(String id) async {
    try {
      final data = await SupabaseService.selectSingle(
        'users',
        filters: {'id': id},
      );
      return data != null ? UserModel.fromJson(data) : null;
    } catch (e) {
      print('Error fetching user by id: $e');
      return null;
    }
  }

  Future<void> followUser(String userId) async {
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      final updatedFollowingIds = [...currentUser.followingIds, userId];
      await updateCurrentUser(
        currentUser.copyWith(
          followingIds: updatedFollowingIds,
          following: currentUser.following + 1,
        ),
      );

      // Update followed user's followers count
      final followedUser = await getUserById(userId);
      if (followedUser != null) {
        await SupabaseService.update(
          'users',
          {'followers': followedUser.followers + 1, 'updated_at': DateTime.now().toIso8601String()},
          filters: {'id': userId},
        );
      }
    }
  }

  Future<void> unfollowUser(String userId) async {
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      final updatedFollowingIds = currentUser.followingIds.where((id) => id != userId).toList();
      await updateCurrentUser(
        currentUser.copyWith(
          followingIds: updatedFollowingIds,
          following: currentUser.following - 1,
        ),
      );

      // Update unfollowed user's followers count
      final unfollowedUser = await getUserById(userId);
      if (unfollowedUser != null) {
        await SupabaseService.update(
          'users',
          {'followers': unfollowedUser.followers - 1, 'updated_at': DateTime.now().toIso8601String()},
          filters: {'id': userId},
        );
      }
    }
  }
}
