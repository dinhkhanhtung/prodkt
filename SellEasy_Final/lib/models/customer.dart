import '../services/database_helper.dart';

class Customer {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String normalizedName;
  double? _cachedDebt;
  int? _cachedOrderCount;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    required this.normalizedName,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString(),
      email: map['email']?.toString(),
      address: map['address']?.toString(),
      normalizedName: map['normalized_name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'normalized_name': normalizedName,
    };
  }

  Future<double> getDebt() async {
    if (_cachedDebt != null) return _cachedDebt!;

    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT SUM(debt) as total_debt 
      FROM orders 
      WHERE customer_id = ? AND status != 'Nháp'
    ''', [id]);

    _cachedDebt = (result.first['total_debt'] as num?)?.toDouble() ?? 0.0;
    return _cachedDebt!;
  }

  Future<int> getOrderCount() async {
    if (_cachedOrderCount != null) return _cachedOrderCount!;

    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as total_orders 
      FROM orders 
      WHERE customer_id = ? AND status != 'Nháp'
    ''', [id]);

    _cachedOrderCount = (result.first['total_orders'] as num?)?.toInt() ?? 0;
    return _cachedOrderCount!;
  }

  void clearCache() {
    _cachedDebt = null;
    _cachedOrderCount = null;
  }
}
