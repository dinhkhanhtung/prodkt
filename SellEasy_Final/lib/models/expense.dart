class Expense {
  final int? id;
  final DateTime date;
  final String? description;
  final double amount;
  final String category;
  final int? productId;
  final int? quantity;
  final int? warehouseId;

  Expense({
    this.id,
    required this.date,
    this.description,
    required this.amount,
    required this.category,
    this.productId,
    this.quantity,
    this.warehouseId,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String?,
      amount: map['amount'] as double,
      category: map['category'] as String,
      productId: map['product_id'] as int?,
      quantity: map['quantity'] as int?,
      warehouseId: map['warehouse_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'description': description,
      'amount': amount,
      'category': category,
      'product_id': productId,
      'quantity': quantity,
      'warehouse_id': warehouseId,
    };
  }
}
