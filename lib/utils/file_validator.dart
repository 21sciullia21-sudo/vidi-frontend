class FileValidator {
  // Whitelist of allowed file extensions for store uploads
  static const List<String> _allowedExtensions = [
    // Images / Overlays
    'jpg', 'jpeg', 'png', 'tiff', 'tif', 'bmp', 'gif', 'webp',
    
    // Video Overlays / Assets
    'mp4', 'mov', 'm4v', 'avi', 'mxf', 'webm', 'prores',
    
    // LUTs
    'cube', '3dl', 'look',
    
    // Sound Effects
    'wav', 'mp3', 'aiff', 'flac', 'ogg',
    
    // 3D Assets
    'obj', 'fbx', 'blend', 'stl', 'dae', 'gltf', 'glb',
    
    // Project Files (Safe types only)
    'aep', 'aepx', 'prproj', 'drp',
    
    // Archives (must only contain allowed file types)
    'zip',
  ];

  // Blocked executable and scriptable file extensions
  static const List<String> _blockedExtensions = [
    'exe', 'bat', 'sh', 'cmd', 'msi', 'apk', 'js', 'py', 'jar',
    'com', 'vbs', 'scr', 'dll', 'app', 'deb', 'rpm', 'run',
    'ps1', 'psm1', 'psd1', 'php', 'rb', 'pl', 'cgi', 'bin',
    'elf', 'so', 'dylib', 'sys', 'drv', 'ocx', 'cpl',
  ];

  /// Validates if a file is allowed for upload
  /// Returns null if valid, or an error message if invalid
  static String? validateFile(String filename) {
    final extension = _getFileExtension(filename).toLowerCase();
    
    if (extension.isEmpty) {
      return 'File has no extension. This file type is not allowed for security reasons.';
    }

    // Check if it's a blocked extension
    if (_blockedExtensions.contains(extension)) {
      return 'This file type is not allowed for security reasons.';
    }

    // Check if it's an allowed extension
    if (!_allowedExtensions.contains(extension)) {
      return 'This file type is not allowed for security reasons.';
    }

    return null; // File is valid
  }

  /// Gets the file extension from a filename
  static String _getFileExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  /// Gets allowed extensions formatted for FilePicker
  static List<String> get allowedExtensions => List.from(_allowedExtensions);

  /// Gets a human-readable list of allowed file types
  static String get allowedTypesDescription {
    return '''
Allowed file types:
• Images: jpg, jpeg, png, tiff, bmp, gif, webp
• Videos: mp4, mov, m4v, avi, mxf, webm
• LUTs: cube, 3dl, look
• Audio: wav, mp3, aiff, flac, ogg
• 3D Assets: obj, fbx, blend, stl, dae, gltf, glb
• Projects: aep, aepx, prproj, drp, zip
''';
  }

  /// Gets the MIME content type for a file based on its extension
  static String getContentType(String filename) {
    final extension = _getFileExtension(filename).toLowerCase();
    
    // Images
    if (['jpg', 'jpeg'].contains(extension)) return 'image/jpeg';
    if (extension == 'png') return 'image/png';
    if (['tiff', 'tif'].contains(extension)) return 'image/tiff';
    if (extension == 'bmp') return 'image/bmp';
    if (extension == 'gif') return 'image/gif';
    if (extension == 'webp') return 'image/webp';
    
    // Videos
    if (extension == 'mp4') return 'video/mp4';
    if (extension == 'mov') return 'video/quicktime';
    if (extension == 'm4v') return 'video/x-m4v';
    if (extension == 'avi') return 'video/x-msvideo';
    if (extension == 'mxf') return 'application/mxf';
    if (extension == 'webm') return 'video/webm';
    
    // Audio
    if (extension == 'wav') return 'audio/wav';
    if (extension == 'mp3') return 'audio/mpeg';
    if (extension == 'aiff') return 'audio/aiff';
    if (extension == 'flac') return 'audio/flac';
    if (extension == 'ogg') return 'audio/ogg';
    
    // 3D Assets
    if (extension == 'obj') return 'model/obj';
    if (extension == 'fbx') return 'application/octet-stream';
    if (extension == 'blend') return 'application/x-blender';
    if (extension == 'stl') return 'model/stl';
    if (extension == 'dae') return 'model/vnd.collada+xml';
    if (extension == 'gltf') return 'model/gltf+json';
    if (extension == 'glb') return 'model/gltf-binary';
    
    // Archives
    if (extension == 'zip') return 'application/zip';
    
    // Default to octet-stream for other allowed types
    return 'application/octet-stream';
  }
}
