class Customer {
  final String? id; // Firestore document ID
  final String userId; // Firebase Auth user ID
  final String name;
  final String? group; // 고객 그룹 (예: VIP, 일반, 신규 등)
  final String? memo; // 메모
  final DateTime createdAt;
  final DateTime? lastShootingAt;

  Customer({
    this.id,
    required this.userId,
    required this.name,
    this.group,
    this.memo,
    DateTime? createdAt,
    this.lastShootingAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'group': group,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
      'lastShootingAt': lastShootingAt?.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return Customer(
      id: documentId,
      userId: map['userId'] as String,
      name: map['name'] as String,
      group: map['group'] as String?,
      memo: map['memo'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastShootingAt: map['lastShootingAt'] != null
          ? DateTime.parse(map['lastShootingAt'] as String)
          : null,
    );
  }

  Customer copyWith({
    String? id,
    String? userId,
    String? name,
    String? group,
    String? memo,
    DateTime? createdAt,
    DateTime? lastShootingAt,
    bool clearGroup = false,
    bool clearMemo = false,
  }) {
    return Customer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      group: clearGroup ? null : (group ?? this.group),
      memo: clearMemo ? null : (memo ?? this.memo),
      createdAt: createdAt ?? this.createdAt,
      lastShootingAt: lastShootingAt ?? this.lastShootingAt,
    );
  }
}

// 기본 그룹 목록
class CustomerGroups {
  static const List<String> defaultGroups = [
    'VIP',
    '일반',
    '신규',
    '휴면',
  ];
}
