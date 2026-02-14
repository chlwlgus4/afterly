class Customer {
  final String? id; // Firestore document ID
  final String userId; // Firebase Auth user ID
  final String name;
  final DateTime createdAt;
  final DateTime? lastShootingAt;

  Customer({
    this.id,
    required this.userId,
    required this.name,
    DateTime? createdAt,
    this.lastShootingAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'lastShootingAt': lastShootingAt?.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return Customer(
      id: documentId,
      userId: map['userId'] as String,
      name: map['name'] as String,
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
    DateTime? createdAt,
    DateTime? lastShootingAt,
  }) {
    return Customer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastShootingAt: lastShootingAt ?? this.lastShootingAt,
    );
  }
}
