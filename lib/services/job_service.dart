import 'package:flutter/foundation.dart';
import 'package:vidi/models/job_model.dart';
import 'package:vidi/supabase/supabase_config.dart';

class JobService {
  Future<List<JobModel>> getJobs() async {
    try {
      final data = await SupabaseService.select('jobs', orderBy: 'posted_at', ascending: false);
      return data.map((json) => JobModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('getJobs: posted_at ordering failed: $e');
      // Fallback if posted_at column doesn't exist
      try {
        final data = await SupabaseService.select('jobs', orderBy: 'created_at', ascending: false);
        return data.map((json) => JobModel.fromJson(json)).toList();
      } catch (e2) {
        debugPrint('getJobs: created_at ordering failed: $e2');
        try {
          final data = await SupabaseService.select('jobs');
          return data.map((json) => JobModel.fromJson(json)).toList();
        } catch (e3) {
          debugPrint('getJobs: final select failed: $e3');
          return [];
        }
      }
    }
  }

  Future<JobModel?> getJobById(String id) async {
    try {
      final data = await SupabaseService.selectSingle('jobs', filters: {'id': id});
      return data != null ? JobModel.fromJson(data) : null;
    } catch (e) {
      debugPrint('Error fetching job by id: $e');
      return null;
    }
  }

  Future<void> addJob(JobModel job) async {
    try {
      // Remove null fields (e.g., assigned_editor_id) to avoid schema cache errors
      final data = Map<String, dynamic>.from(job.toJson())
        ..removeWhere((key, value) => value == null);
      await SupabaseService.insert('jobs', data);
    } catch (e) {
      debugPrint('Error adding job: $e');
    }
  }

  Future<void> updateJob(JobModel job) async {
    try {
      // Remove null fields to avoid sending unknown/nullable columns
      final data = Map<String, dynamic>.from(job.toJson())
        ..removeWhere((key, value) => value == null);
      await SupabaseService.update('jobs', data, filters: {'id': job.id});
    } catch (e) {
      debugPrint('Error updating job: $e');
    }
  }

  Future<void> incrementBidCount(String jobId) async {
    try {
      final job = await getJobById(jobId);
      if (job != null) {
        await updateJob(job.copyWith(bidCount: job.bidCount + 1));
      }
    } catch (e) {
      debugPrint('Error incrementing bid count: $e');
    }
  }

  Future<List<JobModel>> getJobsByCategory(String category) async {
    try {
      try {
        final data = await SupabaseService.select(
          'jobs',
          filters: {'category': category},
          orderBy: 'posted_at',
          ascending: false,
        );
        return data.map((json) => JobModel.fromJson(json)).toList();
      } catch (e) {
        debugPrint('getJobsByCategory: posted_at ordering failed: $e');
        try {
          final data = await SupabaseService.select(
            'jobs',
            filters: {'category': category},
            orderBy: 'created_at',
            ascending: false,
          );
          return data.map((json) => JobModel.fromJson(json)).toList();
        } catch (e2) {
          debugPrint('getJobsByCategory: created_at ordering failed: $e2');
          final data = await SupabaseService.select('jobs', filters: {'category': category});
          return data.map((json) => JobModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching jobs by category: $e');
      return [];
    }
  }

  Future<List<JobModel>> getJobsByClientId(String clientId) async {
    try {
      try {
        final data = await SupabaseService.select(
          'jobs',
          filters: {'client_id': clientId},
          orderBy: 'posted_at',
          ascending: false,
        );
        return data.map((json) => JobModel.fromJson(json)).toList();
      } catch (e) {
        debugPrint('getJobsByClientId: posted_at ordering failed: $e');
        try {
          final data = await SupabaseService.select(
            'jobs',
            filters: {'client_id': clientId},
            orderBy: 'created_at',
            ascending: false,
          );
          return data.map((json) => JobModel.fromJson(json)).toList();
        } catch (e2) {
          debugPrint('getJobsByClientId: created_at ordering failed: $e2');
          final data = await SupabaseService.select('jobs', filters: {'client_id': clientId});
          return data.map((json) => JobModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching jobs by client: $e');
      return [];
    }
  }

  Future<List<JobModel>> searchJobs(String query) async {
    if (query.isEmpty) return await getJobs();
    
    try {
      dynamic queryBuilder = SupabaseConfig.client.from('jobs')
        .select()
        .or('title.ilike.%$query%,description.ilike.%$query%')
        .order('posted_at', ascending: false);
      
      final data = await queryBuilder;
      return data.map<JobModel>((json) => JobModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('searchJobs: posted_at ordering failed or other error: $e');
      try {
        dynamic queryBuilder = SupabaseConfig.client.from('jobs')
          .select()
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);
        final data = await queryBuilder;
        return data.map<JobModel>((json) => JobModel.fromJson(json)).toList();
      } catch (e2) {
        debugPrint('searchJobs: created_at ordering failed: $e2');
        try {
          dynamic queryBuilder = SupabaseConfig.client.from('jobs')
            .select()
            .or('title.ilike.%$query%,description.ilike.%$query%');
          final data = await queryBuilder;
          return data.map<JobModel>((json) => JobModel.fromJson(json)).toList();
        } catch (e3) {
          debugPrint('searchJobs: final select failed: $e3');
          return [];
        }
      }
    }
  }

  Future<List<JobModel>> filterByCategory(String category) async {
    if (category.isEmpty || category == 'All') return await getJobs();
    return await getJobsByCategory(category);
  }

  Future<void> assignEditor(String jobId, String editorId) async {
    try {
      await SupabaseService.update(
        'jobs',
        {
          'assigned_editor_id': editorId,
          'status': 'in_progress',
        },
        filters: {'id': jobId},
      );
    } catch (e) {
      debugPrint('Error assigning editor: $e');
    }
  }
}
