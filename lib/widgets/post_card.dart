import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:vidi/models/post_model.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/pages/post_detail_page.dart';
import 'package:vidi/pages/user_profile_page.dart';

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({Key? key, required this.post}) : super(key: key);

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
    } else if (!kIsWeb && File(imageUrl).existsSync()) {
      return FileImage(File(imageUrl));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final author = provider.getUserById(post.userId);
    final currentUserId = provider.currentUser?.id ?? '';
    final isLiked = post.likes.contains(currentUserId);

    if (author == null) return SizedBox.shrink();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    radius: 20,
                    backgroundColor: Color(0xFF8B5CF6),
                    backgroundImage: _getImageProvider(author.profilePicUrl),
                    child: author.profilePicUrl.isEmpty
                        ? Text(
                            author.name[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
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
                        Text(
                          author.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'in about ${_getTimeAgo(post.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (currentUserId == post.userId)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert),
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
                            await provider.deletePost(post.id);
                            if (context.mounted) {
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
            ),
          ),
          if (post.content.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(height: 12),
          ],
          if (post.imageUrls.isNotEmpty) ...[
            ImageCarousel(imageUrls: post.imageUrls),
            if (_hasImageMetadata(post))
              ImageInfoSection(post: post),
            SizedBox(height: 12),
          ],
          if (post.videoUrls.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: VideoPlayerWidget(videoUrl: post.videoUrls[0]),
              ),
            ),
            if (_hasVideoMetadata(post))
              VideoInfoSection(post: post),
            SizedBox(height: 12),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                  ),
                  onPressed: () => provider.toggleLike(post.id),
                ),
                Text('${post.likes.length}'),
                SizedBox(width: 24),
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline, size: 20),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailPage(post: post),
                    ),
                  ),
                ),
                Text('${post.commentCount}'),
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

    if (diff.inDays > 0) return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'}';
    if (diff.inHours > 0) return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'}';
    if (diff.inMinutes > 0) return '${diff.inMinutes} ${diff.inMinutes == 1 ? 'minute' : 'minutes'}';
    return 'just now';
  }

  bool _hasVideoMetadata(PostModel post) =>
      post.clipLength != null || post.isColorGraded || post.videoFormat != null || post.cameraInfo != null;

  bool _hasImageMetadata(PostModel post) =>
      post.imageFormat != null || post.imageCameraInfo != null;

  String _formatClipLength(int seconds) {
    if (seconds < 60) return '0:${seconds.toString().padLeft(2, '0')}';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildBadge(IconData icon, String label, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  List<Widget> _buildCameraInfo(Map<String, String> cameraInfo) {
    final List<Widget> badges = [];
    cameraInfo.forEach((key, value) {
      if (value.isNotEmpty) {
        badges.add(_buildBadge(
          Icons.camera_alt,
          '$key: $value',
          Color(0xFF6366F1),
        ));
      }
    });
    return badges;
  }
}

class VideoInfoSection extends StatefulWidget {
  final PostModel post;

  const VideoInfoSection({Key? key, required this.post}) : super(key: key);

  @override
  State<VideoInfoSection> createState() => _VideoInfoSectionState();
}

class _VideoInfoSectionState extends State<VideoInfoSection> {
  bool _isExpanded = false;

  String _formatClipLength(int seconds) {
    if (seconds < 60) return '0:${seconds.toString().padLeft(2, '0')}';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF2A2A2A)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Color(0xFF8B5CF6),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Video Info',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(height: 1, color: Color(0xFF2A2A2A)),
            Container(
              padding: EdgeInsets.all(12),
              constraints: BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.post.clipLength != null) ...[
                      _buildInfoRow(
                        Icons.timer,
                        'Duration',
                        _formatClipLength(widget.post.clipLength!),
                        Color(0xFF8B5CF6),
                      ),
                      SizedBox(height: 8),
                    ],
                    if (widget.post.videoFormat != null) ...[
                      _buildInfoRow(
                        Icons.video_settings,
                        'Format',
                        widget.post.videoFormat!,
                        Color(0xFFF59E0B),
                      ),
                      SizedBox(height: 8),
                    ],
                    if (widget.post.isColorGraded) ...[
                      _buildInfoRow(
                        Icons.palette,
                        'Color Grading',
                        'Enabled',
                        Color(0xFF10B981),
                      ),
                      SizedBox(height: 8),
                    ],
                    if (widget.post.cameraInfo != null && widget.post.cameraInfo!.isNotEmpty) ...[
                      Divider(height: 16, color: Color(0xFF2A2A2A)),
                      Text(
                        'Camera Info',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...widget.post.cameraInfo!.entries.map((entry) {
                        if (entry.value.isEmpty) return SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: _buildInfoRow(
                            Icons.camera_alt,
                            entry.key,
                            entry.value,
                            Color(0xFF6366F1),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ImageInfoSection extends StatefulWidget {
  final PostModel post;

  const ImageInfoSection({Key? key, required this.post}) : super(key: key);

  @override
  State<ImageInfoSection> createState() => _ImageInfoSectionState();
}

class _ImageInfoSectionState extends State<ImageInfoSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 18,
                    color: Color(0xFF8B5CF6),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Image Info',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(height: 1, color: Color(0xFF2A2A2A)),
            Container(
              padding: EdgeInsets.all(12),
              constraints: BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.post.imageFormat != null) ...[
                      _buildInfoRow(
                        Icons.photo,
                        'Format',
                        widget.post.imageFormat!,
                        Color(0xFFF59E0B),
                      ),
                      SizedBox(height: 8),
                    ],
                    if (widget.post.imageCameraInfo != null && widget.post.imageCameraInfo!.isNotEmpty) ...[
                      Divider(height: 16, color: Color(0xFF2A2A2A)),
                      Text(
                        'Camera Info',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...widget.post.imageCameraInfo!.entries.map((entry) {
                        if (entry.value.isEmpty) return SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: _buildInfoRow(
                            Icons.camera_alt,
                            entry.key,
                            entry.value,
                            Color(0xFF6366F1),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.videoUrl.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      } else if (!kIsWeb) {
        _controller = VideoPlayerController.file(File(widget.videoUrl));
      } else {
        setState(() => _hasError = true);
        return;
      }

      await _controller.initialize();
      _controller.setLooping(false);
      _controller.setVolume(1.0);
      _controller.addListener(() {
        if (mounted) setState(() {});
      });
      // Pause on first frame so texture is visible
      await _controller.seekTo(Duration.zero);
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _toggleFullScreen() async {
    final wasPlaying = _controller.value.isPlaying;
    final currentPosition = _controller.value.position;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenVideoPlayer(controller: _controller),
      ),
    );
    
    // Force video player to refresh with new key
    if (_controller.value.isInitialized) {
      await _controller.seekTo(currentPosition);
      if (wasPlaying) {
        await _controller.play();
      }
      setState(() {
        _refreshKey++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 300,
        color: Colors.grey[800],
        child: Icon(Icons.videocam_off, size: 48, color: Colors.grey[600]),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: 300,
        color: Colors.grey[800],
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
            _showControls = true;
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              color: Colors.black,
              child: VideoPlayer(
                _controller,
                key: ValueKey(_refreshKey),
              ),
            ),
            if (!_controller.value.isPlaying)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 50),
              ),
            if (_showControls && _controller.value.isPlaying)
              Container(color: Colors.black.withValues(alpha: 0.3)),
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoControls(
                  controller: _controller,
                  onFullScreen: _toggleFullScreen,
                  onSeek: () {
                    setState(() {
                      _refreshKey++;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class VideoControls extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onFullScreen;
  final VoidCallback onSeek;

  const VideoControls({
    Key? key,
    required this.controller,
    required this.onFullScreen,
    required this.onSeek,
  }) : super(key: key);

  @override
  State<VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<VideoControls> {
  bool _showVolumeSlider = false;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.controller.value.position;
    final duration = widget.controller.value.duration;
    final volume = widget.controller.value.volume;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                    max: duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      widget.controller.seekTo(Duration(milliseconds: value.toInt()));
                    },
                    activeColor: Color(0xFF8B5CF6),
                    inactiveColor: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
              Text(
                _formatDuration(duration),
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    widget.controller.value.isPlaying ? widget.controller.pause() : widget.controller.play();
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.replay_10, color: Colors.white),
                onPressed: () {
                  final currentPosition = widget.controller.value.position;
                  final newPosition = currentPosition - Duration(seconds: 15);
                  widget.controller.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
                  widget.onSeek();
                },
              ),
              IconButton(
                icon: Icon(Icons.forward_10, color: Colors.white),
                onPressed: () {
                  final currentPosition = widget.controller.value.position;
                  final duration = widget.controller.value.duration;
                  final newPosition = currentPosition + Duration(seconds: 15);
                  widget.controller.seekTo(newPosition > duration ? duration : newPosition);
                  widget.onSeek();
                },
              ),
              IconButton(
                icon: Icon(
                  volume > 0.5 ? Icons.volume_up : (volume > 0 ? Icons.volume_down : Icons.volume_off),
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _showVolumeSlider = !_showVolumeSlider),
              ),
              if (_showVolumeSlider)
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: volume,
                      onChanged: (value) {
                        setState(() => widget.controller.setVolume(value));
                      },
                      activeColor: Colors.white,
                      inactiveColor: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.fullscreen, color: Colors.white),
                onPressed: widget.onFullScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const FullScreenVideoPlayer({Key? key, required this.controller}) : super(key: key);

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  bool _showControls = true;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            if (widget.controller.value.isPlaying) {
              widget.controller.pause();
            } else {
              widget.controller.play();
            }
            _showControls = true;
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(
                  widget.controller,
                  key: ValueKey(_refreshKey),
                ),
              ),
            ),
            if (_showControls) ...[
              Container(color: Colors.black.withValues(alpha: 0.3)),
              if (!widget.controller.value.isPlaying)
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 60),
                ),
              Positioned(
                top: 40,
                left: 8,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: FullScreenControls(
                  controller: widget.controller,
                  onSeek: () {
                    setState(() {
                      _refreshKey++;
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FullScreenControls extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback? onSeek;

  const FullScreenControls({Key? key, required this.controller, this.onSeek}) : super(key: key);

  @override
  State<FullScreenControls> createState() => _FullScreenControlsState();
}

class _FullScreenControlsState extends State<FullScreenControls> {
  bool _showVolumeSlider = false;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.controller.value.position;
    final duration = widget.controller.value.duration;
    final volume = widget.controller.value.volume;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                    max: duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      widget.controller.seekTo(Duration(milliseconds: value.toInt()));
                    },
                    activeColor: Color(0xFF8B5CF6),
                    inactiveColor: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
              Text(
                _formatDuration(duration),
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    widget.controller.value.isPlaying ? widget.controller.pause() : widget.controller.play();
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.replay_10, color: Colors.white, size: 28),
                onPressed: () {
                  final currentPosition = widget.controller.value.position;
                  final newPosition = currentPosition - Duration(seconds: 15);
                  widget.controller.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
                  widget.onSeek?.call();
                },
              ),
              IconButton(
                icon: Icon(Icons.forward_10, color: Colors.white, size: 28),
                onPressed: () {
                  final currentPosition = widget.controller.value.position;
                  final duration = widget.controller.value.duration;
                  final newPosition = currentPosition + Duration(seconds: 15);
                  widget.controller.seekTo(newPosition > duration ? duration : newPosition);
                  widget.onSeek?.call();
                },
              ),
              IconButton(
                icon: Icon(
                  volume > 0.5 ? Icons.volume_up : (volume > 0 ? Icons.volume_down : Icons.volume_off),
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => setState(() => _showVolumeSlider = !_showVolumeSlider),
              ),
              if (_showVolumeSlider)
                Expanded(
                  flex: 2,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: volume,
                      onChanged: (value) {
                        setState(() => widget.controller.setVolume(value));
                      },
                      activeColor: Colors.white,
                      inactiveColor: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const ImageCarousel({Key? key, required this.imageUrls}) : super(key: key);

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    } else if (!kIsWeb && File(imageUrl).existsSync()) {
      return FileImage(File(imageUrl));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: widget.imageUrls.length,
                    itemBuilder: (context, index) {
                      final imageUrl = widget.imageUrls[index];
                      final imageProvider = _getImageProvider(imageUrl);
                      
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(imageUrl: imageUrl),
                          ),
                        ),
                        child: imageProvider != null
                            ? Image(
                                image: imageProvider,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[800],
                                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey[600]),
                                ),
                              )
                            : Container(
                                color: Colors.grey[800],
                                child: Icon(Icons.broken_image, size: 48, color: Colors.grey[600]),
                              ),
                      );
                    },
                  ),
                ),
              ),
              if (widget.imageUrls.length > 1) ...[
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _currentPage > 0
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          )
                        : SizedBox(),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _currentPage < widget.imageUrls.length - 1
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          )
                        : SizedBox(),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentPage + 1}/${widget.imageUrls.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;

  const FullScreenImageViewer({Key? key, required this.imageUrl}) : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  final TransformationController _transformationController = TransformationController();
  bool _showControls = true;

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
    } else if (!kIsWeb && File(imageUrl).existsSync()) {
      return FileImage(File(imageUrl));
    }
    return null;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _getImageProvider(widget.imageUrl);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: imageProvider != null
                    ? Image(
                        image: imageProvider,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.broken_image,
                          size: 100,
                          color: Colors.grey[600],
                        ),
                      )
                    : Icon(
                        Icons.broken_image,
                        size: 100,
                        color: Colors.grey[600],
                      ),
              ),
            ),
            if (_showControls) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.3],
                  ),
                ),
                height: 100,
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white, size: 28),
                  onPressed: () {
                    _transformationController.value = Matrix4.identity();
                  },
                  tooltip: 'Reset zoom',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
