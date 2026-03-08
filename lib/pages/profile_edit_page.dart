import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vidi/widgets/image_crop_dialog.dart';
import 'package:vidi/supabase/supabase_config.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({Key? key}) : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _locationController;
  late TextEditingController _instagramController;
  late TextEditingController _twitterController;
  late TextEditingController _youtubeController;
  late TextEditingController _linkedinController;
  late TextEditingController _websiteController;
  late TextEditingController _portfolioLinkController;
  late TextEditingController _featuredReelController;
  late TextEditingController _gearBadgeController;
  String _selectedSkillLevel = 'Beginner';
  String? _editingStyle;
  List<String> _specializations = [];
  List<String> _gearBadges = [];
  final TextEditingController _specializationController = TextEditingController();
  String _portfolioFileName = '';
  String _profilePhotoPath = '';

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().currentUser!;
    _nameController = TextEditingController(text: user.name);
    _bioController = TextEditingController(text: user.bio);
    _hourlyRateController = TextEditingController(text: user.hourlyRate.toString());
    _locationController = TextEditingController(text: user.location);
    _instagramController = TextEditingController(text: user.socialLinks['instagram'] ?? '');
    _twitterController = TextEditingController(text: user.socialLinks['twitter'] ?? '');
    _youtubeController = TextEditingController(text: user.socialLinks['youtube'] ?? '');
    _linkedinController = TextEditingController(text: user.socialLinks['linkedin'] ?? '');
    _websiteController = TextEditingController(text: user.socialLinks['website'] ?? '');
    _portfolioLinkController = TextEditingController(text: user.portfolioLink);
    _featuredReelController = TextEditingController(text: user.featuredReelUrl ?? '');
    _gearBadgeController = TextEditingController();
    _selectedSkillLevel = user.skillLevel;
    _editingStyle = user.editingStyle;
    _specializations = List.from(user.specializations);
    _gearBadges = List.from(user.gearBadges);
    _portfolioFileName = user.portfolioFile;
    _profilePhotoPath = user.profilePicUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    _locationController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _youtubeController.dispose();
    _linkedinController.dispose();
    _websiteController.dispose();
    _portfolioLinkController.dispose();
    _featuredReelController.dispose();
    _gearBadgeController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text('Save', style: TextStyle(color: Color(0xFF8B5CF6))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        backgroundImage: _profilePhotoPath.isNotEmpty 
                            ? (_profilePhotoPath.startsWith('data:image') 
                                ? MemoryImage(_decodeBase64Image(_profilePhotoPath))
                                : _profilePhotoPath.startsWith('http')
                                    ? NetworkImage(_profilePhotoPath)
                                    : NetworkImage(_profilePhotoPath) as ImageProvider)
                            : null,
                        child: _profilePhotoPath.isEmpty 
                            ? Icon(Icons.person, size: 60, color: Color(0xFF8B5CF6)) 
                            : null,
                      ),
                      SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _pickProfilePhoto,
                        icon: Icon(Icons.camera_alt),
                        label: Text('Change Photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'Your full name',
                  ),
                  validator: (val) => val?.isEmpty == true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell clients about yourself and your experience...',
                  ),
                  maxLines: 4,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedSkillLevel,
                  decoration: InputDecoration(
                    labelText: 'Skill Level',
                  ),
                  items: ['Beginner', 'Intermediate', 'Expert']
                      .map((level) => DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedSkillLevel = val!),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _hourlyRateController,
                  decoration: InputDecoration(
                    labelText: 'Hourly Rate (\$)',
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    hintText: 'City, Country',
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'Social Media Links',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _instagramController,
                  decoration: InputDecoration(
                    labelText: 'Instagram',
                    hintText: 'https://instagram.com/username',
                    prefixIcon: Icon(Icons.camera_alt),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _twitterController,
                  decoration: InputDecoration(
                    labelText: 'Twitter / X',
                    hintText: 'https://twitter.com/username',
                    prefixIcon: Icon(Icons.message),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _youtubeController,
                  decoration: InputDecoration(
                    labelText: 'YouTube',
                    hintText: 'https://youtube.com/@username',
                    prefixIcon: Icon(Icons.play_circle),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _linkedinController,
                  decoration: InputDecoration(
                    labelText: 'LinkedIn',
                    hintText: 'https://linkedin.com/in/username',
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _websiteController,
                  decoration: InputDecoration(
                    labelText: 'Website',
                    hintText: 'https://yourwebsite.com',
                    prefixIcon: Icon(Icons.language),
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'Portfolio',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _portfolioLinkController,
                  decoration: InputDecoration(
                    labelText: 'Portfolio Link',
                    hintText: 'Link to your portfolio or demo reel',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickPortfolioFile,
                  icon: Icon(Icons.upload_file),
                  label: Text(_portfolioFileName.isEmpty 
                      ? 'Upload Portfolio File' 
                      : 'File: $_portfolioFileName'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF8B5CF6),
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'Editor Profile',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _editingStyle,
                  decoration: InputDecoration(
                    labelText: 'Editing Style',
                    prefixIcon: Icon(Icons.movie_filter),
                  ),
                  items: [
                    'Cinematic',
                    'Documentary',
                    'Hype',
                    'Travel',
                    'Corporate',
                    'Music Video',
                    'Wedding',
                    'Fashion',
                    'Sports',
                  ].map((style) => DropdownMenuItem(value: style, child: Text(style))).toList(),
                  onChanged: (val) => setState(() => _editingStyle = val),
                  hint: Text('Select your editing style'),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _featuredReelController,
                  decoration: InputDecoration(
                    labelText: 'Featured Reel URL',
                    hintText: 'Link to your best work reel',
                    prefixIcon: Icon(Icons.star),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gearBadgeController,
                        decoration: InputDecoration(
                          hintText: 'Add gear (e.g., Sony A7SIII, DaVinci Resolve)',
                        ),
                        onSubmitted: (_) => _addGearBadge(),
                      ),
                    ),
                    IconButton(
                      onPressed: _addGearBadge,
                      icon: Icon(Icons.add, color: Color(0xFF8B5CF6)),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (_gearBadges.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _gearBadges.map((gear) => Chip(
                      label: Text(gear),
                      deleteIcon: Icon(Icons.close, size: 18),
                      onDeleted: () => setState(() => _gearBadges.remove(gear)),
                      backgroundColor: Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    )).toList(),
                  ),
                SizedBox(height: 32),
                Text(
                  'Skills & Specializations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _specializationController,
                        decoration: InputDecoration(
                          hintText: 'Add a skill (e.g., Color Grading)',
                        ),
                        onSubmitted: (_) => _addSpecialization(),
                      ),
                    ),
                    IconButton(
                      onPressed: _addSpecialization,
                      icon: Icon(Icons.add, color: Color(0xFF8B5CF6)),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _specializations.map((spec) => Chip(
                    label: Text(spec),
                    deleteIcon: Icon(Icons.close, size: 18),
                    onDeleted: () => setState(() => _specializations.remove(spec)),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Uint8List _decodeBase64Image(String dataUrl) {
    final base64String = dataUrl.split(',')[1];
    return base64Decode(base64String);
  }

  Future<void> _pickProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        // Show crop dialog
        final croppedBytes = await showDialog<Uint8List>(
          context: context,
          builder: (context) => ImageCropDialog(imageBytes: file.bytes!),
        );
        
        if (croppedBytes != null && mounted) {
          // Upload to Supabase Storage
          try {
            final userId = context.read<AppProvider>().currentUser?.id ?? '';
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final path = 'profiles/$userId/avatar_$timestamp.png';
            
            final url = await SupabaseStorageService.uploadFile(
              bucket: 'profiles',
              path: path,
              bytes: croppedBytes,
              contentType: 'image/png',
            );
            
            setState(() => _profilePhotoPath = url);
          } catch (e) {
            // Silently fall back to base64 if storage upload fails
            // (e.g., bucket doesn't exist or storage not configured)
            print('Storage upload failed, using base64: $e');
            final base64String = base64Encode(croppedBytes);
            setState(() => _profilePhotoPath = 'data:image/png;base64,$base64String');
          }
        }
      }
    }
  }

  Future<void> _pickPortfolioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    
    if (result != null) {
      setState(() => _portfolioFileName = result.files.single.name);
    }
  }

  void _addSpecialization() {
    final text = _specializationController.text.trim();
    if (text.isNotEmpty && !_specializations.contains(text)) {
      setState(() {
        _specializations.add(text);
        _specializationController.clear();
      });
    }
  }

  void _addGearBadge() {
    final text = _gearBadgeController.text.trim();
    if (text.isNotEmpty && !_gearBadges.contains(text)) {
      setState(() {
        _gearBadges.add(text);
        _gearBadgeController.clear();
      });
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AppProvider>();
    final currentUser = provider.currentUser!;

    final socialLinks = <String, String>{};
    if (_instagramController.text.isNotEmpty) {
      socialLinks['instagram'] = _instagramController.text;
    }
    if (_twitterController.text.isNotEmpty) {
      socialLinks['twitter'] = _twitterController.text;
    }
    if (_youtubeController.text.isNotEmpty) {
      socialLinks['youtube'] = _youtubeController.text;
    }
    if (_linkedinController.text.isNotEmpty) {
      socialLinks['linkedin'] = _linkedinController.text;
    }
    if (_websiteController.text.isNotEmpty) {
      socialLinks['website'] = _websiteController.text;
    }

    final updatedUser = currentUser.copyWith(
      name: _nameController.text,
      bio: _bioController.text,
      skillLevel: _selectedSkillLevel,
      hourlyRate: double.tryParse(_hourlyRateController.text) ?? 0,
      location: _locationController.text,
      specializations: _specializations,
      socialLinks: socialLinks,
      portfolioLink: _portfolioLinkController.text,
      portfolioFile: _portfolioFileName,
      profilePicUrl: _profilePhotoPath,
      editingStyle: _editingStyle,
      gearBadges: _gearBadges,
      featuredReelUrl: _featuredReelController.text,
      updatedAt: DateTime.now(),
    );

    await provider.updateUser(updatedUser);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated successfully')),
    );
  }
}
