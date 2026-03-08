import 'package:flutter/material.dart';

/// **ThemeProvider** - Manages theme state and user theme preferences
///
/// Provides a simple, user-friendly theme switching system with three modes:
/// System, Light, and Dark. Integrates with Material Design 3 and follows
/// platform conventions for theme persistence and switching.
///
/// ## Theme Flow:
/// ```
/// System → Light → Dark → System (cycles on toggle)
/// ```
///
/// ## Integration Points:
/// - Connected to `MaterialApp.themeMode` in main.dart
/// - UI toggle button cycles through all three modes
/// - Respects system theme changes in System mode
/// - Theme definitions in `theme.dart` (custom color scheme)
///
/// ## State Management:
/// - Uses `ChangeNotifier` for reactive UI updates
/// - State persists only during app session (extend for permanent storage)
/// - Triggers immediate UI redraws on theme changes
///
/// ## Extension Examples:
/// ```dart
/// // Add persistence:
/// class PersistentThemeProvider extends ThemeProvider {
///   late final SharedPreferences _prefs;
///
///   @override
///   ThemeMode get themeMode => ThemeMode.values[_prefs.getInt('theme') ?? 0];
///
///   @override
///   void setThemeMode(ThemeMode mode) {
///     super.setThemeMode(mode);
///     _prefs.setInt('theme', mode.index);
///   }
/// }
///
/// // Add custom themes:
/// class ExtendedThemeProvider extends ThemeProvider {
///   final Map<String, ThemeData> customThemes;
///   String _selectedTheme = 'default';
/// }
/// ```
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider({
    ThemeMode themeMode = ThemeMode.system,
  }) : _themeMode = themeMode;

  /// Current theme mode - drives MaterialApp.themeMode
  ThemeMode get themeMode => _themeMode;

  /// Cycles through theme modes: System → Light → Dark → System
  ///
  /// Called by the theme toggle button in the chat header.
  /// Provides a smooth user experience for theme switching without
  /// requiring separate controls for each mode.
  void toggleThemeMode() {
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }

  /// Directly sets the theme mode to a specific value
  ///
  /// **Parameters:**
  /// - `themeMode`: Target theme mode
  ///
  /// **Usage:**
  /// ```dart
  /// // Set specific theme:
  /// themeProvider.setThemeMode(ThemeMode.dark);
  ///
  /// // Conditionally set theme:
  /// if (userPrefersDark) {
  ///   themeProvider.setThemeMode(ThemeMode.dark);
  /// }
  /// ```
  void setThemeMode(ThemeMode themeMode) {
    if (_themeMode != themeMode) {
      _themeMode = themeMode;
      notifyListeners();
    }
  }

  // Legacy compatibility methods
  @Deprecated('Use themeMode instead')
  Brightness get brightness {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  @Deprecated('Use toggleThemeMode instead')
  void toggleBrightness() => toggleThemeMode();

  @Deprecated('Use setThemeMode instead')
  void setBrightness(Brightness brightness) {
    setThemeMode(
      brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
