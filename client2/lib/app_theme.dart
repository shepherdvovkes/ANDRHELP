import 'package:flutter/material.dart';

ThemeData _baseTheme(Brightness brightness) =>
    ThemeData(brightness: brightness, useMaterial3: true);

ThemeData themeById(int id) {
  switch (id) {
    case 2:
      return _baseTheme(Brightness.dark).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      );
    case 3:
      return _baseTheme(Brightness.light).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      );
    case 4:
      return _baseTheme(Brightness.dark).copyWith(
        colorScheme: ColorScheme.highContrastDark(),
      );
    case 5:
      return _baseTheme(Brightness.light).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
      );
    case 1:
    default:
      return _baseTheme(Brightness.light).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      );
  }
}


