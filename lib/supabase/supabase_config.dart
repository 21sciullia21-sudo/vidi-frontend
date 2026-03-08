import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Generic Supabase configuration template
/// Replace YOUR_ and YOUR_ with your actual values
class SupabaseConfig {
  static const String supabaseUrl = 'https://inileqvxalpbgidsienl.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImluaWxlcXZ4YWxwYmdpZHNpZW5sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3NzgwOTQsImV4cCI6MjA3NzM1NDA5NH0.w8lPsllz0F-X63DJTIiRnvxGfDnF9TajKNb28Hz6HMY';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: anonKey,
      debug: kDebugMode,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
}

/// Generic database service for CRUD operations
class SupabaseService {
  /// Select multiple records from a table
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      dynamic query = SupabaseConfig.client.from(table).select(select ?? '*');

      // Apply filters
      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      return await query;
    } catch (e) {
      throw _handleDatabaseError('select', table, e);
    }
  }

  /// Select a single record from a table
  static Future<Map<String, dynamic>?> selectSingle(
    String table, {
    String? select,
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = SupabaseConfig.client.from(table).select(select ?? '*');

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      return await query.maybeSingle();
    } catch (e) {
      throw _handleDatabaseError('selectSingle', table, e);
    }
  }

  /// Insert a record into a table
  static Future<List<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseConfig.client.from(table).insert(data).select();
    } catch (e) {
      throw _handleDatabaseError('insert', table, e);
    }
  }

  /// Insert multiple records into a table
  static Future<List<Map<String, dynamic>>> insertMultiple(
    String table,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      return await SupabaseConfig.client.from(table).insert(data).select();
    } catch (e) {
      throw _handleDatabaseError('insertMultiple', table, e);
    }
  }

  /// Update records in a table
  static Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = SupabaseConfig.client.from(table).update(data);

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      return await query.select();
    } catch (e) {
      throw _handleDatabaseError('update', table, e);
    }
  }

  /// Delete records from a table
  static Future<void> delete(
    String table, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = SupabaseConfig.client.from(table).delete();

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      await query;
    } catch (e) {
      throw _handleDatabaseError('delete', table, e);
    }
  }

  /// Get direct table reference for complex queries
  static SupabaseQueryBuilder from(String table) =>
      SupabaseConfig.client.from(table);

  /// Handle database errors
  static Exception _handleDatabaseError(
    String operation,
    String table,
    dynamic error,
  ) {
    if (error is PostgrestException) {
      return Exception('Failed to $operation from $table: ${error.message}');
    } else {
      return Exception('Failed to $operation from $table: ${error.toString()}');
    }
  }
}

/// Supabase Storage service
class SupabaseStorageService {
  /// Upload a file to Supabase Storage and return public URL
  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> bytes,
    String? contentType,
  }) async {
    try {
      final uint8List = Uint8List.fromList(bytes);
      await SupabaseConfig.client.storage.from(bucket).uploadBinary(
        path,
        uint8List,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );
      
      return SupabaseConfig.client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }
  
  /// Delete a file from Supabase Storage
  static Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await SupabaseConfig.client.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Resolve a storage reference (e.g. `images/<user>/<file>.jpg`) into a
  /// URL that can be rendered in the app. Falls back gracefully if the
  /// reference is already a public URL or if signing fails.
  static Future<String?> resolveUrl(
    String reference, {
    int expiresInSeconds = 60 * 60 * 24,
  }) async {
    if (reference.isEmpty) return null;

    // Already a fully qualified URL or base64 data URI
    if (reference.startsWith('http') || reference.startsWith('data:')) {
      return reference;
    }

    final normalized = reference.startsWith('/')
        ? reference.substring(1)
        : reference;

    final parts = normalized.split('/');
    if (parts.length < 2) {
      return reference;
    }

    final bucket = parts.first;
    final path = parts.skip(1).join('/');

    try {
      final signedUrl = await SupabaseConfig.client.storage
          .from(bucket)
          .createSignedUrl(path, expiresInSeconds);
      
      if (signedUrl.isNotEmpty) {
        return signedUrl;
      }
    } catch (_) {
      // Signing can fail when the bucket is public. Fall back to a raw public URL.
      try {
        return SupabaseConfig.client.storage.from(bucket).getPublicUrl(path);
      } catch (_) {
        return null;
      }
    }

    return null;
  }
}
