class Customer {
  final int? id;
  final String name;
  final String normalizedName;
  final String? phone;
  final String? email;
  final String? address;
  final double debt;
  final String createdAt;

  Customer({
    this.id,
    required this.name,
    required this.normalizedName,
    this.phone,
    this.email,
    this.address,
    this.debt = 0.0,
    required this.createdAt,
  });

  // Create a Customer from a Map
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      normalizedName: map['normalized_name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      debt: map['debt'] ?? 0.0,
      createdAt: map['created_at'],
    );
  }

  // Convert a Customer to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'normalized_name': normalizedName,
      'phone': phone,
      'email': email,
      'address': address,
      'debt': debt,
      'created_at': createdAt,
    };
  }

  // Create a copy of Customer with some fields changed
  Customer copyWith({
    int? id,
    String? name,
    String? normalizedName,
    String? phone,
    String? email,
    String? address,
    double? debt,
    String? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      debt: debt ?? this.debt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Customer{id: $id, name: $name, phone: $phone, debt: $debt}';
  }
}
