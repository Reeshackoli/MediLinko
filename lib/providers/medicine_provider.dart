import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medicine_stock.dart';
import '../services/medicine_service.dart';

// Provider for all medicines
final medicinesProvider = FutureProvider.autoDispose<List<MedicineStock>>((ref) async {
  try {
    final response = await MedicineService.getAllMedicines();
    final data = response['data'];
    final medicines = (data['medicines'] as List)
        .map((medicine) => MedicineStock.fromJson(medicine))
        .toList();
    return medicines;
  } catch (e) {
    throw Exception('Failed to load medicines: $e');
  }
});

// Provider for low stock alerts
final lowStockAlertsProvider = FutureProvider.autoDispose<List<MedicineStock>>((ref) async {
  try {
    final response = await MedicineService.getLowStockAlerts();
    final medicines = (response['data'] as List)
        .map((medicine) => MedicineStock.fromJson(medicine))
        .toList();
    return medicines;
  } catch (e) {
    throw Exception('Failed to load low stock alerts: $e');
  }
});

// Provider for expiring medicines
final expiringMedicinesProvider = FutureProvider.autoDispose<List<MedicineStock>>((ref) async {
  try {
    final response = await MedicineService.getExpiringMedicines();
    final medicines = (response['data'] as List)
        .map((medicine) => MedicineStock.fromJson(medicine))
        .toList();
    return medicines;
  } catch (e) {
    throw Exception('Failed to load expiring medicines: $e');
  }
});

// Provider for medicine stats
final medicineStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final response = await MedicineService.getAllMedicines();
    final data = response['data'];
    final summary = data['summary'] ?? {};
    
    return {
      'totalMedicines': summary['total'] ?? 0,
      'lowStockCount': summary['lowStock'] ?? 0,
      'expiringCount': summary['expiringSoon'] ?? 0,
      'totalValue': summary['totalValue'] ?? 0.0,
      'totalQuantity': 0,
    };
  } catch (e) {
    return {
      'totalMedicines': 0,
      'lowStockCount': 0,
      'expiringCount': 0,
      'totalValue': 0.0,
      'totalQuantity': 0,
    };
  }
});
