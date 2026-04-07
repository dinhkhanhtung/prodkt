import 'order_item_model.dart';
import 'customer_model.dart';

class Order {
  final int? id;
  final String date;
  final int? customerId;
  final Customer? customer;
  final double total;
  final double paid;
  final double debt;
  final String status;
  final String category;
  final double taxPercent;
  final double discountPercent;
  final double discountAmount;
  final double shippingFee;
  final double additionalFee;
  final String? additionalFeeDescription;
  final double refundAmount;
  final String? refundDate;
  final String? refundReason;
  final String? note;
  final List<OrderItem>? items;

  Order({
    this.id,
    required this.date,
    this.customerId,
    this.customer,
    required this.total,
    required this.paid,
    required this.debt,
    required this.status,
    this.category = 'Bán lẻ',
    this.taxPercent = 0.0,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.shippingFee = 0.0,
    this.additionalFee = 0.0,
    this.additionalFeeDescription,
    this.refundAmount = 0.0,
    this.refundDate,
    this.refundReason,
    this.note,
    this.items,
  });

  // Create an Order from a Map
  factory Order.fromMap(Map<String, dynamic> map, {Customer? customer, List<OrderItem>? items}) {
    return Order(
      id: map['id'],
      date: map['date'],
      customerId: map['customer_id'],
      customer: customer,
      total: map['total'],
      paid: map['paid'],
      debt: map['debt'],
      status: map['status'],
      category: map['category'] ?? 'Bán lẻ',
      taxPercent: map['tax_percent'] ?? 0.0,
      discountPercent: map['discount_percent'] ?? 0.0,
      discountAmount: map['discount_amount'] ?? 0.0,
      shippingFee: map['shipping_fee'] ?? 0.0,
      additionalFee: map['additional_fee'] ?? 0.0,
      additionalFeeDescription: map['additional_fee_description'],
      refundAmount: map['refund_amount'] ?? 0.0,
      refundDate: map['refund_date'],
      refundReason: map['refund_reason'],
      note: map['note'],
      items: items,
    );
  }

  // Convert an Order to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'customer_id': customerId,
      'total': total,
      'paid': paid,
      'debt': debt,
      'status': status,
      'category': category,
      'tax_percent': taxPercent,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'shipping_fee': shippingFee,
      'additional_fee': additionalFee,
      'additional_fee_description': additionalFeeDescription,
      'refund_amount': refundAmount,
      'refund_date': refundDate,
      'refund_reason': refundReason,
      'note': note,
    };
  }

  // Create a copy of Order with some fields changed
  Order copyWith({
    int? id,
    String? date,
    int? customerId,
    Customer? customer,
    double? total,
    double? paid,
    double? debt,
    String? status,
    String? category,
    double? taxPercent,
    double? discountPercent,
    double? discountAmount,
    double? shippingFee,
    double? additionalFee,
    String? additionalFeeDescription,
    double? refundAmount,
    String? refundDate,
    String? refundReason,
    String? note,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      date: date ?? this.date,
      customerId: customerId ?? this.customerId,
      customer: customer ?? this.customer,
      total: total ?? this.total,
      paid: paid ?? this.paid,
      debt: debt ?? this.debt,
      status: status ?? this.status,
      category: category ?? this.category,
      taxPercent: taxPercent ?? this.taxPercent,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      shippingFee: shippingFee ?? this.shippingFee,
      additionalFee: additionalFee ?? this.additionalFee,
      additionalFeeDescription: additionalFeeDescription ?? this.additionalFeeDescription,
      refundAmount: refundAmount ?? this.refundAmount,
      refundDate: refundDate ?? this.refundDate,
      refundReason: refundReason ?? this.refundReason,
      note: note ?? this.note,
      items: items ?? this.items,
    );
  }

  // Calculate subtotal (before tax, discount, shipping, etc.)
  double getSubtotal() {
    if (items == null || items!.isEmpty) {
      return total - shippingFee - additionalFee + discountAmount;
    }
    
    return items!.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Calculate total items
  int getTotalItems() {
    if (items == null || items!.isEmpty) {
      return 0;
    }
    
    return items!.fold(0, (sum, item) => sum + item.quantity);
  }

  // Calculate total cost
  double getTotalCost() {
    if (items == null || items!.isEmpty) {
      return 0.0;
    }
    
    return items!.fold(0.0, (sum, item) => sum + (item.cost * item.quantity));
  }

  // Calculate profit
  double getProfit() {
    return total - getTotalCost() - shippingFee - additionalFee;
  }

  // Calculate profit margin
  double getProfitMargin() {
    if (total == 0) return 0;
    return (getProfit() / total) * 100;
  }

  @override
  String toString() {
    return 'Order{id: $id, date: $date, total: $total, status: $status}';
  }
}
