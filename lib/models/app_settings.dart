class AppSettings {
  final bool notificationsEnabled;
  final ThemeMode themeMode;
  final String language;
  final bool comparisonGuideSeen;

  const AppSettings({
    this.notificationsEnabled = true,
    this.themeMode = ThemeMode.light,
    this.language = 'ko',
    this.comparisonGuideSeen = false,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    ThemeMode? themeMode,
    String? language,
    bool? comparisonGuideSeen,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      comparisonGuideSeen: comparisonGuideSeen ?? this.comparisonGuideSeen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'themeMode': themeMode.index,
      'language': language,
      'comparisonGuideSeen': comparisonGuideSeen,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      themeMode: ThemeMode.values[json['themeMode'] ?? 0],
      language: json['language'] ?? 'ko',
      comparisonGuideSeen: json['comparisonGuideSeen'] ?? false,
    );
  }
}

enum ThemeMode {
  light,
  dark,
  system,
}
