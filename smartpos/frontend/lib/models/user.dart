class User {
  final int? id;
  final String username;
  final String phone;
  final String shopName;
  final String languagePreference;
  final String? createdAt;

  User({
    this.id,
    required this.username,
    required this.phone,
    required this.shopName,
    this.languagePreference = 'en',
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      phone: json['phone'],
      shopName: json['shop_name'],
      languagePreference: json['language_preference'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'phone': phone,
      'shop_name': shopName,
      'language_preference': languagePreference,
    };
  }

  // Additional method for registration that includes password
  Map<String, dynamic> toRegistrationJson(String password) {
    return {
      'username': username,
      'phone': phone,
      'shop_name': shopName,
      'language_preference': languagePreference,
      'password': password,
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? phone,
    String? shopName,
    String? languagePreference,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      shopName: shopName ?? this.shopName,
      languagePreference: languagePreference ?? this.languagePreference,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
