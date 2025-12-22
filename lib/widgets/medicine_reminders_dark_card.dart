import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants/api_config.dart';
import '../services/token_service.dart';
import '../services/notification_service.dart';

class MedicineRemindersDarkCard extends StatefulWidget {
  const MedicineRemindersDarkCard({super.key});

  @override
  State<MedicineRemindersDarkCard> createState() => _MedicineRemindersDarkCardState();
}

class _MedicineRemindersDarkCardState extends State<MedicineRemindersDarkCard> {
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
        await _scheduleMedicineNotification(medicine);
        await _loadMedicines();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Reminder set for ${medicine.name}'),
              backgroundColor: const Color(0xFF14B8A6),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error adding medicine: $e');
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
              content: Text('❌ Reminder deleted for ${medicine.name}'),
              backgroundColor: const Color(0xFFEF4444),
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
        color: const Color(0xFF2D3748), // Charcoal
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
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
                colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)], // Teal gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.medication_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medicine Reminders',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_medicines.length} active',
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
                  icon: const Icon(Icons.add_circle, color: Colors.white, size: 32),
                  tooltip: 'Add Medicine',
                ),
              ],
            ),
          ),
          
          // Medicines List
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
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
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Reminders Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add your first medicine',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _medicines.length,
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A202C), // Darker charcoal
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF14B8A6).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medication,
              color: Color(0xFF14B8A6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  medicine.dosage,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
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
                  color: const Color(0xFF14B8A6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  medicine.time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Daily',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
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
                  backgroundColor: const Color(0xFF2D3748),
                  title: const Text(
                    'Delete Reminder?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    'Stop reminders for ${medicine.name}?',
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF14B8A6))),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF14B8A6),
              surface: Color(0xFF2D3748),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final medicine = Medicine(
        id: DateTime.now().millisecondsSinceEpoch,
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
      backgroundColor: const Color(0xFF2D3748),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.medication_rounded, color: Color(0xFF14B8A6), size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Add Medicine',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Medicine Name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Medicine Name',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  prefixIcon: const Icon(Icons.medical_services, color: Color(0xFF14B8A6)),
                  filled: true,
                  fillColor: const Color(0xFF1A202C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
                  ),
                ),
                validator: (value) => value?.trim().isEmpty == true ? 'Enter medicine name' : null,
              ),
              const SizedBox(height: 16),
              
              // Dosage
              TextFormField(
                controller: _dosageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Dosage (e.g., 1 pill, 5ml)',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  prefixIcon: const Icon(Icons.healing, color: Color(0xFF14B8A6)),
                  filled: true,
                  fillColor: const Color(0xFF1A202C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
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
                    color: const Color(0xFF1A202C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF14B8A6)),
                      const SizedBox(width: 12),
                      Text(
                        'Time: ${_selectedTime.format(context)}',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit, size: 20, color: Color(0xFF14B8A6)),
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
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14B8A6),
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
