import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:vidi/models/post_model.dart';
import 'package:vidi/models/comment_model.dart';
import 'package:vidi/supabase/supabase_config.dart';

class PostService {
  Future<List<PostModel>> getPosts() async {
    try {
      final data = await SupabaseService.select('posts', orderBy: 'created_at', ascending: false);
      return data.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  Future<PostModel?> getPostById(String id) async {
    try {
      final data = await SupabaseService.selectSingle('posts', filters: {'id': id});
      if (data == null) return null;
      return PostModel.fromJson(data);
    } catch (e) {
      print('Error fetching post by id: $e');
      return null;
    }
  }

  Future<void> addPost(PostModel post) async {
    try {
      // Build the data map dynamically, only including fields that have values
      final Map<String, dynamic> data = {
        'id': post.id,
        'user_id': post.userId,
        'content': post.content,
        'image_urls': post.imageUrls,
        'video_urls': post.videoUrls,
        'likes': post.likes,
        'comment_count': post.commentCount,
        'created_at': post.createdAt.toIso8601String(),
      };

      // Add optional metadata fields only if they have values
      if (post.isColorGraded != null) {
        data['is_color_graded'] = post.isColorGraded;
      }
      if (post.cameraInfo != null) {
        data['camera_info'] = post.cameraInfo;
      }
      if (post.clipLength != null) {
        data['clip_length'] = post.clipLength;
      }
      if (post.videoFormat != null && post.videoFormat!.isNotEmpty) {
        data['video_format'] = post.videoFormat;
      }
      if (post.imageCameraInfo != null) {
        data['image_camera_info'] = post.imageCameraInfo;
      }
      if (post.imageFormat != null && post.imageFormat!.isNotEmpty) {
        data['image_format'] = post.imageFormat;
      }

      try {
        await SupabaseConfig.client.from('posts').insert(data);
      } catch (e) {
        // If the backend schema is missing image_format (PGRST204), retry without it
        final message = e.toString();
        final mentionsImageFormat = message.contains("image_format");
        final isSchemaCache = message.contains('PGRST204') || message.contains('schema cache');
        if (mentionsImageFormat && isSchemaCache && data.containsKey('image_format')) {
          debugPrint('addPost: image_format not in schema; retrying without it. Error: $e');
          final retryData = Map<String, dynamic>.from(data)..remove('image_format');
          await SupabaseConfig.client.from('posts').insert(retryData);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('Error adding post: $e');
      rethrow;
    }
  }

  Future<void> updatePost(PostModel post) async {
    try {
      await SupabaseService.update(
        'posts',
        post.toJson(),
        filters: {'id': post.id},
      );
    } catch (e) {
      debugPrint('Error updating post: $e');
    }
  }

  Future<void> deletePost(String id) async {
    try {
      await SupabaseService.delete('posts', filters: {'id': id});
    } catch (e) {
      debugPrint('Error deleting post: $e');
    }
  }

  Future<void> toggleLike(String postId, String userId) async {
    try {
      final post = await getPostById(postId);
      if (post != null) {
        List<String> updatedLikes = [...post.likes];
        if (updatedLikes.contains(userId)) {
          updatedLikes.remove(userId);
        } else {
          updatedLikes.add(userId);
        }
        await updatePost(post.copyWith(likes: updatedLikes));
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  Future<List<CommentModel>> getCommentsByPostId(String postId) async {
    try {
      final data = await SupabaseService.select(
        'comments',
        filters: {'post_id': postId},
        orderBy: 'created_at',
        ascending: false,
      );
      return data.map((json) => CommentModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      return [];
    }
  }

  Future<void> addComment(CommentModel comment) async {
    try {
      await SupabaseService.insert('comments', comment.toJson());
      
      // Update post comment count
      final post = await getPostById(comment.postId);
      if (post != null) {
        await updatePost(post.copyWith(commentCount: post.commentCount + 1));
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  Future<List<PostModel>> getPostsByUserId(String userId) async {
    try {
      final data = await SupabaseService.select(
        'posts',
        filters: {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
      );
      return data.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching posts by user: $e');
      return [];
    }
  }

  Future<List<PostModel>> getPostsByFollowing(List<String> followingIds) async {
    if (followingIds.isEmpty) return [];
    
    try {
      dynamic query = SupabaseConfig.client.from('posts')
        .select()
        .inFilter('user_id', followingIds)
        .order('created_at', ascending: false);
      
      final data = await query;
      return data.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching posts by following: $e');
      return [];
    }
  }

  Future<List<CommentModel>> getCommentsForPost(String postId) async {
    return await getCommentsByPostId(postId);
  }
}
