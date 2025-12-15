class AppSettings {
  final int fontSizeLevel; // 1..5
  final int themeId; // 1..5
  final bool autoScrollEnabled;
  final double autoScrollSpeed; // 0.5..2.0, multiplier

  const AppSettings({
    this.fontSizeLevel = 3,
    this.themeId = 1,
    this.autoScrollEnabled = true,
    this.autoScrollSpeed = 1.0,
  });

  AppSettings copyWith({
    int? fontSizeLevel,
    int? themeId,
    bool? autoScrollEnabled,
    double? autoScrollSpeed,
  }) {
    return AppSettings(
      fontSizeLevel: fontSizeLevel ?? this.fontSizeLevel,
      themeId: themeId ?? this.themeId,
      autoScrollEnabled: autoScrollEnabled ?? this.autoScrollEnabled,
      autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
    );
  }
}


