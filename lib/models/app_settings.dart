class AppSettings {
  final bool notificationsEnabled;
  final ThemeMode themeMode;
  final String language;

  const AppSettings({
    this.notificationsEnabled = true,
    this.themeMode = ThemeMode.light,
    this.language = 'ko',
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    ThemeMode? themeMode,
    String? language,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'themeMode': themeMode.index,
      'language': language,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      themeMode: ThemeMode.values[json['themeMode'] ?? 0],
      language: json['language'] ?? 'ko',
    );
  }
}

enum ThemeMode {
  light,
  dark,
  system,
}
