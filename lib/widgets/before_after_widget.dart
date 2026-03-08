import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class BeforeAfterWidget extends StatefulWidget {
  final String beforeImageUrl;
  final String afterImageUrl;

  const BeforeAfterWidget({
    Key? key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
  }) : super(key: key);

  @override
  State<BeforeAfterWidget> createState() => _BeforeAfterWidgetState();
}

class _BeforeAfterWidgetState extends State<BeforeAfterWidget> {
  double _sliderPosition = 0.5;

  ImageProvider? _getImageProvider(String imageUrl) {
    if (imageUrl.isEmpty) return null;
    
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    } else if (!kIsWeb && File(imageUrl).existsSync()) {
      return FileImage(File(imageUrl));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final beforeProvider = _getImageProvider(widget.beforeImageUrl);
    final afterProvider = _getImageProvider(widget.afterImageUrl);

    if (beforeProvider == null || afterProvider == null) {
      return Container(
        height: 300,
        color: Colors.grey[800],
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey[600]),
      );
    }

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _sliderPosition = (_sliderPosition + details.delta.dx / context.size!.width).clamp(0.0, 1.0);
        });
      },
      child: Container(
        height: 400,
        child: Stack(
          children: [
            // After image (full width)
            Positioned.fill(
              child: Image(
                image: afterProvider,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[800],
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey[600]),
                ),
              ),
            ),
            // Before image (clipped)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * _sliderPosition,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1.0,
                  child: Image(
                    image: beforeProvider,
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey[600]),
                    ),
                  ),
                ),
              ),
            ),
            // Slider line
            Positioned(
              left: MediaQuery.of(context).size.width * _sliderPosition - 2,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            // Slider handle
            Positioned(
              left: MediaQuery.of(context).size.width * _sliderPosition - 24,
              top: (400 / 2) - 24,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chevron_left, color: Color(0xFF8B5CF6), size: 20),
                    Icon(Icons.chevron_right, color: Color(0xFF8B5CF6), size: 20),
                  ],
                ),
              ),
            ),
            // Labels
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFF8B5CF6), width: 1.5),
                ),
                child: Text(
                  'BEFORE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFF10B981), width: 1.5),
                ),
                child: Text(
                  'AFTER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            // Instruction text
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swipe, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Swipe to compare',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
