import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// **Loader** - Animated loading indicator for streaming and processing states
///
/// A simple, elegant spinning loader using the Lucide loader2 icon.
/// Provides consistent loading feedback across the application with
/// theme-aware styling and customizable sizing.
///
/// ## Features:
/// - **Smooth Animation**: Continuous 1-second rotation cycle
/// - **Theme Integration**: Uses primary color from current theme
/// - **Customizable Size**: Configurable dimensions via size parameter
/// - **Performance**: Efficient animation with proper cleanup
/// - **Accessibility**: Works with screen readers and respects reduced motion
///
/// ## Usage Contexts:
/// - **Message Streaming**: Shows in MessageView during AI response generation
/// - **Processing States**: General loading indicator for async operations
/// - **Button States**: Can be embedded in buttons during processing
/// - **Sidebar Loading**: Used in conversation list during data loading
///
/// ## Visual Design:
/// - Uses Lucide loader2 icon for modern, minimal aesthetic
/// - Consistent with app's icon design language
/// - Smooth rotation animation without jarring motion
/// - Proper sizing for different use contexts
///
/// ## Integration Examples:
/// ```dart
/// // In streaming message:
/// if (chatProvider.status == ChatStatus.streaming && message.content.isEmpty) {
///   return Loader(size: 20);
/// }
///
/// // In button:
/// ElevatedButton(
///   onPressed: isLoading ? null : onPressed,
///   child: isLoading ? Loader(size: 16) : Text('Submit'),
/// )
///
/// // In list item:
/// ListTile(
///   leading: isLoading ? Loader(size: 24) : Icon(LucideIcons.message),
///   title: Text('Loading conversation...'),
/// )
/// ```
///
/// ## Customization Examples:
/// ```dart
/// // Custom animation speed:
/// class FastLoader extends Loader {
///   @override
///   Duration get duration => Duration(milliseconds: 500);
/// }
///
/// // Custom colors:
/// class ColoredLoader extends Loader {
///   final Color color;
///
///   @override
///   Widget build(BuildContext context) => Transform.rotate(
///     angle: _controller.value * 2.0 * pi,
///     child: Icon(LucideIcons.loader2, color: color, size: widget.size),
///   );
/// }
///
/// // Pulse animation variant:
/// class PulseLoader extends StatefulWidget {
///   Widget build(BuildContext context) => AnimatedContainer(
///     width: widget.size * _pulseAnimation.value,
///     height: widget.size * _pulseAnimation.value,
///     child: Icon(LucideIcons.circle),
///   );
/// }
/// ```
class Loader extends StatefulWidget {
  final double size;
  const Loader({super.key, this.size = 16});

  @override
  State<Loader> createState() => _LoaderState();
}

class _LoaderState extends State<Loader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2.0 * 3.14159,
            child: Icon(
              LucideIcons.loader2,
              size: widget.size,
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }
}
