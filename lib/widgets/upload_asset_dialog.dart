import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:vidi/models/asset_model.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/services/asset_service.dart';
import 'package:vidi/supabase/supabase_config.dart';
import 'package:vidi/utils/file_validator.dart';

class UploadAssetDialog extends StatefulWidget {
  const UploadAssetDialog({Key? key}) : super(key: key);

  @override
  State<UploadAssetDialog> createState() => _UploadAssetDialogState();
}

class _UploadAssetDialogState extends State<UploadAssetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'VFX Packs';
  String? _previewImagePath;
  Uint8List? _previewImageBytes;
  String? _previewImageName;
  String? _productFilePath;
  Uint8List? _productFileBytes;
  String? _productFileName;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'VFX Packs',
    'LUTs',
    'Transitions',
    'Sound Effects',
    'Templates',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickPreviewImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _previewImageBytes = file.bytes;
          _previewImageName = file.name;
          _previewImagePath = file.path ?? file.name;
        });
      }
    } catch (e) {
      debugPrint('Pick preview image error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't pick image. Please try again.")),
        );
      }
    }
  }

  Future<void> _pickProductFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: FileValidator.allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validate file type
        final validationError = FileValidator.validateFile(file.name);
        if (validationError != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(validationError),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
        
        setState(() {
          _productFileBytes = file.bytes;
          _productFileName = file.name;
          _productFilePath = file.path ?? file.name;
        });
      }
    } catch (e) {
      debugPrint('Pick product file error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't pick file. Please try again.")),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final currentUser = provider.currentUser;
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      String imageUrl = '';
      String? downloadUrl;

      // Encode preview image as base64
      if (_previewImageBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please upload a preview image')),
          );
          setState(() => _isSubmitting = false);
          return;
        }
      }

      // Require product file before continuing
      if (_productFileBytes == null || _productFileName == null) {
        debugPrint('Product file required but missing');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please upload the product file before publishing.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _isSubmitting = false);
        }
        return;
      }
      
      try {
        final base64Image = base64Encode(_previewImageBytes!);
        final extension = _previewImageName?.split('.').last ?? 'png';
        imageUrl = 'data:image/$extension;base64,$base64Image';
      } catch (e) {
        debugPrint('Error encoding preview image: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't process image. Please try again.")),
          );
          setState(() => _isSubmitting = false);
          return;
        }
      }

      // Upload product file to Supabase Storage (required)
      try {
        final assetId = Uuid().v4();
        final filePath = 'assets/$assetId/${_productFileName!}';
        final contentType = FileValidator.getContentType(_productFileName!);
        downloadUrl = await SupabaseStorageService.uploadFile(
          bucket: 'assets',
          path: filePath,
          bytes: _productFileBytes!,
          contentType: contentType,
        );
      } catch (e) {
        debugPrint('Error uploading product file: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Couldn't upload the product file. Please try again."),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _isSubmitting = false);
        }
        return;
      }

      final asset = AssetModel(
        id: Uuid().v4(),
        sellerId: currentUser.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        imageUrl: imageUrl,
        downloadUrl: downloadUrl ?? '',
        createdAt: DateTime.now(),
      );

      final assetService = AssetService();
      await assetService.addAsset(asset);
      await provider.initialize();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product uploaded successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting product: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't upload product. Please try again."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Upload Product',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Product Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value!),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        hintText: 'Describe your product...',
                      ),
                      maxLines: 3,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickPreviewImage,
                      icon: Icon(Icons.image),
                      label: Text(_previewImagePath == null 
                          ? 'Upload Preview Image' 
                          : 'Preview image selected'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                    SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickProductFile,
                      icon: Icon(Icons.folder_zip),
                        label: Text(_productFilePath == null 
                            ? 'Upload Product File (required)' 
                            : 'File selected'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Allowed: Images, Videos, LUTs, Audio, 3D Assets, Project Files',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    if (_previewImageName != null || _productFileName != null) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_previewImageName != null) ...[
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Color(0xFF8B5CF6), size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Preview: $_previewImageName',
                                      style: TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_productFileName != null) ...[
                              if (_previewImageName != null) SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Color(0xFF8B5CF6), size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Product: $_productFileName',
                                      style: TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8B5CF6),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Upload'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
