import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/widgets/asset_card.dart';
import 'package:vidi/widgets/upload_asset_dialog.dart';
import 'package:vidi/pages/asset_detail_page.dart';
import 'package:vidi/pages/checkout_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({Key? key}) : super(key: key);

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  final List<String> _categories = [
    'All',
    '3D Models',
    'Textures',
    'Audio',
    'Graphics',
    'Video',
    'Templates',
    'Plugins',
    'Scripts',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Asset Store'),
        actions: [
          IconButton(
            icon: Icon(Icons.forum_outlined),
            onPressed: () => context.read<AppProvider>().toggleMessagesSidebar(),
          ),
          Consumer<AppProvider>(
            builder: (context, provider, _) => Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart_outlined),
                  onPressed: () {
                    if (provider.cartItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Your cart is empty'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutPage(items: provider.cartItems),
                        ),
                      );
                    }
                  },
                ),
                if (provider.cartItems.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Color(0xFF8B5CF6),
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${provider.cartItems.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          final allAssets = provider.assets;
          
          // Filter assets by search and category
          final filteredAssets = allAssets.where((asset) {
            final matchesSearch = _searchQuery.isEmpty ||
                asset.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                asset.description.toLowerCase().contains(_searchQuery.toLowerCase());
            
            final matchesCategory = _selectedCategory == 'All' ||
                asset.category.toLowerCase() == _selectedCategory.toLowerCase();
            
            return matchesSearch && matchesCategory;
          }).toList();

          return Column(
            children: [
              // Search Bar
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.black,
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search assets...',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.white54),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              
              // Category Filters
              Container(
                height: 60,
                color: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  physics: BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category == _selectedCategory;
                    
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = category);
                        },
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                        labelPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        backgroundColor: Colors.grey[900],
                        selectedColor: Color(0xFF8B5CF6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Color(0xFF8B5CF6) : Colors.grey[800]!,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Asset Grid
              Expanded(
                child: filteredAssets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _selectedCategory != 'All'
                                  ? 'No assets found'
                                  : 'No assets available',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          const double targetTileWidth = 180;
                          final double availableWidth = constraints.maxWidth;

                          int columns = (availableWidth / targetTileWidth).floor();
                          if (columns < 2) columns = 2;
                          if (columns > 6) columns = 6;

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.7,
                            ),
                            itemCount: filteredAssets.length,
                            itemBuilder: (context, index) {
                              final asset = filteredAssets[index];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AssetDetailPage(asset: asset),
                                  ),
                                ),
                                child: AssetCard(asset: asset),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => UploadAssetDialog(),
        ),
        icon: Icon(Icons.upload),
        label: Text('Upload'),
        backgroundColor: Color(0xFF8B5CF6),
      ),
    );
  }
}
