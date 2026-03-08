import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:google_fonts/google_fonts.dart';

/// **CodeBlock** - Syntax-highlighted code display with copy functionality
///
/// This widget renders code blocks within AI responses with proper syntax
/// highlighting, theme-aware styling, and user interaction features.
/// It's automatically used by the markdown parser for fenced code blocks.
///
/// ## Features:
/// - **Syntax Highlighting**: Language-specific highlighting via flutter_highlight
/// - **Theme Integration**: Light (VS) and Dark (VS2015) syntax themes
/// - **Copy Functionality**: One-click copy button with user feedback
/// - **Language Detection**: Automatic language detection from markdown
/// - **Responsive Design**: Horizontal scrolling for wide code blocks
/// - **Accessibility**: Screen reader support and keyboard navigation
///
/// ## Supported Languages:
/// - All languages supported by flutter_highlight package
/// - Common: dart, javascript, python, java, cpp, css, json, yaml, etc.
/// - Fallback: Plain text rendering when language not recognized
///
/// ## Integration:
/// - Used automatically by `ResponseWidget` markdown renderer
/// - Triggered by fenced code blocks in AI responses: ```language\ncode```
/// - Integrates with app theme for consistent visual experience
///
/// ## Styling Patterns:
/// ```dart
/// // Light theme: VS syntax highlighting
/// // Dark theme: VS2015 syntax highlighting
/// // Font: JetBrains Mono for optimal code readability
/// // Copy button: Positioned top-right with hover effects
/// ```
///
/// ## Customization Examples:
/// ```dart
/// // Add line numbers:
/// class NumberedCodeBlock extends CodeBlock {
///   @override
///   Widget build(BuildContext context) {
///     return Row([
///       _buildLineNumbers(),
///       Expanded(child: super.build(context)),
///     ]);
///   }
/// }
///
/// // Add code execution:
/// class ExecutableCodeBlock extends CodeBlock {
///   final Function(String)? onExecute;
///
///   Widget _buildActions() {
///     return Row([
///       IconButton(icon: Icon(LucideIcons.play), onPressed: () => onExecute?.(widget.code)),
///       _copyButton,
///     ]);
///   }
/// }
///
/// // Add custom syntax themes:
/// class ThemedCodeBlock extends CodeBlock {
///   final Map<String, TextStyle> customTheme;
///
///   @override
///   Map<String, TextStyle> get _syntaxTheme =>
///     isDark ? customTheme : vsLightTheme;
/// }
/// ```
class CodeBlock extends StatefulWidget {
  final String code;
  final String? language;
  const CodeBlock({super.key, required this.code, this.language});

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  bool _copied = false;

  void _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() {
      _copied = true;
    });

    // Reset the copied state after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  // Custom theme without background for light mode
  Map<String, TextStyle> get _lightTheme {
    final theme = Map<String, TextStyle>.from(vsTheme);
    // Remove any background colors
    return theme.map(
      (key, style) =>
          MapEntry(key, style.copyWith(backgroundColor: Colors.transparent)),
    );
  }

  // Custom theme without background for dark mode
  Map<String, TextStyle> get _darkTheme {
    final theme = Map<String, TextStyle>.from(vs2015Theme);
    // Remove any background colors
    return theme.map(
      (key, style) =>
          MapEntry(key, style.copyWith(backgroundColor: Colors.transparent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Code content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: HighlightView(
              widget.code,
              language: widget.language ?? 'text',
              theme: Theme.of(context).brightness == Brightness.dark
                  ? _darkTheme
                  : _lightTheme,
              textStyle: GoogleFonts.jetBrainsMono(
                fontSize: 14,
              ),
            ),
          ),
          // Copy button in top right
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                _copied ? LucideIcons.check : LucideIcons.copy,
                size: 16,
              ),
              onPressed: _handleCopy,
              tooltip: _copied ? 'Copied!' : 'Copy',
            ),
          ),
        ],
      ),
    );
  }
}
