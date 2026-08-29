class UserAddress {
  final String id;
  final String recipientName;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String phone;
  final bool isDefault;

  const UserAddress({
    required this.id,
    required this.recipientName,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    this.country = 'United States',
    required this.phone,
    this.isDefault = false,
  });

  String get fullAddress => '$street, $city, $state $zipCode, $country';

  UserAddress copyWith({
    String? id,
    String? recipientName,
    String? street,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? phone,
    bool? isDefault,
  }) {
    return UserAddress(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      recipientName: json['recipientName']?.toString() ?? 'Guest Shopper',
      street: json['street']?.toString() ?? '14 Market Street',
      city: json['city']?.toString() ?? 'New York',
      state: json['state']?.toString() ?? 'NY',
      zipCode: json['zipCode']?.toString() ?? '10001',
      country: json['country']?.toString() ?? 'United States',
      phone: json['phone']?.toString() ?? '+1 (555) 234-5678',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipientName': recipientName,
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'phone': phone,
      'isDefault': isDefault,
    };
  }
}

