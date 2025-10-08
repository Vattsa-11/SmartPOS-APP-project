import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;
  double discount; // Percentage discount (0-100)

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discount = 0.0,
  });

  double get unitPrice => product.price;
  
  double get totalPrice => (product.price * quantity) * (1 - discount / 100);

  CartItem copyWith({
    Product? product,
    int? quantity,
    double? discount,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'product_id': product.id,
      'product_name': product.name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'total_price': totalPrice,
    };
  }
}
