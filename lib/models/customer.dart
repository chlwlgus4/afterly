class Customer {
  final int? id;
  final String name;
  final DateTime createdAt;
  final DateTime? lastShootingAt;

  Customer({
    this.id,
    required this.name,
    DateTime? createdAt,
    this.lastShootingAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'lastShootingAt': lastShootingAt?.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastShootingAt: map['lastShootingAt'] != null
          ? DateTime.parse(map['lastShootingAt'] as String)
          : null,
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastShootingAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastShootingAt: lastShootingAt ?? this.lastShootingAt,
    );
  }
}
