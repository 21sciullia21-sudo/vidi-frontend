import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidi/models/asset_model.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/pages/user_profile_page.dart';
import 'package:vidi/pages/checkout_page.dart';

class AssetDetailPage extends StatelessWidget {
  final AssetModel asset;

  const AssetDetailPage({Key? key, required this.asset}) : super(key: key);

  void _showCartDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Shopping Cart'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${provider.cartItems.length} items in cart'),
            SizedBox(height: 8),
            Text(
              'Total: \$${provider.cartTotal.toInt()}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continue Shopping'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CheckoutPage(items: provider.cartItems),
                ),
              );
            },
            child: Text('Checkout'),
          ),
        ],
      ),
    );
  }

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
    final seller = provider.getUserById(asset.sellerId);
    final currentUserId = provider.currentUser?.id ?? '';
    final isOwner = currentUserId == asset.sellerId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete Product'),
                      content: Text('Are you sure you want to delete this product?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await provider.deleteAsset(asset.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Product deleted successfully')),
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _getImageProvider(asset.imageUrl) != null
                    ? Image(
                        image: _getImageProvider(asset.imageUrl)!,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 300,
                          color: Colors.grey[800],
                          child: Icon(Icons.image, size: 64, color: Colors.grey[600]),
                        ),
                      )
                    : Container(
                        height: 300,
                        color: Colors.grey[800],
                        child: Icon(Icons.image, size: 64, color: Colors.grey[600]),
                      ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '\$${asset.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      SizedBox(height: 16),
                      if (seller != null) ...[
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfilePage(userId: seller.id),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Color(0xFF8B5CF6),
                                backgroundImage: _getImageProvider(seller.profilePicUrl),
                                child: seller.profilePicUrl.isEmpty
                                    ? Text(
                                        seller.name[0].toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Created by',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    seller.name,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                      Row(
                        children: [
                          Icon(Icons.category_outlined, size: 20, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            asset.category,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(width: 24),
                          Icon(Icons.download_outlined, size: 20, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            '${asset.downloads} downloads',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      Text(
                        asset.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(color: Color(0xFF2A2A2A)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  provider.addToCart(asset);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added to cart'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'View Cart',
                        onPressed: () => _showCartDialog(context, provider),
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Color(0xFF8B5CF6)),
                ),
                child: Text('Add to Cart'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutPage(items: [asset]),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B5CF6),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Buy Now \$${asset.price.toInt()}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
