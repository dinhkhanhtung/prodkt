class Product {
  final int? id;
  final String name;
  final String normalizedName;
  final String? code;
  final int quantity;
  final double sellPrice;
  final double costPrice;
  final String? imagePath;
  final DateTime entryDate;
  final int? warehouseId;
  final Map<String, dynamic>? attributes;
  final String? unit;

  Product({
    this.id,
    required this.name,
    required this.normalizedName,
    this.code,
    required this.quantity,
    required this.sellPrice,
    required this.costPrice,
    this.imagePath,
    required this.entryDate,
    this.warehouseId,
    this.attributes,
    this.unit,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name']?.toString() ?? '',
      normalizedName: map['normalized_name']?.toString() ?? '',
      code: map['code']?.toString(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      sellPrice: (map['sell_price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      imagePath: map['image_path']?.toString(),
      entryDate: map['entry_date'] != null
          ? DateTime.parse(map['entry_date'] as String)
          : DateTime.now(),
      warehouseId: map['warehouse_id'] as int?,
      attributes: map['attributes'] != null
          ? Map<String, dynamic>.from(map['attributes'])
          : null,
      unit: map['unit']?.toString() ?? 'cái',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'normalized_name': normalizedName,
      'code': code,
      'quantity': quantity,
      'sell_price': sellPrice,
      'cost_price': costPrice,
      'image_path': imagePath,
      'entry_date': entryDate.toIso8601String(),
      'warehouse_id': warehouseId,
      'unit': unit,
    };
  }

  bool get needsWarning {
    if (attributes == null) return false;

    final now = DateTime.now();
    final daysSinceEntry = now.difference(entryDate).inDays;

    if (daysSinceEntry > 30) return true;

    final expiryDate = attributes!['Hạn sử dụng'];
    if (expiryDate != null) {
      final expiry = DateTime.parse(expiryDate);
      final daysUntilExpiry = expiry.difference(now).inDays;
      return daysUntilExpiry < 7;
    }

    return false;
  }

  Product copyWith({
    int? id,
    String? name,
    String? normalizedName,
    String? code,
    int? quantity,
    double? sellPrice,
    double? costPrice,
    String? imagePath,
    DateTime? entryDate,
    int? warehouseId,
    Map<String, dynamic>? attributes,
    String? unit,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      code: code ?? this.code,
      quantity: quantity ?? this.quantity,
      sellPrice: sellPrice ?? this.sellPrice,
      costPrice: costPrice ?? this.costPrice,
      imagePath: imagePath ?? this.imagePath,
      entryDate: entryDate ?? this.entryDate,
      warehouseId: warehouseId ?? this.warehouseId,
      attributes: attributes ?? this.attributes,
      unit: unit ?? this.unit,
    );
  }
}
