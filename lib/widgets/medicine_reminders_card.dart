import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants/api_config.dart';
import '../services/token_service.dart';
import '../services/notification_service_fcm.dart';
import '../services/medicine_tracker_service.dart';
import '../models/user_medicine.dart';

class MedicineRemindersCard extends StatefulWidget {
  const MedicineRemindersCard({super.key});

  @override
  State<MedicineRemindersCard> createState() => _MedicineRemindersCardState();
}

class _MedicineRemindersCardState extends State<MedicineRemindersCard> {
  List<Medicine> _medicines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await TokenService().getToken();
      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/medicine-reminders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List medicinesJson = data['medicines'] ?? [];
        
        setState(() {
          _medicines = medicinesJson
              .map((m) => Medicine.fromJson(m))
              .toList();
          _isLoading = false;
        });
        
        // Schedule notifications for all medicines
        for (var medicine in _medicines) {
          await _scheduleMedicineNotification(medicine);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading medicines: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addMedicine(Medicine medicine) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/medicine-reminders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': medicine.id,
          'name': medicine.name,
          'dosage': medicine.dosage,
          'time': medicine.time,
        }),
      );

      if (response.statusCode == 200) {
        // Also add to medicine tracker for comprehensive tracking
        try {
          final timeParts = medicine.time.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
          final formattedTime = '$displayHour:${minute.toString().padLeft(2, '0')} $period';
          
          await MedicineTrackerService.addMedicine(
            medicineName: medicine.name,
            dosage: medicine.dosage,
            startDate: DateTime.now(),
            doses: [
              MedicineDose(
                time: formattedTime,
                frequency: 'daily',
              ),
            ],
          );
          debugPrint('✅ Medicine also added to tracker for comprehensive monitoring');
        } catch (trackerError) {
          debugPrint('⚠️ Could not add to tracker (reminder still works): $trackerError');
        }
        
        await _scheduleMedicineNotification(medicine);
        await _loadMedicines();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Reminder set for ${medicine.name}'),
              backgroundColor: const Color(0xFF5FD4C4),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error adding medicine: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to add reminder. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/medicine-reminders/${medicine.id}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await NotificationService.cancelMedicineReminder(medicine.id);
        await _loadMedicines();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reminder deleted for ${medicine.name}'),
              backgroundColor: Colors.grey[700],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error deleting medicine: $e');
    }
  }

  Future<void> _scheduleMedicineNotification(Medicine medicine) async {
    final timeParts = medicine.time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    await NotificationService.scheduleMedicineReminder(
      id: medicine.id,
      medicineName: medicine.name,
      dosage: medicine.dosage,
      time: TimeOfDay(hour: hour, minute: minute),
    );
  }

  void _showAddMedicineDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMedicineDialog(
        onAdd: _addMedicine,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4C9AFF), Color(0xFF5FD4C4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medicine Reminders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_medicines.length} active reminder${_medicines.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showAddMedicineDialog,
                  icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                  tooltip: 'Add Medicine',
                ),
              ],
            ),
          ),
          
          // Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4C9AFF)),
              ),
            )
          else if (_medicines.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Reminders Set',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add your first medicine reminder',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _medicines.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final medicine = _medicines[index];
                return MedicineListTile(
                  medicine: medicine,
                  onDelete: () => _deleteMedicine(medicine),
                );
              },
            ),
        ],
      ),
    );
  }
}

class MedicineListTile extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onDelete;

  const MedicineListTile({
    super.key,
    required this.medicine,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4C9AFF).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4C9AFF), Color(0xFF5FD4C4)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medication,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  medicine.dosage,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4C9AFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  medicine.time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Daily',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Reminder?'),
                  content: Text('Stop reminders for ${medicine.name}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class AddMedicineDialog extends StatefulWidget {
  final Function(Medicine) onAdd;

  const AddMedicineDialog({super.key, required this.onAdd});

  @override
  State<AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<AddMedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      // Generate unique ID within 32-bit range
      final uniqueString = '${_nameController.text}-${_selectedTime.hour}:${_selectedTime.minute}';
      final medicineId = uniqueString.hashCode.abs() % 2147483647; // Max 32-bit int
      
      final medicine = Medicine(
        id: medicineId,
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        time: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
      );
      
      Navigator.pop(context);
      widget.onAdd(medicine);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4C9AFF), Color(0xFF5FD4C4)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medication_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Medicine',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Medicine Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Medicine Name',
                  prefixIcon: const Icon(Icons.medical_services, color: Color(0xFF4C9AFF)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4C9AFF), width: 2),
                  ),
                ),
                validator: (value) => value?.trim().isEmpty == true ? 'Enter medicine name' : null,
              ),
              const SizedBox(height: 16),
              
              // Dosage
              TextFormField(
                controller: _dosageController,
                decoration: InputDecoration(
                  labelText: 'Dosage (e.g., 1 pill, 5ml)',
                  prefixIcon: const Icon(Icons.healing, color: Color(0xFF4C9AFF)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4C9AFF), width: 2),
                  ),
                ),
                validator: (value) => value?.trim().isEmpty == true ? 'Enter dosage' : null,
              ),
              const SizedBox(height: 16),
              
              // Time Picker
              InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF4C9AFF)),
                      const SizedBox(width: 12),
                      Text(
                        'Time: ${_selectedTime.format(context)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit, size: 20, color: Color(0xFF4C9AFF)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C9AFF),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Add Reminder',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Medicine {
  final int id;
  final String name;
  final String dosage;
  final String time;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.time,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      time: json['time'] ?? '00:00',
    );
  }
}
