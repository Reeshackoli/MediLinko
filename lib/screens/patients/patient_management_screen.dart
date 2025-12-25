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
    _tabController = TabController(length: 3, vsync: this); // Changed to 3 tabs
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
        title: const Text('Patient Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Treating', icon: Icon(Icons.medical_services)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          // Separate appointments by status
          final pendingAppointments = _getPendingAppointments(appointments);
          final currentPatients = _getCurrentPatients(appointments);
          final treatedPatients = _getTreatedPatients(appointments);

          return TabBarView(
            controller: _tabController,
            children: [
              _PendingAppointmentsList(
                appointments: pendingAppointments,
                onAcceptReject: () {
                  ref.read(doctorAppointmentsProvider.notifier).loadAppointments();
                },
              ),
              _PatientList(
                patients: currentPatients,
                emptyMessage: 'No patients currently being treated',
                emptyIcon: Icons.person_search,
                showCompleteButton: true,
                onComplete: () {
                  ref.read(doctorAppointmentsProvider.notifier).loadAppointments();
                },
              ),
              _PatientList(
                patients: treatedPatients,
                emptyMessage: 'No treatment history available',
                emptyIcon: Icons.history_edu,
                showCompleteButton: false,
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

  List<AppointmentModel> _getPendingAppointments(List<AppointmentModel> appointments) {
    // Return all pending appointments for doctor to approve/reject
    return appointments
        .where((appointment) => appointment.status == 'pending')
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
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
              'lastAppointmentTime': appointment.time,
              'status': appointment.status,
              'appointmentId': appointment.id,
              'symptoms': appointment.symptoms,
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
    
    // CRITICAL: Only show completed appointments in history, NOT cancelled
    for (var appointment in appointments) {
      if (appointment.status == 'completed') {  // Strict filtering - completed only
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

class _PatientList extends ConsumerWidget {
  final List<Map<String, dynamic>> patients;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool showCompleteButton;
  final VoidCallback? onComplete;

  const _PatientList({
    required this.patients,
    required this.emptyMessage,
    required this.emptyIcon,
    this.showCompleteButton = false,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        await ref.read(doctorAppointmentsProvider.notifier).loadAppointments();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return _PatientCard(
            patient: patient,
            showCompleteButton: showCompleteButton,
            onComplete: onComplete,
          );
        },
      ),
    );
  }
}

class _PatientCard extends ConsumerWidget {
  final Map<String, dynamic> patient;
  final bool showCompleteButton;
  final VoidCallback? onComplete;

  const _PatientCard({
    required this.patient,
    this.showCompleteButton = false,
    this.onComplete,
  });

  Future<void> _markAsComplete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Complete'),
        content: Text('Mark treatment for ${patient['name']} as complete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        // Show loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marking as complete...')),
        );

        final result = await ref
            .read(doctorAppointmentsProvider.notifier)
            .updateAppointmentStatus(
              appointmentId: patient['appointmentId'],
              status: 'completed',
            );

        if (context.mounted) {
          if (result['success']) {
            // Trigger immediate refresh
            await ref.read(doctorAppointmentsProvider.notifier).loadAppointments();
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Appointment marked as complete'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${result['message'] ?? 'Failed to complete'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                // Navigate to patient profile
                context.go('/doctor/patients/${patient['id']}?name=${Uri.encodeComponent(patient['name'])}');
              },
              borderRadius: BorderRadius.circular(8),
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
                            Flexible(
                              child: Text(
                                'Last visit: ${_formatDate(patient['lastAppointment'])}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (patient['lastAppointmentTime'] != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  patient['lastAppointmentTime'],
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
            if (showCompleteButton) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _markAsComplete(context, ref),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Mark as Complete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ],
          ],
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

// Pending Appointments List - shows appointments waiting for doctor's approval
class _PendingAppointmentsList extends ConsumerWidget {
  final List<AppointmentModel> appointments;
  final VoidCallback onAcceptReject;

  const _PendingAppointmentsList({
    required this.appointments,
    required this.onAcceptReject,
  });

  Future<void> _approveAppointment(BuildContext context, WidgetRef ref, AppointmentModel appointment) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Approving appointment...')),
      );

      final result = await ref
          .read(doctorAppointmentsProvider.notifier)
          .updateAppointmentStatus(
            appointmentId: appointment.id,
            status: 'approved',
          );

      if (context.mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Appointment approved'),
              backgroundColor: Colors.green,
            ),
          );
          onAcceptReject();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['message'] ?? 'Failed to approve'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectAppointment(BuildContext context, WidgetRef ref, AppointmentModel appointment) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient: ${appointment.patient?.fullName ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Date: ${appointment.date} at ${appointment.time}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (Optional)',
                hintText: 'e.g., Slot no longer available',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rejecting appointment...')),
        );

        final result = await ref
            .read(doctorAppointmentsProvider.notifier)
            .updateAppointmentStatus(
              appointmentId: appointment.id,
              status: 'rejected',
              reason: reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : null,
            );

        if (context.mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Appointment rejected'),
                backgroundColor: Colors.orange,
              ),
            );
            onAcceptReject();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${result['message'] ?? 'Failed to reject'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No pending appointments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'All appointment requests have been reviewed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(doctorAppointmentsProvider.notifier).loadAppointments();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          final patient = appointment.patient;
          
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.withOpacity(0.05),
                    Colors.deepOrange.withOpacity(0.05),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with patient info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.orange.withOpacity(0.2),
                          child: Text(
                            (patient?.fullName ?? 'P')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient?.fullName ?? 'Unknown Patient',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (patient?.phone != null)
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      patient!.phone ?? '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),
                    
                    // Appointment details
                    Row(
                      children: [
                        Expanded(
                          child: _InfoRow(
                            icon: Icons.calendar_today,
                            label: 'Date',
                            value: _formatDate(appointment.date),
                          ),
                        ),
                        Expanded(
                          child: _InfoRow(
                            icon: Icons.access_time,
                            label: 'Time',
                            value: appointment.time,
                          ),
                        ),
                      ],
                    ),
                    
                    if (appointment.symptoms.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Symptoms:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.symptoms,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _rejectAppointment(context, ref, appointment),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approveAppointment(context, ref, appointment),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dateObj = DateTime.parse(date);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dateObj.day} ${months[dateObj.month - 1]} ${dateObj.year}';
    } catch (e) {
      return date;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryBlue),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
