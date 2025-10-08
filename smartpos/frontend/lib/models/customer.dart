class Customer {
  final int? id;
  final String name;
  final String phone;
  final int? userId;
  final String? createdAt;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.userId,
    this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      userId: json['user_id'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}
