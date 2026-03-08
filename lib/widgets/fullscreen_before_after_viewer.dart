import 'package:flutter/material.dart';

class FullScreenBeforeAfterViewer extends StatefulWidget {
  final String beforeImageUrl;
  final String afterImageUrl;

  const FullScreenBeforeAfterViewer({
    Key? key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
  }) : super(key: key);

  @override
  State<FullScreenBeforeAfterViewer> createState() => _FullScreenBeforeAfterViewerState();
}

class _FullScreenBeforeAfterViewerState extends State<FullScreenBeforeAfterViewer> {
  double _sliderPosition = 0.5;
  bool _showControls = true;

  ImageProvider? _getImageProvider(String imageUrl) {
    if (imageUrl.isEmpty) return null;
    
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final beforeProvider = _getImageProvider(widget.beforeImageUrl);
    final afterProvider = _getImageProvider(widget.afterImageUrl);

    if (beforeProvider == null || afterProvider == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 100, color: Colors.grey[600]),
              SizedBox(height: 16),
              Text(
                'Failed to load images',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        onHorizontalDragUpdate: (details) {
          setState(() {
            _sliderPosition = (_sliderPosition + details.delta.dx / MediaQuery.of(context).size.width).clamp(0.0, 1.0);
          });
        },
        child: Stack(
          children: [
            // After image (full width)
            Positioned.fill(
              child: Image(
                image: afterProvider,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[800],
                  child: Icon(Icons.broken_image, size: 100, color: Colors.grey[600]),
                ),
              ),
            ),
            // Before image (clipped)
            Positioned.fill(
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: _sliderPosition,
                  child: Image(
                    image: beforeProvider,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: Icon(Icons.broken_image, size: 100, color: Colors.grey[600]),
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
              top: MediaQuery.of(context).size.height / 2 - 24,
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
            if (_showControls) ...[
              // Top gradient and close button
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white, size: 28),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Labels
              Positioned(
                top: 100,
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
                top: 100,
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
                bottom: 40,
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
          ],
        ),
      ),
    );
  }
}
