import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/medicine_stock.dart';
import '../../providers/medicine_provider.dart';
import '../../services/medicine_service.dart';
import 'package:intl/intl.dart';

class MedicineListScreen extends ConsumerStatefulWidget {
  const MedicineListScreen({super.key});

  @override
  ConsumerState<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends ConsumerState<MedicineListScreen> {
  String _searchQuery = '';
  String _filterCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/pharmacist/medicines/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search medicines...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'All',
                      'Tablet',
                      'Capsule',
                      'Syrup',
                      'Injection',
                      'Cream',
                      'Drops',
                      'Inhaler',
                      'Other'
                    ].map((category) {
                      final isSelected = _filterCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _filterCategory = category;
                            });
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Medicine List
          Expanded(
            child: medicinesAsync.when(
              data: (medicines) {
                // Apply filters
                var filteredMedicines = medicines.where((medicine) {
                  final matchesSearch = medicine.medicineName.toLowerCase().contains(_searchQuery) ||
                      medicine.batchNumber.toLowerCase().contains(_searchQuery) ||
                      (medicine.manufacturer?.toLowerCase().contains(_searchQuery) ?? false);

                  final matchesCategory = _filterCategory == 'All' || medicine.category == _filterCategory;

                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredMedicines.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No medicines found',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Medicine'),
                          onPressed: () => context.push('/pharmacist/medicines/add'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(medicinesProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredMedicines.length,
                    itemBuilder: (context, index) {
                      final medicine = filteredMedicines[index];
                      return _buildMedicineCard(medicine);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${error.toString()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(medicinesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(MedicineStock medicine) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isExpired = medicine.expiryDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/pharmacist/medicines/edit/${medicine.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.medicineName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Batch: ${medicine.batchNumber}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        if (medicine.manufacturer != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            medicine.manufacturer!,
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(medicine.category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      medicine.category,
                      style: TextStyle(
                        color: _getCategoryColor(medicine.category),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.inventory_2,
                    label: 'Qty: ${medicine.quantity}',
                    color: medicine.isLowStock ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.calendar_today,
                    label: dateFormat.format(medicine.expiryDate),
                    color: isExpired
                        ? Colors.red
                        : medicine.isExpiringSoon
                            ? Colors.orange
                            : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.currency_rupee,
                    label: '${medicine.price.toStringAsFixed(2)}',
                    color: Colors.teal,
                  ),
                ],
              ),
              if (medicine.isLowStock || medicine.isExpiringSoon || isExpired) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (medicine.isLowStock)
                      _buildAlertBadge(
                        'Low Stock',
                        Colors.orange,
                        Icons.warning_amber_rounded,
                      ),
                    if (isExpired)
                      _buildAlertBadge(
                        'Expired',
                        Colors.red,
                        Icons.error_outline,
                      )
                    else if (medicine.isExpiringSoon)
                      _buildAlertBadge(
                        'Expiring in ${medicine.daysUntilExpiry} days',
                        Colors.orange,
                        Icons.access_time,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Tablet':
        return Colors.blue;
      case 'Capsule':
        return Colors.purple;
      case 'Syrup':
        return Colors.pink;
      case 'Injection':
        return Colors.red;
      case 'Cream':
        return Colors.teal;
      case 'Drops':
        return Colors.cyan;
      case 'Inhaler':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
