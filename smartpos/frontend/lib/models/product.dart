class Product {
  final int? id;
  final String name;
  final String barcode;
  final double price;
  final String category;
  final int? userId;
  final String? createdAt;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.category,
    this.userId,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      barcode: json['barcode'],
      price: json['price'].toDouble(),
      category: json['category'],
      userId: json['user_id'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'barcode': barcode,
      'price': price,
      'category': category,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    double? price,
    String? category,
    int? userId,
    String? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      category: category ?? this.category,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
