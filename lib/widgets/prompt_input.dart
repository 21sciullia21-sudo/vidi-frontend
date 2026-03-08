import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/config.dart';
import '../data/models.dart';

/// **PromptInput Components** - User input area with rich interaction features
///
/// This file provides a collection of input components for the chat interface,
/// from a simple base container to a full-featured input widget with model
/// selection, send actions, and keyboard shortcuts.
///
/// ## Component Hierarchy:
/// ```
/// PromptInput (base container)
/// ├── PromptInputSimple (text + send button)
/// └── PromptInputComplete (full featured)
///     ├── Model Selector Dropdown
///     ├── Multi-line Text Input
///     ├── Attachment Button (placeholder)
///     └── Send Button with shortcuts
/// ```
///
/// ## Key Features:
/// - **Responsive Design**: Adapts layout based on screen size and content
/// - **Keyboard Shortcuts**: Ctrl+Enter/Cmd+Enter to send, Enter for new lines
/// - **Model Selection**: Integrated dropdown for AI model switching
/// - **State Management**: Integrates with ChatProvider for sending messages
/// - **Accessibility**: Proper focus management and keyboard navigation
/// - **Theme Integration**: Consistent styling with app theme colors

/// **PromptInput** - Base container component for user input areas
///
/// Provides consistent styling and layout structure for all input variants.
/// This base component handles form integration, safe areas, and visual styling.
///
/// ## Usage:
/// ```dart
/// PromptInput(
///   onSubmit: () => print('Form submitted'),
///   child: YourCustomInputWidget(),
/// )
/// ```
class PromptInput extends StatelessWidget {
  final Widget child;
  final void Function()? onSubmit;

  const PromptInput({
    super.key,
    required this.child,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(
                      context,
                    ).colorScheme.outline
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.11),
                blurRadius: 12,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// Textarea component
class PromptInputTextarea extends StatefulWidget {
  final TextEditingController? controller;
  final String placeholder;
  final double minHeight;
  final double maxHeight;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmit;

  const PromptInputTextarea({
    super.key,
    this.controller,
    this.placeholder = 'What would you like to know?',
    this.minHeight = 60,
    this.maxHeight = 160,
    this.onChanged,
    this.onSubmit,
  });

  @override
  State<PromptInputTextarea> createState() => _PromptInputTextareaState();
}

class _PromptInputTextareaState extends State<PromptInputTextarea> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 6,
      ),
      constraints: BoxConstraints(
        minHeight: widget.minHeight,
        maxHeight: widget.maxHeight,
      ),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
            final pressed = HardwareKeyboard.instance.logicalKeysPressed;
            final isShift =
                pressed.contains(LogicalKeyboardKey.shiftLeft) ||
                pressed.contains(LogicalKeyboardKey.shiftRight);
            if (!isShift) {
              // Submit on Enter
              widget.onSubmit?.call();
              return KeyEventResult.handled; // Prevent newline
            }
            // Shift+Enter → allow default newline
            return KeyEventResult.ignored;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          minLines: 1,
          maxLines: null,
          onChanged: widget.onChanged,
          onSubmitted: (_) => widget.onSubmit?.call(),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.all(12),
          ),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

// Toolbar component
class PromptInputToolbar extends StatelessWidget {
  final Widget child;

  const PromptInputToolbar({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: child,
    );
  }
}

// Tools section (left side of toolbar)
class PromptInputTools extends StatelessWidget {
  final List<Widget> children;

  const PromptInputTools({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

// Generic button component
class PromptInputButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;

  const PromptInputButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      onPressed: onPressed,
      icon: child,
      style: IconButton.styleFrom(
        splashFactory: NoSplash.splashFactory,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.all(6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

// Submit button component
class PromptInputSubmit extends StatelessWidget {
  final ChatStatus status;
  final VoidCallback? onSubmit;
  final VoidCallback? onStop;
  final bool enabled;

  const PromptInputSubmit({
    super.key,
    this.status = ChatStatus.idle,
    this.onSubmit,
    this.onStop,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    VoidCallback? onPressed;
    String tooltip;

    switch (status) {
      case ChatStatus.idle:
        icon = LucideIcons.send;
        onPressed = enabled ? onSubmit : null;
        tooltip = 'Send message';
        break;
      case ChatStatus.submitting:
        icon = LucideIcons.loader2;
        onPressed = null;
        tooltip = 'Sending...';
        break;
      case ChatStatus.streaming:
        icon = LucideIcons.square;
        onPressed = onStop;
        tooltip = 'Stop generation';
        break;
      case ChatStatus.error:
        icon = LucideIcons.x;
        onPressed = onSubmit;
        tooltip = 'Retry';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: status == ChatStatus.submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: onPressed != null
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          foregroundColor: onPressed != null
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// Model selection components
class PromptInputModelSelect extends StatefulWidget {
  final String value;
  final List<String> models;
  final ValueChanged<String>? onChanged;

  const PromptInputModelSelect({
    super.key,
    required this.value,
    required this.models,
    this.onChanged,
  });

  @override
  State<PromptInputModelSelect> createState() => _PromptInputModelSelectState();
}

class _PromptInputModelSelectState extends State<PromptInputModelSelect> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;
  bool _isHovered = false;

  String _getDisplayName(String modelId) {
    return AppConfig.modelDisplayNames[modelId] ?? modelId;
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!mounted) {
      _isOpen = false;
      return;
    }
    setState(() {
      _isOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    const maxDropdownHeight =
        280.0; // Maximum height for dropdown (reduced for smaller model list)
    const itemHeight =
        40.0; // Height per item including padding (increased for better touch targets)
    const verticalPadding = 8.0; // Total vertical padding

    final idealHeight = (widget.models.length * itemHeight) + verticalPadding;
    final dropdownHeight = idealHeight > maxDropdownHeight
        ? maxDropdownHeight
        : idealHeight;

    // Calculate if there's space below, otherwise position above
    final spaceBelow =
        screenSize.height -
        (position.dy + size.height) -
        20; // 20px margin from bottom
    final spaceAbove = position.dy - 20; // 20px margin from top
    final shouldShowAbove =
        spaceBelow < dropdownHeight && spaceAbove > dropdownHeight;

    // Calculate offset - always align left edge of dropdown with left edge of button
    final offset = shouldShowAbove
        ? Offset(0, -dropdownHeight - 4) // Above with gap
        : Offset(0, size.height + 4); // Below with gap

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown, // Close when clicking outside
        child: Stack(
          children: [
            Positioned(
              width: 280, // Slightly wider for better model name display
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: offset,
                child: GestureDetector(
                  onTap: () {}, // Prevent closing when clicking inside
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surface,
                    shadowColor: Theme.of(
                      context,
                    ).shadowColor.withValues(alpha: 0.2),
                    child: Container(
                      height: dropdownHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.8),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: idealHeight > maxDropdownHeight
                            ? Scrollbar(
                                thumbVisibility: true,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  shrinkWrap: true,
                                  itemCount: widget.models.length,
                                  itemBuilder: (context, index) {
                                    return _buildMenuItem(
                                      widget.models[index],
                                    );
                                  },
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: widget.models
                                      .map(_buildMenuItem)
                                      .toList(),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String model) {
    final isSelected = model == widget.value;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          widget.onChanged?.call(model);
          _closeDropdown();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.08)
                : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _getDisplayName(model),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                Icon(
                  LucideIcons.check,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Avoid calling setState during dispose; directly remove overlay
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.04)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 4),
                Text(
                  _getDisplayName(widget.value),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 100),
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// **PromptInputComplete** - Full-featured user input widget with all chat features
///
/// This is the primary input component used in ChatPage. It combines text input,
/// model selection, action buttons, and keyboard shortcuts into a cohesive
/// user experience.
///
/// ## Features:
/// - **Multi-line Text Input**: Auto-expanding with min/max height constraints
/// - **Model Selection**: Integrated dropdown for switching AI models
/// - **Keyboard Shortcuts**: Ctrl/Cmd+Enter to send, Enter for new lines
/// - **Action Buttons**: Send, stop generation, attachment (placeholder)
/// - **State Integration**: Responds to ChatStatus for proper UI states
/// - **Accessibility**: Full keyboard navigation and screen reader support
///
/// ## Parameters:
/// - `onSubmit`: Called with (prompt, modelId) when user sends message
/// - `models`: List of available AI models for dropdown
/// - `modelId`: Currently selected model (controls dropdown state)
/// - `status`: Current chat status (idle/streaming/etc) - affects button states
/// - `placeholder`: Input field placeholder text
/// - `minHeight`/`maxHeight`: Text field height constraints
/// - `onStop`: Called when user stops generation (shows during streaming)
/// - `onModelChanged`: Called when user selects different model
/// - `onAddAttachment`: Placeholder for future file attachment feature
///
/// ## Integration Pattern:
/// ```dart
/// // In ChatPage:
/// PromptInputComplete(
///   onSubmit: (prompt, modelId) => chatProvider.sendMessage(prompt, modelId),
///   models: AppConfig.availableModels,
///   modelId: chatProvider.currentModelId,
///   status: chatProvider.status,
///   onStop: () => chatProvider.stopGeneration(),
///   onModelChanged: (model) => chatProvider.setModel(model),
/// )
/// ```
///
/// ## Customization Examples:
/// ```dart
/// // Add custom shortcuts:
/// class ShortcutPromptInput extends PromptInputComplete {
///   @override
///   Widget build(BuildContext context) {
///     return Shortcuts(
///       shortcuts: {
///         LogicalKeySet(LogicalKeyboardKey.escape): VoidCallableIntent(() => clearInput()),
///       },
///       child: super.build(context),
///     );
///   }
/// }
///
/// // Add input validation:
/// class ValidatedPromptInput extends PromptInputComplete {
///   final String? Function(String)? validator;
///
///   void _validateAndSubmit() {
///     final error = validator?.call(_controller.text);
///     if (error != null) {
///       showErrorSnackbar(error);
///       return;
///     }
///     widget.onSubmit?.call(_controller.text, _currentModel);
///   }
/// }
/// ```
class PromptInputComplete extends StatefulWidget {
  final void Function(String prompt, String modelId)? onSubmit;
  final List<String>? models;
  final String? modelId;
  final ChatStatus status;
  final String placeholder;
  final double minHeight;
  final double maxHeight;
  final VoidCallback? onStop;
  final ValueChanged<String>? onModelChanged;
  final VoidCallback? onAddAttachment;

  const PromptInputComplete({
    super.key,
    this.onSubmit,
    this.models,
    this.modelId,
    this.status = ChatStatus.idle,
    this.placeholder = 'What would you like to know?',
    this.minHeight = 48,
    this.maxHeight = 160,
    this.onStop,
    this.onModelChanged,
    this.onAddAttachment,
  });

  @override
  State<PromptInputComplete> createState() => _PromptInputCompleteState();
}

class _PromptInputCompleteState extends State<PromptInputComplete> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _currentModel {
    return widget.modelId ??
        (widget.models?.firstOrDefault() ?? 'openai/gpt-4o-mini');
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && widget.status != ChatStatus.submitting) {
      widget.onSubmit?.call(text, _currentModel);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PromptInput(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PromptInputTextarea(
            controller: _controller,
            placeholder: widget.placeholder,
            minHeight: widget.minHeight,
            maxHeight: widget.maxHeight,
            onChanged: (_) => setState(() {}),
            onSubmit: _handleSubmit,
          ),
          PromptInputToolbar(
            child: Row(
              children: [
                PromptInputTools(
                  children: [
                    PromptInputButton(
                      tooltip: 'Add attachment',
                      onPressed: widget.onAddAttachment,
                      child: const Icon(LucideIcons.plus, size: 16),
                    ),
                    const SizedBox(width: 6),
                    PromptInputModelSelect(
                      value: _currentModel,
                      models: widget.models ?? AppConfig.availableModels,
                      onChanged: widget.onModelChanged,
                    ),
                  ],
                ),
                const Spacer(),
                PromptInputSubmit(
                  status: widget.status,
                  enabled: _controller.text.trim().isNotEmpty,
                  onSubmit: _handleSubmit,
                  onStop: widget.onStop,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on List<String> {
  String? firstOrDefault() => isEmpty ? null : first;
}
