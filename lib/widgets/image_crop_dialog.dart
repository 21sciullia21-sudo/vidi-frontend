import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ImageCropDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const ImageCropDialog({Key? key, required this.imageBytes}) : super(key: key);

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  ui.Image? _image;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.black,
              title: Text('Adjust Photo', style: TextStyle(color: Colors.white)),
              leading: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                TextButton(
                  onPressed: _isLoading ? null : _cropAndSave,
                  child: Text('Done', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                  : GestureDetector(
                      onScaleStart: (details) {},
                      onScaleUpdate: (details) {
                        setState(() {
                          _scale = (_scale * details.scale).clamp(0.5, 3.0);
                          _offset += details.focalPointDelta;
                        });
                      },
                      child: Container(
                        color: Colors.black,
                        child: Stack(
                          children: [
                            Center(
                              child: Transform(
                                transform: Matrix4.identity()
                                  ..translate(_offset.dx, _offset.dy)
                                  ..scale(_scale),
                                alignment: Alignment.center,
                                child: _image != null
                                    ? RawImage(
                                        image: _image,
                                        fit: BoxFit.contain,
                                      )
                                    : SizedBox(),
                              ),
                            ),
                            // Crop overlay
                            Center(
                              child: Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white, width: 2),
                                  borderRadius: BorderRadius.circular(150),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            Container(
              color: Colors.black,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Pinch to zoom, drag to adjust', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => setState(() => _scale = (_scale - 0.1).clamp(0.5, 3.0)),
                        icon: Icon(Icons.remove_circle_outline, color: Colors.white, size: 32),
                      ),
                      SizedBox(width: 32),
                      Text('${(_scale * 100).toInt()}%', style: TextStyle(color: Colors.white, fontSize: 16)),
                      SizedBox(width: 32),
                      IconButton(
                        onPressed: () => setState(() => _scale = (_scale + 0.1).clamp(0.5, 3.0)),
                        icon: Icon(Icons.add_circle_outline, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cropAndSave() async {
    if (_image == null) return;

    try {
      final cropSize = 300.0;
      final outputSize = 400;
      
      // Get the image dimensions
      final imageWidth = _image!.width.toDouble();
      final imageHeight = _image!.height.toDouble();
      
      // Calculate the scale factor to fit the image on screen (BoxFit.contain behavior)
      final screenSize = MediaQuery.of(context).size;
      final containerWidth = screenSize.width * 0.9;
      final containerHeight = screenSize.height * 0.8 - 200;
      
      final widthRatio = containerWidth / imageWidth;
      final heightRatio = containerHeight / imageHeight;
      final fitScale = widthRatio < heightRatio ? widthRatio : heightRatio;
      
      // Display size of the image
      final displayWidth = imageWidth * fitScale;
      final displayHeight = imageHeight * fitScale;
      
      // The image is centered, so calculate its position on screen
      final imageLeft = (containerWidth - displayWidth) / 2;
      final imageTop = (containerHeight - displayHeight) / 2;
      
      // Crop circle is centered on screen
      final cropCenterX = containerWidth / 2;
      final cropCenterY = containerHeight / 2;
      
      // Calculate the crop area top-left corner relative to the image's top-left (before transformations)
      // We need to work backwards from the crop circle position through the transformations
      // Crop circle center in image display space (before user transform)
      final cropInImageX = (cropCenterX - imageLeft - _offset.dx) / _scale;
      final cropInImageY = (cropCenterY - imageTop - _offset.dy) / _scale;
      
      // Convert from display space to original image space
      final cropInOriginalX = cropInImageX / fitScale;
      final cropInOriginalY = cropInImageY / fitScale;
      
      // Calculate crop size in original image coordinates
      final cropSizeInOriginal = (cropSize / _scale) / fitScale;
      
      // Calculate top-left corner of crop area in original image
      final srcLeft = (cropInOriginalX - cropSizeInOriginal / 2).clamp(0.0, imageWidth);
      final srcTop = (cropInOriginalY - cropSizeInOriginal / 2).clamp(0.0, imageHeight);
      final srcRight = (cropInOriginalX + cropSizeInOriginal / 2).clamp(0.0, imageWidth);
      final srcBottom = (cropInOriginalY + cropSizeInOriginal / 2).clamp(0.0, imageHeight);
      
      // Create cropped image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      final srcRect = Rect.fromLTRB(srcLeft, srcTop, srcRight, srcBottom);
      final dstRect = Rect.fromLTWH(0, 0, outputSize.toDouble(), outputSize.toDouble());
      
      // Draw black background first to handle transparency
      canvas.drawRect(dstRect, Paint()..color = Colors.black);
      
      // Draw image on top of black background
      canvas.drawImageRect(_image!, srcRect, dstRect, Paint());
      
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(outputSize, outputSize);
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      
      Navigator.pop(context, bytes);
    } catch (e) {
      print('Error cropping image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cropping image')),
      );
    }
  }
}
