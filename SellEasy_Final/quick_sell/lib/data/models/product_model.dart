class Product {
  final int? id;
  final String name;
  final String normalizedName;
  final String? code;
  final int quantity;
  final double sellPrice;
  final double costPrice;
  final String? imagePath;
  final String entryDate;
  final bool isTemporary;
  final String unit;
  final Map<String, dynamic>? attributes;

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
    this.isTemporary = false,
    this.unit = 'cái',
    this.attributes,
  });

  // Create a Product from a Map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      normalizedName: map['normalized_name'],
      code: map['code'],
      quantity: map['quantity'],
      sellPrice: map['sell_price'],
      costPrice: map['cost_price'],
      imagePath: map['image_path'],
      entryDate: map['entry_date'],
      isTemporary: map['is_temporary'] == 1,
      unit: map['unit'] ?? 'cái',
      attributes: map['attributes'] != null
          ? Map<String, dynamic>.from(
              map['attributes'] is String
                  ? Map<String, dynamic>.from(
                      Map<String, dynamic>.from(
                        map['attributes'],
                      ),
                    )
                  : map['attributes'],
            )
          : null,
    );
  }

  // Convert a Product to a Map
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
      'entry_date': entryDate,
      'is_temporary': isTemporary ? 1 : 0,
      'unit': unit,
      'attributes': attributes != null ? attributes.toString() : null,
    };
  }

  // Create a copy of Product with some fields changed
  Product copyWith({
    int? id,
    String? name,
    String? normalizedName,
    String? code,
    int? quantity,
    double? sellPrice,
    double? costPrice,
    String? imagePath,
    String? entryDate,
    bool? isTemporary,
    String? unit,
    Map<String, dynamic>? attributes,
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
      isTemporary: isTemporary ?? this.isTemporary,
      unit: unit ?? this.unit,
      attributes: attributes ?? this.attributes,
    );
  }

  // Get product status
  String getStatus() {
    if (quantity <= 0) {
      return 'out_of_stock';
    } else if (quantity <= 5) {
      return 'low_stock';
    } else {
      return 'in_stock';
    }
  }

  // Calculate profit
  double getProfit() {
    return sellPrice - costPrice;
  }

  // Calculate profit margin
  double getProfitMargin() {
    if (sellPrice == 0) return 0;
    return (getProfit() / sellPrice) * 100;
  }

  @override
  String toString() {
    return 'Product{id: $id, name: $name, quantity: $quantity, sellPrice: $sellPrice}';
  }
}
