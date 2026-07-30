import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Register a new user in the custom `users` table.
  Future<bool> registerUser(String username, String password) async {
    try {
      final response = await _supabase.from('users').insert({
        'username': username,
        'password': password, // Note: In a production app, use hashing!
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      return response.isNotEmpty;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  /// Login a user by checking the custom `users` table.
  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  /// Update username in the custom `users` table.
  Future<bool> updateUsername(String oldUsername, String newUsername) async {
    try {
      final response = await _supabase
          .from('users')
          .update({'username': newUsername})
          .eq('username', oldUsername)
          .select();

      return response.isNotEmpty;
    } catch (e) {
      print('Update username error: $e');
      return false;
    }
  }

  /// Update password in the custom `users` table.
  Future<bool> updatePassword(String username, String newPassword) async {
    try {
      final response = await _supabase
          .from('users')
          .update({'password': newPassword})
          .eq('username', username)
          .select();

      return response.isNotEmpty;
    } catch (e) {
      print('Update password error: $e');
      return false;
    }
  }

  /// Delete a user from the custom `users` table.
  Future<bool> deleteUser(String username) async {
    try {
      await _supabase.from('users').delete().eq('username', username);
      return true;
    } catch (e) {
      print('Delete user error: $e');
      return false;
    }
  }
}

