class Product {
  final int? id;
  final String name;
  final String barcode;
  final double price;
  final double? sellingPrice;
  final double? costPrice;
  final int? currentStock;
  final int? minimumStock;
  final String unit;
  final double discountPercentage;
  final double taxPercentage;
  final bool isFeatured;
  final String? category;
  final int? userId;
  final String? createdAt;
  final String? updatedAt;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.price,
    this.sellingPrice,
    this.costPrice,
    this.currentStock,
    this.minimumStock,
    this.unit = 'pcs',
    this.discountPercentage = 0.0,
    this.taxPercentage = 0.0,
    this.isFeatured = false,
    this.category,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      name: json['name'] ?? '',
      barcode: json['barcode'] ?? '',
      price: _parseDouble(json['price']),
      sellingPrice: _parseDouble(json['selling_price']),
      costPrice: _parseDouble(json['cost_price']),
      currentStock: json['current_stock'] is String ? int.tryParse(json['current_stock']) : json['current_stock'],
      minimumStock: json['minimum_stock'] is String ? int.tryParse(json['minimum_stock']) : json['minimum_stock'],
      unit: json['unit'] ?? 'pcs',
      discountPercentage: _parseDouble(json['discount_percentage']),
      taxPercentage: _parseDouble(json['tax_percentage']),
      isFeatured: json['is_featured'] ?? false,
      category: json['category'],
      userId: json['user_id'] is String ? int.tryParse(json['user_id']) : json['user_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'barcode': barcode,
      'price': price,
      'selling_price': sellingPrice ?? price,
      'cost_price': costPrice ?? 0.0,
      'initial_stock': currentStock ?? 0,
      'minimum_stock': minimumStock ?? 0,
      'unit': unit,
      'discount_percentage': discountPercentage,
      'tax_percentage': taxPercentage,
      'is_featured': isFeatured,
      if (category != null) 'category': category,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    double? price,
    double? sellingPrice,
    double? costPrice,
    int? currentStock,
    int? minimumStock,
    String? unit,
    double? discountPercentage,
    double? taxPercentage,
    bool? isFeatured,
    String? category,
    int? userId,
    String? createdAt,
    String? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      unit: unit ?? this.unit,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      isFeatured: isFeatured ?? this.isFeatured,
      category: category ?? this.category,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
