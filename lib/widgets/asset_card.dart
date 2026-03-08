import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidi/models/asset_model.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/pages/user_profile_page.dart';

class AssetCard extends StatelessWidget {
  final AssetModel asset;
  final bool showCreator;

  const AssetCard({Key? key, required this.asset, this.showCreator = true}) : super(key: key);

  ImageProvider? _getImageProvider(String imageUrl) {
    if (imageUrl.isEmpty) return null;
    
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        return null;
      }
    } else if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final creator = provider.getUserById(asset.sellerId);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: _getImageProvider(asset.imageUrl) != null
                  ? Image(
                      image: _getImageProvider(asset.imageUrl)!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: Icon(Icons.image, size: 48, color: Colors.grey[600]),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: Icon(Icons.image, size: 48, color: Colors.grey[600]),
                    ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                Text(
                  '\$${asset.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                if (showCreator && creator != null) ...[
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfilePage(userId: creator.id),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Color(0xFF8B5CF6),
                          backgroundImage: _getImageProvider(creator.profilePicUrl),
                          child: creator.profilePicUrl.isEmpty
                              ? Text(
                                  creator.name[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            creator.name,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 6),
                ],
                Row(
                  children: [
                    Icon(Icons.download, size: 12, color: Colors.white54),
                    SizedBox(width: 4),
                    Text(
                      '${asset.downloads} downloads',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
