import 'dart:convert';

class OrderItem {
  final int? id;
  final int? orderId;
  final int? productId;
  final String name;
  final int quantity;
  final double price;
  final double costPrice;
  final Map<String, dynamic>? attributes;

  OrderItem({
    this.id,
    this.orderId,
    this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.costPrice,
    this.attributes,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int?,
      orderId: map['order_id'] as int?,
      productId: map['product_id'] as int?,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      price: map['price'] as double,
      costPrice: map['cost_price'] as double,
      attributes: map['attributes'] != null
          ? Map<String, dynamic>.from(json.decode(map['attributes'] as String))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'cost_price': costPrice,
      'attributes': attributes != null ? json.encode(attributes) : null,
    };
  }

  double get total => quantity * price;

  OrderItem copyWith({
    int? id,
    int? orderId,
    int? productId,
    String? name,
    int? quantity,
    double? price,
    double? costPrice,
    Map<String, dynamic>? attributes,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      attributes: attributes ?? this.attributes,
    );
  }
}
