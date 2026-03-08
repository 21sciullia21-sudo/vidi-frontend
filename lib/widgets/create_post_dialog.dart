import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:vidi/models/post_model.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/supabase/supabase_config.dart';

class CreatePostDialog extends StatefulWidget {
  const CreatePostDialog({Key? key}) : super(key: key);

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final _contentController = TextEditingController();
  final _cameraController = TextEditingController();
  final _lensController = TextEditingController();
  final _isoController = TextEditingController();
  final _fpsController = TextEditingController();
  final _clipLengthController = TextEditingController();
  final _imageCameraController = TextEditingController();
  final _imageLensController = TextEditingController();
  final _imageIsoController = TextEditingController();
  bool _isPosting = false;
  bool _isDetecting = false;
  List<PlatformFile> _selectedFiles = [];
  bool _isColorGraded = false;
  String? _videoFormat;
  String? _imageFormat;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_handleContentChanged);
  }

  @override
  void dispose() {
    _contentController.removeListener(_handleContentChanged);
    _contentController.dispose();
    _cameraController.dispose();
    _lensController.dispose();
    _isoController.dispose();
    _fpsController.dispose();
    _clipLengthController.dispose();
    _imageCameraController.dispose();
    _imageLensController.dispose();
    _imageIsoController.dispose();
    super.dispose();
  }

  bool get _hasContent => _contentController.text.trim().isNotEmpty;
  bool get _hasMedia => _selectedFiles.isNotEmpty;
  bool get _canSubmit => _hasContent || _hasMedia;

  void _handleContentChanged() {
    setState(() {});
  }

  Future<void> _pickMedia() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: true,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        // Limit to 5 files total
        final filesToAdd = result.files.take(5).toList();
        setState(() {
          _selectedFiles = filesToAdd;
        });
        
        if (result.files.length > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Maximum 5 images per post. Only first 5 selected.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Pick media error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick media. Please try again.')),
      );
    }
  }



  bool _isVideoExtension(String? extension) {
    if (extension == null) return false;
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension.toLowerCase());
  }

  bool _isVideoFile(PlatformFile file) {
    return _isVideoExtension(_determineExtension(file));
  }

  String _determineExtension(PlatformFile file) {
    final directExtension = file.extension?.trim();
    if (directExtension != null && directExtension.isNotEmpty) {
      return directExtension.toLowerCase();
    }

    final nameExtension = _extractExtensionFromName(file.name);
    if (nameExtension.isNotEmpty) {
      return nameExtension.toLowerCase();
    }

    if (file.path != null) {
      final pathExtension = _extractExtensionFromName(file.path!);
      if (pathExtension.isNotEmpty) {
        return pathExtension.toLowerCase();
      }
    }

    return '';
  }

  String _extractExtensionFromName(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) {
      return '';
    }
    return name.substring(dotIndex + 1);
  }

  Future<void> _autoDetectMetadata() async {
    setState(() => _isDetecting = true);
    
    try {
      final videoFile = _selectedFiles.firstWhere(_isVideoFile);
      VideoPlayerController? controller;
      
      // Initialize video player to extract metadata
      if (kIsWeb && videoFile.bytes != null) {
        final blob = videoFile.bytes!;
        final url = Uri.dataFromBytes(blob.toList()).toString();
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else if (videoFile.path != null) {
        controller = VideoPlayerController.file(File(videoFile.path!));
      }
      
      if (controller != null) {
        await controller.initialize();
        
        // Extract duration/clip length
        final duration = controller.value.duration;
        final seconds = duration.inSeconds;
        if (seconds > 0 && _clipLengthController.text.isEmpty) {
          _clipLengthController.text = seconds.toString();
        }
        
        // Try to detect FPS from video properties
        // Note: video_player doesn't expose FPS directly, so we'll set common defaults
        if (_fpsController.text.isEmpty) {
          // Most videos are 24, 30, or 60 fps - default to 24 for cinematic content
          _fpsController.text = '24';
        }
        
        controller.dispose();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Video duration detected: ${seconds}s')),
          );
        }
      }
    } catch (e) {
      debugPrint('Auto-detect error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not auto-detect all metadata. Please enter manually.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  String _contentTypeForExtension(String extension) {
    final lowerExt = extension.toLowerCase();

    if (_isVideoExtension(lowerExt)) {
      switch (lowerExt) {
        case 'mp4':
          return 'video/mp4';
        case 'mov':
          return 'video/quicktime';
        case 'avi':
          return 'video/x-msvideo';
        case 'mkv':
          return 'video/x-matroska';
        case 'webm':
          return 'video/webm';
        default:
          return 'video/$lowerExt';
      }
    }

    switch (lowerExt) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  Widget _buildMediaPreview(PlatformFile file) {
    final isVideo = _isVideoFile(file);
    
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[800],
        image: !isVideo && file.bytes != null
            ? DecorationImage(
                image: MemoryImage(file.bytes!),
                fit: BoxFit.cover,
              )
            : !isVideo && file.path != null
                ? DecorationImage(
                    image: FileImage(File(file.path!)),
                    fit: BoxFit.cover,
                  )
                : null,
      ),
      child: Stack(
        children: [
          if (isVideo)
            Center(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 24),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _selectedFiles.remove(file)),
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Create Post',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 24),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: 'Share your work or thoughts...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                autofocus: true,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickMedia,
                    icon: Icon(Icons.photo_library, size: 20),
                    label: Text('Upload Photo or Video (max 5)'),
                  ),
                  if (_selectedFiles.isNotEmpty) ...[
                    SizedBox(width: 8),
                    Text(
                      '${_selectedFiles.length}/5 selected',
                      style: TextStyle(color: Color(0xFF8B5CF6)),
                    ),
                  ],
                ],
              ),
              if (_selectedFiles.isNotEmpty) ...[
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedFiles.map(_buildMediaPreview).toList(),
                ),
              ],
              if (_selectedFiles.any(_isVideoFile)) ...[
                SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Video Metadata (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    TextButton.icon(
                      onPressed: _isDetecting ? null : _autoDetectMetadata,
                      icon: _isDetecting 
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.auto_fix_high, size: 18),
                      label: Text('Auto Detect'),
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cameraController,
                        decoration: InputDecoration(
                          labelText: 'Camera',
                          hintText: 'Sony A7SIII',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _lensController,
                        decoration: InputDecoration(
                          labelText: 'Lens',
                          hintText: '24-70mm',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _isoController,
                        decoration: InputDecoration(
                          labelText: 'ISO',
                          hintText: '800',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _fpsController,
                        decoration: InputDecoration(
                          labelText: 'FPS',
                          hintText: '24',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _clipLengthController,
                        decoration: InputDecoration(
                          labelText: 'Length (sec)',
                          hintText: '15',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _videoFormat,
                        decoration: InputDecoration(
                          labelText: 'Video Format',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: ['MP4', 'MOV', 'AVI', 'MKV', 'RAW', 'LOG', 'S-Log3', 'C-Log', 'V-Log', 'ProRes RAW', 'H.264', 'H.265/HEVC', 'ProRes 422'].map((format) =>
                          DropdownMenuItem(value: format, child: Text(format))
                        ).toList(),
                        onChanged: (value) => setState(() => _videoFormat = value),
                        hint: Text('Select format'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: CheckboxListTile(
                        title: Text('Color Graded', style: TextStyle(fontSize: 14)),
                        value: _isColorGraded,
                        onChanged: (value) => setState(() => _isColorGraded = value ?? false),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
              ],
              if (_selectedFiles.any((file) => !_isVideoFile(file))) ...[
                SizedBox(height: 20),
                Text(
                  'Image Metadata (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _imageCameraController,
                        decoration: InputDecoration(
                          labelText: 'Camera',
                          hintText: 'Sony A7SIII',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _imageLensController,
                        decoration: InputDecoration(
                          labelText: 'Lens',
                          hintText: '24-70mm',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _imageIsoController,
                        decoration: InputDecoration(
                          labelText: 'ISO',
                          hintText: '800',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _imageFormat,
                        decoration: InputDecoration(
                          labelText: 'Image Format',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: ['JPG', 'PNG', 'RAW', 'TIFF', 'DNG', 'WebP'].map((format) =>
                          DropdownMenuItem(value: format, child: Text(format))
                        ).toList(),
                        onChanged: (value) => setState(() => _imageFormat = value),
                        hint: Text('Select format'),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isPosting || !_canSubmit ? null : _submitPost,
                      child: _isPosting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.black),
                              ),
                            )
                          : Text('Post'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitPost() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add text or upload at least one file before posting.')),
      );
      return;
    }

    setState(() => _isPosting = true);

    final provider = context.read<AppProvider>();
    final currentUser = provider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be signed in to post.')),
      );
      setState(() => _isPosting = false);
      return;
    }

    try {
      final imageUrls = <String>[];
      final videoUrls = <String>[];

      // Upload all files to Supabase Storage
      for (final file in _selectedFiles) {
        if (file.bytes == null && file.path == null) continue;
        
        final bytes = file.bytes ?? await File(file.path!).readAsBytes();
        final rawExtension = _determineExtension(file);
        final isVideo = _isVideoExtension(rawExtension);
        final sanitizedExtension = rawExtension.isNotEmpty
            ? rawExtension
            : (isVideo ? 'mp4' : 'jpg');
        final bucket = isVideo ? 'videos' : 'images';
        final objectPath = '${currentUser.id}/${const Uuid().v4()}.$sanitizedExtension';

        final publicUrl = await SupabaseStorageService.uploadFile(
          bucket: bucket,
          path: objectPath,
          bytes: bytes,
          contentType: _contentTypeForExtension(sanitizedExtension),
        );

        print('✅ Uploaded to $bucket: $publicUrl');

        if (isVideo) {
          videoUrls.add(publicUrl);
        } else {
          imageUrls.add(publicUrl);
        }
      }

      Map<String, String>? cameraInfo;
      if (videoUrls.isNotEmpty && 
          (_cameraController.text.isNotEmpty || 
           _lensController.text.isNotEmpty || 
           _isoController.text.isNotEmpty || 
           _fpsController.text.isNotEmpty)) {
        cameraInfo = {};
        if (_cameraController.text.isNotEmpty) cameraInfo['Camera'] = _cameraController.text;
        if (_lensController.text.isNotEmpty) cameraInfo['Lens'] = _lensController.text;
        if (_isoController.text.isNotEmpty) cameraInfo['ISO'] = _isoController.text;
        if (_fpsController.text.isNotEmpty) cameraInfo['FPS'] = '${_fpsController.text}fps';
      }

      int? clipLength;
      if (videoUrls.isNotEmpty && _clipLengthController.text.isNotEmpty) {
        clipLength = int.tryParse(_clipLengthController.text);
      }

      Map<String, String>? imageCameraInfo;
      if (imageUrls.isNotEmpty && 
          (_imageCameraController.text.isNotEmpty || 
           _imageLensController.text.isNotEmpty || 
           _imageIsoController.text.isNotEmpty)) {
        imageCameraInfo = {};
        if (_imageCameraController.text.isNotEmpty) imageCameraInfo['Camera'] = _imageCameraController.text;
        if (_imageLensController.text.isNotEmpty) imageCameraInfo['Lens'] = _imageLensController.text;
        if (_imageIsoController.text.isNotEmpty) imageCameraInfo['ISO'] = _imageIsoController.text;
      }

      final post = PostModel(
        id: const Uuid().v4(),
        userId: currentUser.id,
        content: _contentController.text.trim(),
        imageUrls: imageUrls,
        videoUrls: videoUrls,
        createdAt: DateTime.now(),
        cameraInfo: cameraInfo,
        clipLength: clipLength,
        isColorGraded: videoUrls.isNotEmpty ? _isColorGraded : false,
        videoFormat: videoUrls.isNotEmpty ? _videoFormat : null,
        imageCameraInfo: imageCameraInfo,
        imageFormat: imageUrls.isNotEmpty ? _imageFormat : null,
      );

      print('📝 Creating post with ${imageUrls.length} images and ${videoUrls.length} videos');
      print('Image URLs: $imageUrls');
      print('Video URLs: $videoUrls');

      await provider.addPost(post);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Create post error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create post. Please try again.')),
        );
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }
}
