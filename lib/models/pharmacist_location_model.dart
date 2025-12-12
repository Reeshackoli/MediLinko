class PharmacyLocationModel {
  final String id;
  final String storeName;
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final int? deliveryRadius;
  final String? operatingHours;
  final List<String>? servicesOffered;
  final String? phone;
  final double? distance;
  
  PharmacyLocationModel({
    required this.id,
    required this.storeName,
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.deliveryRadius,
    this.operatingHours,
    this.servicesOffered,
    this.phone,
    this.distance,
  });
  
  factory PharmacyLocationModel.fromJson(Map<String, dynamic> json) {
    // Try to get coordinates from location field first (GeoJSON format)
    double lat = 0.0;
    double lng = 0.0;
    
    if (json['location'] != null && json['location']['coordinates'] != null) {
      // GeoJSON format: [longitude, latitude]
      lng = (json['location']['coordinates'][0] ?? 0).toDouble();
      lat = (json['location']['coordinates'][1] ?? 0).toDouble();
    } else {
      // Fallback to direct fields
      lat = (json['pharmacyLatitude'] ?? 0).toDouble();
      lng = (json['pharmacyLongitude'] ?? 0).toDouble();
    }
    
    int? parsedRadius;
    if (json['deliveryRadius'] != null) {
      if (json['deliveryRadius'] is int) {
        parsedRadius = json['deliveryRadius'] as int;
      } else {
        parsedRadius = int.tryParse(json['deliveryRadius'].toString());
      }
    }

    return PharmacyLocationModel(
      id: json['_id'] ?? json['id'] ?? '',
      // Prefer explicit shop/store fields. Do NOT fall back to pharmacist fullName.
      storeName: (json['pharmacyName'] ?? json['storeName'] ?? '').toString(),
      latitude: lat,
      longitude: lng,
      address: json['fullAddress'] ?? json['address'],
      city: json['city'],
      deliveryRadius: parsedRadius,
      operatingHours: json['openingTime'] != null && json['closingTime'] != null
          ? '${json['openingTime']} - ${json['closingTime']}'
          : null,
      servicesOffered: json['servicesOffered'] != null
          ? List<String>.from(json['servicesOffered'])
          : null,
      phone: json['phone'] ?? json['altPhone'],
      distance: json['distance']?.toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeName': storeName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'deliveryRadius': deliveryRadius,
      'operatingHours': operatingHours,
      'servicesOffered': servicesOffered,
      'phone': phone,
      'distance': distance,
    };
  }
}