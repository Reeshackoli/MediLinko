class PharmacyLocationModel {
  final String id;
  final String storeName;
  final String? ownerName;
  final String? phone;
  final String? email;
  final double latitude;
  final double longitude;
  final String? address;
  final List<String>? services;
  final double? deliveryRadius;
  final String? operatingHours;
  final double? distance;

  PharmacyLocationModel({
    required this.id,
    required this.storeName,
    this.ownerName,
    this.phone,
    this.email,
    required this.latitude,
    required this.longitude,
    this.address,
    this.services,
    this.deliveryRadius,
    this.operatingHours,
    this.distance,
  });

  factory PharmacyLocationModel.fromJson(Map<String, dynamic> json) {
    // Extract storeAddress
    String? fullAddress;
    final storeAddress = json['storeAddress'] as Map<String, dynamic>?;
    if (storeAddress != null) {
      final parts = [
        storeAddress['street'],
        storeAddress['city'],
        storeAddress['pincode'],
      ].where((e) => e != null && e.toString().isNotEmpty).toList();
      if (parts.isNotEmpty) {
        fullAddress = parts.join(', ');
      }
    }

    // Extract operating hours
    String? hours;
    final operatingHours = json['operatingHours'] as Map<String, dynamic>?;
    if (operatingHours != null && operatingHours['opening'] != null && operatingHours['closing'] != null) {
      hours = '${operatingHours['opening']} - ${operatingHours['closing']}';
    }

    return PharmacyLocationModel(
      id: json['_id'] ?? json['id'] ?? '',
      storeName: json['storeName'] ?? 'Unknown Pharmacy',
      ownerName: json['fullName'],
      phone: json['phone'],
      email: json['email'],
      latitude: (json['pharmacyLatitude'] ?? json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['pharmacyLongitude'] ?? json['longitude'] ?? 0.0).toDouble(),
      address: fullAddress,
      services: (json['servicesOffered'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      deliveryRadius: json['deliveryRadius']?.toDouble(),
      operatingHours: hours,
      distance: json['distance']?.toDouble(),
    );
  }
}
