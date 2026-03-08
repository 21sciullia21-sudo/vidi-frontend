import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vidi/models/post_model.dart';
import 'package:vidi/models/comment_model.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/services/post_service.dart';
import 'package:vidi/pages/user_profile_page.dart';
import 'package:vidi/widgets/post_card.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;

  const PostDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final PostService _postService = PostService();
  List<CommentModel> _comments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    final latestComments = await _postService.getCommentsForPost(widget.post.id);
    if (!mounted) return;
    setState(() {
      _comments = latestComments;
      _isLoading = false;
    });
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    final provider = Provider.of<AppProvider>(context, listen: false);
    final currentUser = provider.currentUser;
    if (currentUser == null) return;

    final comment = CommentModel(
      id: const Uuid().v4(),
      postId: widget.post.id,
      userId: currentUser.id,
      content: _commentController.text.trim(),
      createdAt: DateTime.now().toUtc(),
    );

    try {
      await _postService.addComment(comment);
      if (!mounted) return;
      _commentController.clear();
      await _loadComments();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post comment. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final author = provider.getUserById(widget.post.userId);
    final currentUserId = provider.currentUser?.id ?? '';
    final isLiked = widget.post.likes.contains(currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Post'),
        actions: [
          if (currentUserId == widget.post.userId)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete Post'),
                      content: Text('Are you sure you want to delete this post?'),
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
                    await provider.deletePost(widget.post.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Post deleted successfully')),
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (author != null) ...[
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfilePage(userId: author.id),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Color(0xFF8B5CF6),
                              backgroundImage: _getImageProvider(author.profilePicUrl),
                              child: author.profilePicUrl.isEmpty
                                  ? Text(
                                      author.name[0].toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    )
                                  : null,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    author.name,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    _getTimeAgo(widget.post.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (widget.post.content.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        widget.post.content,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  if (widget.post.imageUrls.isNotEmpty) ...[
                    ImageCarousel(imageUrls: widget.post.imageUrls),
                    if (_hasImageMetadata(widget.post))
                      ImageInfoSection(post: widget.post),
                    SizedBox(height: 16),
                  ],
                  if (widget.post.videoUrls.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: VideoPlayerWidget(videoUrl: widget.post.videoUrls[0]),
                    ),
                    if (_hasVideoMetadata(widget.post))
                      VideoInfoSection(post: widget.post),
                    SizedBox(height: 16),
                  ],
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : null,
                          ),
                          onPressed: () => provider.toggleLike(widget.post.id),
                        ),
                        Text('${widget.post.likes.length}'),
                        SizedBox(width: 24),
                        Icon(Icons.chat_bubble, size: 20, color: Color(0xFF8B5CF6)),
                        SizedBox(width: 8),
                        Text('${_comments.length}'),
                      ],
                    ),
                  ),
                  Divider(height: 32),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Comments',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  SizedBox(height: 16),
                  if (_isLoading)
                    Center(child: CircularProgressIndicator())
                  else if (_comments.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No comments yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _comments.length,
                      separatorBuilder: (_, __) => Divider(height: 24),
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final commentAuthor = provider.getUserById(comment.userId);
                        if (commentAuthor == null) return SizedBox.shrink();

                          return InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfilePage(userId: commentAuthor.id),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Color(0xFF8B5CF6),
                                  backgroundImage: _getImageProvider(commentAuthor.profilePicUrl),
                                  child: commentAuthor.profilePicUrl.isEmpty
                                      ? Text(
                                          commentAuthor.name[0].toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            commentAuthor.name,
                                            style: Theme.of(context).textTheme.titleSmall,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            _getTimeAgo(comment.createdAt),
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        comment.content,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                      },
                    ),
                  SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Container(
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
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: Icon(Icons.send, color: Color(0xFF8B5CF6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
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

  bool _hasVideoMetadata(PostModel post) =>
      post.clipLength != null || post.isColorGraded || post.videoFormat != null || post.cameraInfo != null;

  bool _hasImageMetadata(PostModel post) =>
      post.imageFormat != null || post.imageCameraInfo != null;
}
