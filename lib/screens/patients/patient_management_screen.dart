import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';

class PatientManagementScreen extends ConsumerStatefulWidget {
  const PatientManagementScreen({super.key});

  @override
  ConsumerState<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends ConsumerState<PatientManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load appointments
    Future.microtask(() {
      ref.read(doctorAppointmentsProvider.notifier).loadAppointments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Currently Treating', icon: Icon(Icons.medical_services)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          // Separate patients by status
          final currentPatients = _getCurrentPatients(appointments);
          final treatedPatients = _getTreatedPatients(appointments);

          return TabBarView(
            controller: _tabController,
            children: [
              _PatientList(
                patients: currentPatients,
                emptyMessage: 'No patients currently being treated',
                emptyIcon: Icons.person_search,
              ),
              _PatientList(
                patients: treatedPatients,
                emptyMessage: 'No treatment history available',
                emptyIcon: Icons.history_edu,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(doctorAppointmentsProvider.notifier).loadAppointments();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getCurrentPatients(List<AppointmentModel> appointments) {
    final patientMap = <String, Map<String, dynamic>>{};
    
    // CRITICAL: Only show patients with 'approved' status
    for (var appointment in appointments) {
      if (appointment.status == 'approved') {  // Strict filtering - approved only
        final patient = appointment.patient;
        if (patient != null) {
          final patientId = patient.id;
          if (!patientMap.containsKey(patientId)) {
            patientMap[patientId] = {
              'id': patientId,
              'name': patient.fullName,
              'email': patient.email,
              'phone': patient.phone,
              'lastAppointment': appointment.date,
              'status': appointment.status,
              'appointmentId': appointment.id,
            };
          }
        }
      }
    }
    
    return patientMap.values.toList()
      ..sort((a, b) => b['lastAppointment'].compareTo(a['lastAppointment']));
  }

  List<Map<String, dynamic>> _getTreatedPatients(List<AppointmentModel> appointments) {
    final patientMap = <String, Map<String, dynamic>>{};
    
    for (var appointment in appointments) {
      if (appointment.status == 'completed' || appointment.status == 'cancelled') {
        final patient = appointment.patient;
        if (patient != null) {
          final patientId = patient.id;
          if (!patientMap.containsKey(patientId)) {
            patientMap[patientId] = {
              'id': patientId,
              'name': patient.fullName,
              'email': patient.email,
              'phone': patient.phone,
              'lastAppointment': appointment.date,
              'status': appointment.status,
              'appointmentId': appointment.id,
            };
          } else {
            // Update to most recent appointment
            if (appointment.date.compareTo(patientMap[patientId]!['lastAppointment']) > 0) {
              patientMap[patientId]!['lastAppointment'] = appointment.date;
              patientMap[patientId]!['status'] = appointment.status;
              patientMap[patientId]!['appointmentId'] = appointment.id;
            }
          }
        }
      }
    }
    
    return patientMap.values.toList()
      ..sort((a, b) => b['lastAppointment'].compareTo(a['lastAppointment']));
  }
}

class _PatientList extends StatelessWidget {
  final List<Map<String, dynamic>> patients;
  final String emptyMessage;
  final IconData emptyIcon;

  const _PatientList({
    required this.patients,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Implement refresh logic
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return _PatientCard(patient: patient);
        },
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to patient profile
          context.go('/doctor/patients/${patient['id']}?name=${Uri.encodeComponent(patient['name'])}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                child: Text(
                  patient['name'][0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['name'],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    if (patient['email'] != null)
                      Text(
                        patient['email'],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Last visit: ${_formatDate(patient['lastAppointment'])}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusChip(status: patient['status']),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dateObj = DateTime.parse(date);
      return '${dateObj.day}/${dateObj.month}/${dateObj.year}';
    } catch (e) {
      return date;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green.shade700;
        label = 'Active';
        break;
      case 'pending':
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange.shade700;
        label = 'Pending';
        break;
      case 'completed':
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue.shade700;
        label = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red.shade700;
        label = 'Cancelled';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

