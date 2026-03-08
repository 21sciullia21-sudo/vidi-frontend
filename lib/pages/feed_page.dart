import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/widgets/post_card.dart';
import 'package:vidi/widgets/create_post_dialog.dart';
import 'package:vidi/models/post_model.dart';
import 'package:vidi/models/user_model.dart';
import 'package:vidi/services/user_service.dart';
import 'package:vidi/pages/user_profile_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with SingleTickerProviderStateMixin {
  static const double _contentMaxWidth = 680.0;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();
  String _searchQuery = '';
  String _userSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vidi'),
        actions: [
          IconButton(
            icon: Icon(Icons.forum_outlined),
            onPressed: () => context.read<AppProvider>().toggleMessagesSidebar(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Feed'),
            Tab(text: 'People'),
            Tab(text: 'Explore'),
          ],
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildFeedTab(provider),
              _buildFollowingTab(provider),
              _buildExploreTab(provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePost(context),
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF8B5CF6),
      ),
    );
  }

  Widget _buildFeedTab(AppProvider provider) {
    final posts = _getPopularPosts(provider.posts);
    
    if (posts.isEmpty) {
      return _buildEmptyState('No posts yet', 'Be the first to share something!');
    }

    return _buildCenteredPostList(posts);
  }

  Widget _buildFollowingTab(AppProvider provider) {
    final currentUser = provider.currentUser;
    if (currentUser == null) {
      return _buildEmptyState('Not logged in', 'Please log in to see posts from people you follow');
    }

    // Filter users based on search query
    final filteredUsers = _userSearchQuery.isEmpty
        ? <UserModel>[]
        : provider.users.where((user) {
            if (user.id == currentUser.id) return false; // Don't show current user
            return user.name.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
                   user.email.toLowerCase().contains(_userSearchQuery.toLowerCase());
          }).toList();

    return Column(
      children: [
        // User search bar
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _contentMaxWidth),
              child: TextField(
                controller: _userSearchController,
                decoration: InputDecoration(
                  hintText: 'Search for users to follow...',
                  prefixIcon: Icon(Icons.person_search),
                  suffixIcon: _userSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _userSearchController.clear();
                              _userSearchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _userSearchQuery = value),
              ),
            ),
          ),
        ),
        
        // Show user search results or following posts
        Expanded(
          child: _userSearchQuery.isNotEmpty
              ? _buildUserSearchResults(filteredUsers, currentUser, provider)
              : _buildFollowingPosts(provider, currentUser),
        ),
      ],
    );
  }

  Widget _buildUserSearchResults(List<UserModel> users, UserModel currentUser, AppProvider provider) {
    if (users.isEmpty) {
      return _buildEmptyState('No users found', 'Try different search keywords');
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isFollowing = currentUser.followingIds.contains(user.id);
        
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _contentMaxWidth),
            child: Card(
              margin: EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.profilePicUrl.isNotEmpty
                      ? (user.profilePicUrl.startsWith('data:')
                          ? MemoryImage(
                              Uri.parse(user.profilePicUrl).data!.contentAsBytes())
                          : NetworkImage(user.profilePicUrl))
                      : null,
                  child: user.profilePicUrl.isEmpty
                      ? Icon(Icons.person, color: Colors.white)
                      : null,
                  backgroundColor: Color(0xFF8B5CF6),
                ),
                title: Text(user.name, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${user.followers} followers'),
                trailing: ElevatedButton(
                  onPressed: () => _toggleFollow(user.id, isFollowing, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.grey[800] : Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(userId: user.id),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowingPosts(AppProvider provider, UserModel currentUser) {
    final followingPosts = provider.posts.where((post) {
      return currentUser.followingIds.contains(post.userId);
    }).toList();

    followingPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (followingPosts.isEmpty) {
      return _buildEmptyState(
        'No posts from followed users',
        'Search for users above to follow them!',
      );
    }

    return _buildCenteredPostList(
      followingPosts,
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
    );
  }

  Future<void> _toggleFollow(String userId, bool isCurrentlyFollowing, AppProvider provider) async {
    try {
      final userService = UserService();
      if (isCurrentlyFollowing) {
        await userService.unfollowUser(userId);
      } else {
        await userService.followUser(userId);
      }
      // Refresh provider to update current user
      await provider.initialize();
    } catch (e) {
      debugPrint('Follow/unfollow error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }

  Widget _buildExploreTab(AppProvider provider) {
    final filteredPosts = _searchQuery.isEmpty
        ? provider.posts
        : provider.posts.where((post) {
            return post.content.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    filteredPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _contentMaxWidth),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search posts by keywords...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
        ),
        Expanded(
          child: filteredPosts.isEmpty
              ? _buildEmptyState(
                  _searchQuery.isEmpty ? 'No posts yet' : 'No posts found',
                  _searchQuery.isEmpty 
                      ? 'Check back later for new content!' 
                      : 'Try different keywords',
                )
              : _buildCenteredPostList(
                  filteredPosts,
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                ),
        ),
      ],
    );
  }

  List<PostModel> _getPopularPosts(List<PostModel> posts) {
    final sortedPosts = List<PostModel>.from(posts);
    sortedPosts.sort((a, b) {
      final aScore = a.likes.length * 2 + a.commentCount;
      final bScore = b.likes.length * 2 + b.commentCount;
      return bScore.compareTo(aScore);
    });
    return sortedPosts;
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  void _showCreatePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePostDialog(),
    );
  }

  Widget _buildCenteredPostList(
    List<PostModel> posts, {
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(16, 24, 16, 24),
  }) {
    return ListView.separated(
      padding: padding,
      itemCount: posts.length,
      separatorBuilder: (_, __) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _contentMaxWidth),
            child: PostCard(post: posts[index]),
          ),
        );
      },
    );
  }
}
