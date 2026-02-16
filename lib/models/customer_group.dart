class CustomerGroup {
  final String? id; // Firestore document ID
  final String userId; // Firebase Auth user ID
  final String name;
  final String? color; // 색상 코드 (예: '#FF5733')
  final int order; // 정렬 순서
  final DateTime createdAt;

  CustomerGroup({
    this.id,
    required this.userId,
    required this.name,
    this.color,
    this.order = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'color': color,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomerGroup.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return CustomerGroup(
      id: documentId,
      userId: map['userId'] as String,
      name: map['name'] as String,
      color: map['color'] as String?,
      order: map['order'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  CustomerGroup copyWith({
    String? id,
    String? userId,
    String? name,
    String? color,
    int? order,
    DateTime? createdAt,
    bool clearColor = false,
  }) {
    return CustomerGroup(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: clearColor ? null : (color ?? this.color),
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// 기본 그룹 색상
class GroupColors {
  static const List<String> defaultColors = [
    '#6C63FF', // 보라
    '#FF6B6B', // 빨강
    '#4ECDC4', // 청록
    '#FFE66D', // 노랑
    '#95E1D3', // 민트
    '#F38181', // 분홍
    '#AA96DA', // 연보라
    '#FCBAD3', // 연분홍
  ];
}
