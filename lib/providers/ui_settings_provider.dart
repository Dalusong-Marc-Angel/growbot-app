// lib/providers/ui_settings_provider.dart
import 'package:flutter/material.dart';

// Enum for Card GUI sizes
enum CardScale {
  small('Small'),
  medium('Medium'),
  large('Large');

  const CardScale(this.label);
  final String label;
}

class UISettingsProvider with ChangeNotifier {
  // Card Scale State
  CardScale _cardScale = CardScale.medium;
  CardScale get cardScale => _cardScale;

  // Numeric multiplier getter for UI scaling
  double get scaleFactor {
    switch (_cardScale) {
      case CardScale.small:
        return 0.85;
      case CardScale.medium:
        return 1.0;
      case CardScale.large:
        return 1.2;
    }
  }

  void setCardScale(CardScale scale) {
    _cardScale = scale;
    notifyListeners();
  }

  // Theme Mode State
  ThemeMode _themeMode = ThemeMode.system; 
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    
    notifyListeners();
  }
}