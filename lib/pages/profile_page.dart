import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/widgets/profile_header.dart';
import 'package:vidi/widgets/profile_info.dart';
import 'package:vidi/widgets/post_card.dart';
import 'package:vidi/widgets/asset_card.dart';
import 'package:vidi/pages/profile_edit_page.dart';
import 'package:vidi/pages/settings_page.dart';
import 'package:vidi/pages/asset_detail_page.dart';
import 'package:vidi/pages/signin_page.dart';
import 'package:vidi/services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.forum_outlined),
            onPressed: () => context.read<AppProvider>().toggleMessagesSidebar(),
          ),
          Consumer<AppProvider>(
            builder: (context, provider, _) {
              final user = provider.currentUser;
              if (user == null) return SizedBox.shrink();

              return PopupMenuButton<String>(
                icon: Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProfileEditPage()),
                    );
                  } else if (value == 'settings') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SettingsPage()),
                    );
                  } else if (value == 'switch_role') {
                    _showRoleSwitchDialog(context, provider, user.currentRole);
                  } else if (value == 'sign_out') {
                    _handleSignOut(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Edit Profile'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 20),
                        SizedBox(width: 12),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'switch_role',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, size: 20),
                        SizedBox(width: 12),
                        Text('Switch Role'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'sign_out',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Sign Out', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading || provider.currentUser == null) {
            return Center(child: CircularProgressIndicator());
          }

          final user = provider.currentUser!;
          final userPosts = provider.posts.where((p) => p.userId == user.id).toList();
          final userAssets = provider.assets.where((a) => a.sellerId == user.id).toList();

          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              physics: ClampingScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 800),
                      child: Column(
                        children: [
                          ProfileHeader(user: user),
                          SizedBox(height: 16),
                          ProfileInfo(user: user),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      indicatorColor: Color(0xFF8B5CF6),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
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
                              Icon(Icons.post_add, size: 64, color: Colors.white.withValues(alpha: 0.5)),
                              SizedBox(height: 16),
                              Text(
                                'No posts yet',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: userPosts.length,
                          separatorBuilder: (_, __) => SizedBox(height: 16),
                          itemBuilder: (context, index) => Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 680),
                              child: PostCard(post: userPosts[index]),
                            ),
                          ),
                        ),
                  userAssets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white.withValues(alpha: 0.5)),
                              SizedBox(height: 16),
                              Text(
                                'No products yet',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 800),
                            child: GridView.builder(
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
                                  child: AssetCard(asset: asset, showCreator: false),
                                );
                              },
                            ),
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRoleSwitchDialog(BuildContext context, AppProvider provider, String currentRole) {
    final newRole = currentRole == 'client' ? 'freelancer' : 'client';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Switch Role'),
        content: Text(
          'Switch to ${newRole == 'client' ? 'Client' : 'Freelancer'} mode?\n\n'
          '${newRole == 'client' ? 'You\'ll be able to post jobs and review bids.' : 'You\'ll be able to browse jobs and submit bids.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.switchRole(newRole);
              Navigator.pop(context);
            },
            child: Text('Switch'),
          ),
        ],
      ),
    );
  }

  void _handleSignOut(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final authService = AuthService();
              await authService.logout();
              
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => SignInPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Sign Out'),
          ),
        ],
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
