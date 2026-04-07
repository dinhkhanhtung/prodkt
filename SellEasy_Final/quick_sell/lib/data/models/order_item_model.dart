import 'product_model.dart';

class OrderItem {
  final int? id;
  final int orderId;
  final int productId;
  final Product? product;
  final int quantity;
  final double price;
  final double cost;
  final bool isExchanged;

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    this.product,
    required this.quantity,
    required this.price,
    required this.cost,
    this.isExchanged = false,
  });

  // Create an OrderItem from a Map
  factory OrderItem.fromMap(Map<String, dynamic> map, {Product? product}) {
    return OrderItem(
      id: map['id'],
      orderId: map['order_id'],
      productId: map['product_id'],
      product: product,
      quantity: map['quantity'],
      price: map['price'],
      cost: map['cost'] ?? 0.0,
      isExchanged: map['is_exchanged'] == 1,
    );
  }

  // Convert an OrderItem to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'cost': cost,
      'is_exchanged': isExchanged ? 1 : 0,
    };
  }

  // Create a copy of OrderItem with some fields changed
  OrderItem copyWith({
    int? id,
    int? orderId,
    int? productId,
    Product? product,
    int? quantity,
    double? price,
    double? cost,
    bool? isExchanged,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      isExchanged: isExchanged ?? this.isExchanged,
    );
  }

  // Calculate total price
  double getTotalPrice() {
    return price * quantity;
  }

  // Calculate total cost
  double getTotalCost() {
    return cost * quantity;
  }

  // Calculate profit
  double getProfit() {
    return getTotalPrice() - getTotalCost();
  }

  // Calculate profit margin
  double getProfitMargin() {
    if (price == 0) return 0;
    return ((price - cost) / price) * 100;
  }

  @override
  String toString() {
    return 'OrderItem{id: $id, productId: $productId, quantity: $quantity, price: $price}';
  }
}
