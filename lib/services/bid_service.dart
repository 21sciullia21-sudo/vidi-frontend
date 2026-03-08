import 'package:vidi/models/bid_model.dart';
import 'package:vidi/supabase/supabase_config.dart';

class BidService {
  Future<List<BidModel>> getBidsByJobId(String jobId) async {
    try {
      final data = await SupabaseService.select(
        'bids',
        filters: {'job_id': jobId},
        orderBy: 'submitted_at',
        ascending: false,
      );
      return data.map((json) => BidModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching bids: $e');
      return [];
    }
  }

  Future<void> addBid(BidModel bid) async {
    try {
      await SupabaseService.insert('bids', bid.toJson());
    } catch (e) {
      print('Error adding bid: $e');
    }
  }

  Future<void> updateBid(BidModel bid) async {
    try {
      await SupabaseService.update(
        'bids',
        bid.toJson(),
        filters: {'id': bid.id},
      );
    } catch (e) {
      print('Error updating bid: $e');
    }
  }

  Future<List<BidModel>> getBidsByEditor(String editorId) async {
    try {
      final data = await SupabaseService.select(
        'bids',
        filters: {'editor_id': editorId},
        orderBy: 'submitted_at',
        ascending: false,
      );
      return data.map((json) => BidModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching editor bids: $e');
      return [];
    }
  }

  Future<bool> hasUserBidOnJob(String jobId, String userId) async {
    try {
      dynamic query = SupabaseConfig.client.from('bids')
        .select()
        .eq('editor_id', userId)
        .eq('job_id', jobId);
      
      final data = await query;
      return data.isNotEmpty;
    } catch (e) {
      print('Error checking user bid: $e');
      return false;
    }
  }

  Future<List<BidModel>> getBidsForJob(String jobId) async {
    return await getBidsByJobId(jobId);
  }

  Future<List<BidModel>> getAllBids() async {
    try {
      final data = await SupabaseService.select('bids', orderBy: 'submitted_at', ascending: false);
      return data.map((json) => BidModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching all bids: $e');
      return [];
    }
  }

  Future<void> acceptBid(String bidId) async {
    try {
      await SupabaseService.update(
        'bids',
        {
          'status': 'accepted',
          'accepted_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': bidId},
      );
    } catch (e) {
      print('Error accepting bid: $e');
    }
  }

  Future<BidModel?> getUserBidForJob(String jobId, String userId) async {
    try {
      final data = await SupabaseConfig.client.from('bids')
        .select()
        .eq('editor_id', userId)
        .eq('job_id', jobId)
        .limit(1);
      
      if (data.isEmpty) return null;
      return BidModel.fromJson(data.first);
    } catch (e) {
      print('Error fetching user bid: $e');
      return null;
    }
  }
}
