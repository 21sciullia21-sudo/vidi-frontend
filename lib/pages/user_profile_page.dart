import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/widgets/profile_header.dart';
import 'package:vidi/widgets/profile_info.dart';
import 'package:vidi/widgets/post_card.dart';
import 'package:vidi/widgets/asset_card.dart';
import 'package:vidi/pages/asset_detail_page.dart';

class UserProfilePage extends StatelessWidget {
  final String userId;

  const UserProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final user = provider.getUserById(userId);
          if (user == null) {
            return Center(child: Text('User not found'));
          }

          final userPosts = provider.posts.where((p) => p.userId == userId).toList();
          final userAssets = provider.assets.where((a) => a.sellerId == userId).toList();

          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      ProfileHeader(user: user),
                      SizedBox(height: 16),
                      ProfileInfo(user: user),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      tabs: [
                        Tab(text: 'Posts (${userPosts.length})'),
                        Tab(text: 'Products (${userAssets.length})'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  userPosts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.post_add, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No posts yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(16),
                          itemCount: userPosts.length,
                          separatorBuilder: (_, __) => SizedBox(height: 16),
                          itemBuilder: (context, index) =>
                              PostCard(post: userPosts[index]),
                        ),
                  userAssets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No products yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: userAssets.length,
                          itemBuilder: (context, index) {
                            final asset = userAssets[index];
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
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
