class User {
  final String? id;
  final String email;
  final String ownerName;
  final String phone;
  // Shop info is now separate - these are for compatibility/current selection
  final String? currentShopId;
  final String? currentShopName;

  User({
    this.id,
    required this.email,
    required this.ownerName,
    required this.phone,
    this.currentShopId,
    this.currentShopName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      email: json['email'] ?? '',
      ownerName: json['owner_name'] ?? '',
      phone: json['phone'] ?? '',
      currentShopId: json['current_shop_id']?.toString(),
      currentShopName: json['current_shop_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'owner_name': ownerName,
      'phone': phone,
      'current_shop_id': currentShopId,
      'current_shop_name': currentShopName,
    };
  }

  // Backward compatibility - use currentShopName if available
  String get shopName => currentShopName ?? '';

  User copyWith({
    String? id,
    String? email,
    String? ownerName,
    String? phone,
    String? currentShopId,
    String? currentShopName,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      currentShopId: currentShopId ?? this.currentShopId,
      currentShopName: currentShopName ?? this.currentShopName,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, ownerName: $ownerName, currentShop: $currentShopName)';
  }
}
