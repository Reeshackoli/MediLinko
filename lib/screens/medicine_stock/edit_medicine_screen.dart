import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/medicine_stock.dart';
import '../../services/medicine_service.dart';
import '../../providers/medicine_provider.dart';
import '../../core/theme/app_theme.dart';

class EditMedicineScreen extends ConsumerStatefulWidget {
  final String medicineId;

  const EditMedicineScreen({super.key, required this.medicineId});

  @override
  ConsumerState<EditMedicineScreen> createState() => _EditMedicineScreenState();
}

class _EditMedicineScreenState extends ConsumerState<EditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicineNameController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _lowStockLevelController = TextEditingController();
  final _quantitySoldController = TextEditingController();

  DateTime? _expiryDate;
  String _selectedCategory = 'Other';
  bool _isLoading = false;
  MedicineStock? _medicine;

  final List<String> _categories = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Injection',
    'Cream',
    'Drops',
    'Inhaler',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadMedicine();
  }

  Future<void> _loadMedicine() async {
    setState(() => _isLoading = true);
    try {
      final medicinesData = await MedicineService.getAllMedicines();
      final data = medicinesData['data'] as Map<String, dynamic>;
      final medicines = (data['medicines'] as List)
          .map((m) => MedicineStock.fromJson(m))
          .toList();
      
      final medicine = medicines.firstWhere(
        (m) => m.id == widget.medicineId,
        orElse: () => throw Exception('Medicine not found'),
      );

      setState(() {
        _medicine = medicine;
        _medicineNameController.text = medicine.medicineName;
        _batchNumberController.text = medicine.batchNumber;
        _quantityController.text = medicine.quantity.toString();
        _priceController.text = medicine.price.toString();
        _manufacturerController.text = medicine.manufacturer ?? '';
        _lowStockLevelController.text = medicine.lowStockLevel.toString();
        _expiryDate = medicine.expiryDate;
        _selectedCategory = medicine.category;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medicine: $e'), backgroundColor: Colors.red),
        );
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _batchNumberController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _manufacturerController.dispose();
    _lowStockLevelController.dispose();
    _quantitySoldController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _recordSale() async {
    final soldQuantity = int.tryParse(_quantitySoldController.text);
    if (soldQuantity == null || soldQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity'), backgroundColor: Colors.red),
      );
      return;
    }

    final currentQuantity = int.parse(_quantityController.text);
    if (soldQuantity > currentQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot sell more than available quantity'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newQuantity = currentQuantity - soldQuantity;
      
      print('🔵 Recording sale: medicineId=${widget.medicineId}, quantity=$soldQuantity');
      
      await MedicineService.recordSale(
        medicineId: widget.medicineId,
        quantitySold: soldQuantity,
      );

      print('✅ Sale recorded successfully');

      setState(() {
        _quantityController.text = newQuantity.toString();
        _quantitySoldController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sale recorded: $soldQuantity units sold'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload medicine to get updated data
      await _loadMedicine();
    } catch (e) {
      print('❌ Error recording sale: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording sale: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select expiry date'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await MedicineService.updateMedicine(
        medicineId: widget.medicineId,
        medicineName: _medicineNameController.text.trim(),
        batchNumber: _batchNumberController.text.trim(),
        expiryDate: _expiryDate,
        quantity: int.parse(_quantityController.text),
        price: double.parse(_priceController.text),
        manufacturer: _manufacturerController.text.trim().isEmpty ? null : _manufacturerController.text.trim(),
        category: _selectedCategory,
        lowStockLevel: int.parse(_lowStockLevelController.text),
      );

      ref.invalidate(medicinesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine updated successfully'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMedicine() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text('Are you sure you want to delete this medicine?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await MedicineService.deleteMedicine(widget.medicineId);
      ref.invalidate(medicinesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine deleted successfully'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isExpired = _medicine?.expiryDate.isBefore(DateTime.now()) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _isLoading ? null : _deleteMedicine,
          ),
        ],
      ),
      body: _isLoading && _medicine == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stock Status Card
                  if (_medicine != null) ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: _medicine!.isLowStock
                          ? Colors.orange.shade50
                          : (_medicine!.isExpiringSoon || isExpired)
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _medicine!.isLowStock
                                      ? Icons.warning_amber_rounded
                                      : isExpired
                                          ? Icons.error_outline
                                          : Icons.check_circle_outline,
                                  color: _medicine!.isLowStock
                                      ? Colors.orange
                                      : isExpired
                                          ? Colors.red
                                          : Colors.green,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Stock Status',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _medicine!.isLowStock
                                            ? 'Low Stock Alert'
                                            : isExpired
                                                ? 'Expired'
                                                : _medicine!.isExpiringSoon
                                                    ? 'Expiring Soon'
                                                    : 'In Stock',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _medicine!.isLowStock
                                              ? Colors.orange
                                              : isExpired
                                                  ? Colors.red
                                                  : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_medicine!.isLowStock || _medicine!.isExpiringSoon || isExpired) ...[
                              const Divider(height: 24),
                              if (_medicine!.isLowStock)
                                _buildAlertRow(
                                  Icons.inventory,
                                  'Current: ${_medicine!.quantity} units',
                                  'Alert level: ${_medicine!.lowStockLevel} units',
                                  Colors.orange,
                                ),
                              if (_medicine!.isExpiringSoon && !isExpired)
                                _buildAlertRow(
                                  Icons.access_time,
                                  'Expires in ${_medicine!.daysUntilExpiry} days',
                                  dateFormat.format(_medicine!.expiryDate),
                                  Colors.orange,
                                ),
                              if (isExpired)
                                _buildAlertRow(
                                  Icons.error_outline,
                                  'Expired on ${dateFormat.format(_medicine!.expiryDate)}',
                                  'Remove from stock immediately',
                                  Colors.red,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quantity Sold Today Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.point_of_sale, color: AppTheme.primaryBlue),
                                const SizedBox(width: 8),
                                const Text(
                                  'Record Sale',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _quantitySoldController,
                                    decoration: InputDecoration(
                                      labelText: 'Quantity Sold Today',
                                      hintText: 'Enter quantity',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      prefixIcon: const Icon(Icons.shopping_cart),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _recordSale,
                                  icon: const Icon(Icons.check),
                                  label: const Text('Record'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Available: ${_quantityController.text} units',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Medicine Details Form
                  const Text(
                    'Medicine Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _medicineNameController,
                    decoration: InputDecoration(
                      labelText: 'Medicine Name *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.medical_services),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Please enter medicine name' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _batchNumberController,
                    decoration: InputDecoration(
                      labelText: 'Batch Number *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.qr_code),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Please enter batch number' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(value: category, child: Text(category));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _manufacturerController,
                    decoration: InputDecoration(
                      labelText: 'Manufacturer (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Current Quantity *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.inventory),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter quantity';
                      if (int.tryParse(value) == null) return 'Please enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price per Unit *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter price';
                      if (double.tryParse(value) == null) return 'Please enter a valid price';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  InkWell(
                    onTap: _selectExpiryDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Expiry Date *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _expiryDate != null ? dateFormat.format(_expiryDate!) : 'Select date',
                        style: TextStyle(color: _expiryDate != null ? Colors.black : Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _lowStockLevelController,
                    decoration: InputDecoration(
                      labelText: 'Low Stock Alert Level *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.warning_amber),
                      helperText: 'Alert when quantity falls below this level',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter low stock level';
                      if (int.tryParse(value) == null) return 'Please enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateMedicine,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Update Medicine'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildAlertRow(IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
