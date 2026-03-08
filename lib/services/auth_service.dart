import 'package:vidi/models/user_model.dart';
import 'package:vidi/supabase/supabase_config.dart';
import 'package:vidi/services/user_service.dart';

class AuthService {
  final UserService _userService = UserService();

  Future<bool> isLoggedIn() async {
    return SupabaseConfig.auth.currentUser != null;
  }

  Future<UserModel?> getCurrentUser() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user != null) {
      return await _userService.getUserById(user.id);
    }
    return null;
  }

  Future<UserModel?> signUp(String email, String name, String password) async {
    try {
      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Create user profile in users table
        final newUser = UserModel(
          id: response.user!.id,
          name: name,
          email: email,
          profilePicUrl: '',
          bio: '',
          skillLevel: 'Beginner',
          hourlyRate: 0,
          location: '',
          currentRole: 'freelancer',
          followers: 0,
          following: 0,
          projectCount: 0,
          specializations: [],
          isNew: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          socialLinks: {},
          portfolioLink: '',
          portfolioFile: '',
          followingIds: [],
        );

        await _userService.createUser(newUser);
        return null; // Defer loading until after navigation
      }
      return null;
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await SupabaseConfig.auth.signOut();
  }
}
