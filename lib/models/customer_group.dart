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

  factory CustomerGroup.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
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
    '#E8488A', // 대표 핑크
    '#FF6FA8', // 라이트 핑크
    '#D93D7B', // 체리 핑크
    '#FF8A73', // 코랄
    '#FF9D5C', // 웜 오렌지
    '#2EB47D', // 민트
    '#FF9AC4', // 소프트 핑크
    '#8E8295', // 뉴트럴 보라그레이
  ];
}
