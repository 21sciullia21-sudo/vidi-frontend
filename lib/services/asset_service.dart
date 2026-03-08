import 'package:vidi/models/asset_model.dart';
import 'package:vidi/models/purchase_model.dart';
import 'package:vidi/supabase/supabase_config.dart';
import 'package:flutter/foundation.dart';

class AssetService {
  Future<List<AssetModel>> getAssets() async {
    try {
      final data = await SupabaseService.select('assets', orderBy: 'created_at', ascending: false);
      return data.map((json) => AssetModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching assets: $e');
      return [];
    }
  }

  Future<AssetModel?> getAssetById(String id) async {
    try {
      final data = await SupabaseService.selectSingle('assets', filters: {'id': id});
      return data != null ? AssetModel.fromJson(data) : null;
    } catch (e) {
      debugPrint('Error fetching asset by id: $e');
      return null;
    }
  }

  Future<void> addAsset(AssetModel asset) async {
    try {
      await SupabaseService.insert('assets', asset.toJson());
    } catch (e) {
      debugPrint('Error adding asset: $e');
    }
  }

  Future<void> updateAsset(AssetModel asset) async {
    try {
      await SupabaseService.update(
        'assets',
        asset.toJson(),
        filters: {'id': asset.id},
      );
    } catch (e) {
      debugPrint('Error updating asset: $e');
    }
  }

  Future<void> deleteAsset(String id) async {
    try {
      await SupabaseService.delete('assets', filters: {'id': id});
    } catch (e) {
      debugPrint('Error deleting asset: $e');
    }
  }

  Future<void> incrementDownloads(String assetId) async {
    try {
      final asset = await getAssetById(assetId);
      if (asset != null) {
        await updateAsset(asset.copyWith(downloads: asset.downloads + 1));
      }
    } catch (e) {
      debugPrint('Error incrementing downloads: $e');
    }
  }

  Future<List<AssetModel>> getAssetsByCategory(String category) async {
    try {
      final data = await SupabaseService.select(
        'assets',
        filters: {'category': category},
        orderBy: 'created_at',
        ascending: false,
      );
      return data.map((json) => AssetModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching assets by category: $e');
      return [];
    }
  }

  Future<List<AssetModel>> getAssetsBySeller(String sellerId) async {
    try {
      final data = await SupabaseService.select(
        'assets',
        filters: {'seller_id': sellerId},
        orderBy: 'created_at',
        ascending: false,
      );
      return data.map((json) => AssetModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching assets by seller: $e');
      return [];
    }
  }

  Future<List<PurchaseModel>> getPurchases() async {
    try {
      final data = await SupabaseService.select('purchases', orderBy: 'purchased_at', ascending: false);
      return data.map((json) => PurchaseModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching purchases: $e');
      return [];
    }
  }

  Future<void> addPurchase(PurchaseModel purchase) async {
    try {
      await SupabaseService.insert('purchases', purchase.toJson());
      
      // Increment asset downloads
      await incrementDownloads(purchase.assetId);
    } catch (e) {
      debugPrint('Error adding purchase: $e');
    }
  }
}
