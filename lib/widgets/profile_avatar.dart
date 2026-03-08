import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Color? backgroundColor;
  final IconData defaultIcon;

  const ProfileAvatar({
    Key? key,
    required this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.defaultIcon = Icons.person,
  }) : super(key: key);

  Uint8List? _decodeBase64Image(String dataUrl) {
    try {
      final base64String = dataUrl.split(',')[1];
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  ImageProvider? _getImageProvider() {
    if (imageUrl.isEmpty) return null;
    
    if (imageUrl.startsWith('data:image')) {
      final bytes = _decodeBase64Image(imageUrl);
      return bytes != null ? MemoryImage(bytes) : null;
    } else if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _getImageProvider();
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Color(0xFF8B5CF6).withValues(alpha: 0.2),
      backgroundImage: imageProvider,
      child: imageProvider == null ? Icon(defaultIcon, size: radius, color: Color(0xFF8B5CF6)) : null,
    );
  }
}
