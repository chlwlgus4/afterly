class ShootingSession {
  final String? id; // Firestore document ID
  final String userId; // Firebase Auth user ID
  final String customerId; // Customer document ID
  final String? beforeImageUrl; // Changed from path to URL (Firebase Storage)
  final String? afterImageUrl; // Changed from path to URL (Firebase Storage)
  final String? alignedBeforeUrl; // Changed from path to URL
  final String? alignedAfterUrl; // Changed from path to URL
  final double? jawlineScore;
  final double? symmetryScore;
  final double? skinToneScore;
  final double? eyebrowScore;
  final String? summary;
  final DateTime createdAt;

  ShootingSession({
    this.id,
    required this.userId,
    required this.customerId,
    this.beforeImageUrl,
    this.afterImageUrl,
    this.alignedBeforeUrl,
    this.alignedAfterUrl,
    this.jawlineScore,
    this.symmetryScore,
    this.skinToneScore,
    this.eyebrowScore,
    this.summary,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'customerId': customerId,
      'beforeImageUrl': beforeImageUrl,
      'afterImageUrl': afterImageUrl,
      'alignedBeforeUrl': alignedBeforeUrl,
      'alignedAfterUrl': alignedAfterUrl,
      'jawlineScore': jawlineScore,
      'symmetryScore': symmetryScore,
      'skinToneScore': skinToneScore,
      'eyebrowScore': eyebrowScore,
      'summary': summary,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ShootingSession.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return ShootingSession(
      id: documentId,
      userId: map['userId'] as String,
      customerId: map['customerId'] as String,
      beforeImageUrl: map['beforeImageUrl'] as String?,
      afterImageUrl: map['afterImageUrl'] as String?,
      alignedBeforeUrl: map['alignedBeforeUrl'] as String?,
      alignedAfterUrl: map['alignedAfterUrl'] as String?,
      jawlineScore: (map['jawlineScore'] as num?)?.toDouble(),
      symmetryScore: (map['symmetryScore'] as num?)?.toDouble(),
      skinToneScore: (map['skinToneScore'] as num?)?.toDouble(),
      eyebrowScore: (map['eyebrowScore'] as num?)?.toDouble(),
      summary: map['summary'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  ShootingSession copyWith({
    String? id,
    String? userId,
    String? customerId,
    String? beforeImageUrl,
    String? afterImageUrl,
    String? alignedBeforeUrl,
    String? alignedAfterUrl,
    double? jawlineScore,
    double? symmetryScore,
    double? skinToneScore,
    double? eyebrowScore,
    String? summary,
    DateTime? createdAt,
  }) {
    return ShootingSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      beforeImageUrl: beforeImageUrl ?? this.beforeImageUrl,
      afterImageUrl: afterImageUrl ?? this.afterImageUrl,
      alignedBeforeUrl: alignedBeforeUrl ?? this.alignedBeforeUrl,
      alignedAfterUrl: alignedAfterUrl ?? this.alignedAfterUrl,
      jawlineScore: jawlineScore ?? this.jawlineScore,
      symmetryScore: symmetryScore ?? this.symmetryScore,
      skinToneScore: skinToneScore ?? this.skinToneScore,
      eyebrowScore: eyebrowScore ?? this.eyebrowScore,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get hasBeforeImage => beforeImageUrl != null;
  bool get hasAfterImage => afterImageUrl != null;
  bool get isComplete => hasBeforeImage && hasAfterImage;
  bool get hasAnalysis => jawlineScore != null;
}
