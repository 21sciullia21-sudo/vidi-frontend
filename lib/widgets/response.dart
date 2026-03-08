import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:google_fonts/google_fonts.dart';
import 'code_block.dart';

/// **Response** - Markdown renderer for AI assistant messages
///
/// This widget handles the rich rendering of AI responses, including text formatting,
/// code blocks, lists, links, and other markdown elements. It provides consistent
/// styling and integrates custom components like CodeBlock for syntax highlighting.
///
/// ## Key Features:
/// - **Full Markdown Support**: Headers, lists, links, emphasis, code blocks
/// - **Custom Code Rendering**: Integrates `CodeBlock` widget for syntax highlighting
/// - **Theme Integration**: Adapts typography and colors to current theme
/// - **Responsive Text**: Proper line heights and spacing for readability
/// - **Link Handling**: Clickable links with hover states
/// - **Performance**: Efficient rendering for large responses
///
/// ## Markdown Elements Supported:
/// - Headers (h1, h2, h3) with proper typography hierarchy
/// - Paragraphs with theme-appropriate spacing
/// - **Bold** and *italic* text formatting
/// - Inline `code` with monospace font
/// - Fenced code blocks with syntax highlighting
/// - Unordered and ordered lists
/// - Blockquotes with visual styling
/// - Horizontal rules for content separation
///
/// ## Code Block Integration:
/// - Automatically uses `CodeBlock` widget for ```fenced blocks```
/// - Supports language detection: ```dart, ```javascript, etc.
/// - Preserves syntax highlighting and copy functionality
/// - Adapts to light/dark theme automatically
///
/// ## Customization Examples:
/// ```dart
/// // Add custom markdown elements:
/// class ExtendedResponse extends Response {
///   @override
///   Map<String, MarkdownElementBuilder> get builders => {
///     ...super.builders,
///     'callout': CalloutBuilder(), // Custom callout boxes
///     'table': CustomTableBuilder(), // Enhanced table rendering
///   };
/// }
///
/// // Add link interception:
/// class InterceptedResponse extends Response {
///   final Function(String url)? onLinkTap;
///
///   @override
///   MarkdownStyleSheet get styleSheet => super.styleSheet.copyWith(
///     a: TextStyle(
///       color: Theme.of(context).colorScheme.primary,
///       decoration: TextDecoration.underline,
///     ),
///   );
/// }
///
/// // Add text selection:
/// class SelectableResponse extends Response {
///   @override
///   Widget build(BuildContext context) {
///     return SelectableMarkdownBody(
///       data: markdown,
///       styleSheet: styleSheet,
///       builders: builders,
///     );
///   }
/// }
/// ```
class Response extends StatelessWidget {
  final String markdown;
  const Response({super.key, required this.markdown});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: markdown,
      builders: {
        'code': CodeBlockBuilder(),
      },
      styleSheet: MarkdownStyleSheet(
        p: Theme.of(context).textTheme.bodyMedium,
        h1: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        h2: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        h3: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        code: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        codeblockDecoration: const BoxDecoration(),
        codeblockPadding: EdgeInsets.zero,
        blockquote: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            ),
          ),
        ),
        listBullet: Theme.of(context).textTheme.bodyMedium,
        tableBody: Theme.of(context).textTheme.bodyMedium,
        tableHead: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      selectable: true,
    );
  }
}

class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Only handle multi-line code blocks, not inline code
    // Inline code typically doesn't have a language class
    final String text = element.textContent;

    // If the text contains newlines or has a language class, treat it as a code block
    if (!text.contains('\n') && element.attributes['class'] == null) {
      return null; // Let the default markdown renderer handle inline code
    }

    final String? language = element.attributes['class']?.replaceFirst(
      'language-',
      '',
    );

    return CodeBlock(
      code: text,
      language: language,
    );
  }
}
