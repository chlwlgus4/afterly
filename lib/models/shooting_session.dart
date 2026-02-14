class ShootingSession {
  final int? id;
  final int customerId;
  final String? beforeImagePath;
  final String? afterImagePath;
  final String? alignedBeforePath;
  final String? alignedAfterPath;
  final double? jawlineScore;
  final double? symmetryScore;
  final double? skinToneScore;
  final String? summary;
  final DateTime createdAt;

  ShootingSession({
    this.id,
    required this.customerId,
    this.beforeImagePath,
    this.afterImagePath,
    this.alignedBeforePath,
    this.alignedAfterPath,
    this.jawlineScore,
    this.symmetryScore,
    this.skinToneScore,
    this.summary,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customerId': customerId,
      'beforeImagePath': beforeImagePath,
      'afterImagePath': afterImagePath,
      'alignedBeforePath': alignedBeforePath,
      'alignedAfterPath': alignedAfterPath,
      'jawlineScore': jawlineScore,
      'symmetryScore': symmetryScore,
      'skinToneScore': skinToneScore,
      'summary': summary,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ShootingSession.fromMap(Map<String, dynamic> map) {
    return ShootingSession(
      id: map['id'] as int?,
      customerId: map['customerId'] as int,
      beforeImagePath: map['beforeImagePath'] as String?,
      afterImagePath: map['afterImagePath'] as String?,
      alignedBeforePath: map['alignedBeforePath'] as String?,
      alignedAfterPath: map['alignedAfterPath'] as String?,
      jawlineScore: (map['jawlineScore'] as num?)?.toDouble(),
      symmetryScore: (map['symmetryScore'] as num?)?.toDouble(),
      skinToneScore: (map['skinToneScore'] as num?)?.toDouble(),
      summary: map['summary'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  ShootingSession copyWith({
    int? id,
    int? customerId,
    String? beforeImagePath,
    String? afterImagePath,
    String? alignedBeforePath,
    String? alignedAfterPath,
    double? jawlineScore,
    double? symmetryScore,
    double? skinToneScore,
    String? summary,
    DateTime? createdAt,
  }) {
    return ShootingSession(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      beforeImagePath: beforeImagePath ?? this.beforeImagePath,
      afterImagePath: afterImagePath ?? this.afterImagePath,
      alignedBeforePath: alignedBeforePath ?? this.alignedBeforePath,
      alignedAfterPath: alignedAfterPath ?? this.alignedAfterPath,
      jawlineScore: jawlineScore ?? this.jawlineScore,
      symmetryScore: symmetryScore ?? this.symmetryScore,
      skinToneScore: skinToneScore ?? this.skinToneScore,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get hasBeforeImage => beforeImagePath != null;
  bool get hasAfterImage => afterImagePath != null;
  bool get isComplete => hasBeforeImage && hasAfterImage;
  bool get hasAnalysis => jawlineScore != null;
}
