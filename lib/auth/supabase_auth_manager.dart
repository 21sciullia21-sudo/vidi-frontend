import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:vidi/auth/auth_manager.dart';
import 'package:vidi/models/user_model.dart';
import 'package:vidi/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthManager extends AuthManager with EmailSignInManager {
  @override
  Future<UserModel?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Fetch user data from users table
        final userData = await SupabaseService.selectSingle(
          'users',
          filters: {'id': response.user!.id},
        );
        
        if (userData != null) {
          return UserModel.fromJson(userData);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Sign in error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email or password is incorrect.')),
        );
      }
      return null;
    }
  }

  @override
  Future<UserModel?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // User data will be created automatically via database trigger or 
        // needs to be created manually after navigation
        return null; // Return null to defer user data loading
      }
      return null;
    } catch (e) {
      debugPrint('Sign up error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up failed. Please try again.')),
        );
      }
      return null;
    }
  }

  @override
  Future signOut() async {
    await SupabaseConfig.auth.signOut();
  }

  @override
  Future deleteUser(BuildContext context) async {
    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId != null) {
        // Delete user data from users table (cascades to related tables)
        await SupabaseService.delete('users', filters: {'id': userId});
      }
    } catch (e) {
      debugPrint('Delete user error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete account. Please try again.')),
        );
      }
    }
  }

  @override
  Future updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await SupabaseConfig.auth.updateUser(UserAttributes(email: email));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('Update email error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update email. Please try again.')),
        );
      }
    }
  }

  @override
  Future resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await SupabaseConfig.auth.resetPasswordForEmail(email);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    } catch (e) {
      debugPrint('Reset password error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send reset email. Please try again.')),
        );
      }
    }
  }
}
