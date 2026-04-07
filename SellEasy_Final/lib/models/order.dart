class Order {
  final int? id;
  final DateTime date;
  final int? customerId;
  final double total;
  final double paid;
  final double debt;
  final String status;
  final double taxPercent;
  final double discountPercent;
  final double discountAmount;
  final double shippingFee;
  final String category;

  Order({
    this.id,
    required this.date,
    this.customerId,
    required this.total,
    required this.paid,
    required this.debt,
    required this.status,
    this.taxPercent = 0,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.shippingFee = 0,
    this.category = 'Bán lẻ',
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      customerId: map['customer_id'] as int?,
      total: map['total'] as double,
      paid: map['paid'] as double,
      debt: map['debt'] as double,
      status: map['status'] as String,
      taxPercent: map['tax_percent'] as double? ?? 0,
      discountPercent: map['discount_percent'] as double? ?? 0,
      discountAmount: map['discount_amount'] as double? ?? 0,
      shippingFee: map['shipping_fee'] as double? ?? 0,
      category: map['category'] as String? ?? 'Bán lẻ',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'customer_id': customerId,
      'total': total,
      'paid': paid,
      'debt': debt,
      'status': status,
      'tax_percent': taxPercent,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'shipping_fee': shippingFee,
      'category': category,
    };
  }

  Order copyWith({
    int? id,
    DateTime? date,
    int? customerId,
    double? total,
    double? paid,
    double? debt,
    String? status,
    double? taxPercent,
    double? discountPercent,
    double? discountAmount,
    double? shippingFee,
    String? category,
  }) {
    return Order(
      id: id ?? this.id,
      date: date ?? this.date,
      customerId: customerId ?? this.customerId,
      total: total ?? this.total,
      paid: paid ?? this.paid,
      debt: debt ?? this.debt,
      status: status ?? this.status,
      taxPercent: taxPercent ?? this.taxPercent,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      shippingFee: shippingFee ?? this.shippingFee,
      category: category ?? this.category,
    );
  }
}
