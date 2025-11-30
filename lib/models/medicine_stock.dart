class MedicineStock {
  final String id;
  final String pharmacistId;
  final String medicineName;
  final String batchNumber;
  final DateTime expiryDate;
  final int quantity;
  final double price;
  final String? manufacturer;
  final String category;
  final int lowStockLevel;
  final DateTime? lastExpiryAlertSent;
  final DateTime? lastLowStockAlertSent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLowStock;
  final bool isExpiringSoon;
  final int daysUntilExpiry;
  final double totalValue;

  MedicineStock({
    required this.id,
    required this.pharmacistId,
    required this.medicineName,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
    required this.price,
    this.manufacturer,
    this.category = 'Other',
    this.lowStockLevel = 10,
    this.lastExpiryAlertSent,
    this.lastLowStockAlertSent,
    required this.createdAt,
    required this.updatedAt,
    required this.isLowStock,
    required this.isExpiringSoon,
    required this.daysUntilExpiry,
    required this.totalValue,
  });

  factory MedicineStock.fromJson(Map<String, dynamic> json) {
    return MedicineStock(
      id: json['_id'] ?? '',
      pharmacistId: json['pharmacistId'] ?? '',
      medicineName: json['medicineName'] ?? '',
      batchNumber: json['batchNumber'] ?? '',
      expiryDate: DateTime.parse(json['expiryDate']),
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      manufacturer: json['manufacturer'],
      category: json['category'] ?? 'Other',
      lowStockLevel: json['lowStockLevel'] ?? 10,
      lastExpiryAlertSent: json['lastExpiryAlertSent'] != null
          ? DateTime.parse(json['lastExpiryAlertSent'])
          : null,
      lastLowStockAlertSent: json['lastLowStockAlertSent'] != null
          ? DateTime.parse(json['lastLowStockAlertSent'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isLowStock: json['isLowStock'] ?? false,
      isExpiringSoon: json['isExpiringSoon'] ?? false,
      daysUntilExpiry: json['daysUntilExpiry'] ?? 0,
      totalValue: (json['totalValue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'pharmacistId': pharmacistId,
      'medicineName': medicineName,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate.toIso8601String(),
      'quantity': quantity,
      'price': price,
      if (manufacturer != null) 'manufacturer': manufacturer,
      'category': category,
      'lowStockLevel': lowStockLevel,
      if (lastExpiryAlertSent != null)
        'lastExpiryAlertSent': lastExpiryAlertSent!.toIso8601String(),
      if (lastLowStockAlertSent != null)
        'lastLowStockAlertSent': lastLowStockAlertSent!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isLowStock': isLowStock,
      'isExpiringSoon': isExpiringSoon,
      'daysUntilExpiry': daysUntilExpiry,
      'totalValue': totalValue,
    };
  }

  MedicineStock copyWith({
    String? id,
    String? pharmacistId,
    String? medicineName,
    String? batchNumber,
    DateTime? expiryDate,
    int? quantity,
    double? price,
    String? manufacturer,
    String? category,
    int? lowStockLevel,
    DateTime? lastExpiryAlertSent,
    DateTime? lastLowStockAlertSent,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLowStock,
    bool? isExpiringSoon,
    int? daysUntilExpiry,
    double? totalValue,
  }) {
    return MedicineStock(
      id: id ?? this.id,
      pharmacistId: pharmacistId ?? this.pharmacistId,
      medicineName: medicineName ?? this.medicineName,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      manufacturer: manufacturer ?? this.manufacturer,
      category: category ?? this.category,
      lowStockLevel: lowStockLevel ?? this.lowStockLevel,
      lastExpiryAlertSent: lastExpiryAlertSent ?? this.lastExpiryAlertSent,
      lastLowStockAlertSent: lastLowStockAlertSent ?? this.lastLowStockAlertSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLowStock: isLowStock ?? this.isLowStock,
      isExpiringSoon: isExpiringSoon ?? this.isExpiringSoon,
      daysUntilExpiry: daysUntilExpiry ?? this.daysUntilExpiry,
      totalValue: totalValue ?? this.totalValue,
    );
  }
}
