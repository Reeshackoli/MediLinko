import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/appointment_model.dart' show PatientInfo;
import '../../models/prescription_model.dart';
import '../../providers/prescription_provider.dart';
import '../../core/theme/app_theme.dart';

class DoctorPrescriptionsScreen extends ConsumerStatefulWidget {
  const DoctorPrescriptionsScreen({super.key});

  @override
  ConsumerState<DoctorPrescriptionsScreen> createState() => _DoctorPrescriptionsScreenState();
}

class _DoctorPrescriptionsScreenState extends ConsumerState<DoctorPrescriptionsScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(doctorPatientsProvider.notifier).loadPatients();
      ref.read(doctorPrescriptionsProvider.notifier).loadPrescriptions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsState = ref.watch(doctorPatientsProvider);
    final prescriptionsState = ref.watch(doctorPrescriptionsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Manage Prescriptions', style: TextStyle(color: Colors.white)),
        elevation: 0,
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Patients', icon: Icon(Icons.people)),
            Tab(text: 'Sent Prescriptions', icon: Icon(Icons.description)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Patients Tab
          _buildPatientsTab(patientsState),
          // Sent Prescriptions Tab
          _buildPrescriptionsTab(prescriptionsState),
        ],
      ),
    );
  }

  Widget _buildPatientsTab(AsyncValue patientsState) {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search patients...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        
        // Patient list
        Expanded(
          child: patientsState.when(
            data: (patients) {
              final filteredPatients = patients.where((patient) {
                return patient.fullName.toLowerCase().contains(_searchQuery) ||
                       (patient.email?.toLowerCase().contains(_searchQuery) ?? false);
              }).toList();

              if (filteredPatients.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No patients found'
                            : 'No patients match your search',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await ref.read(doctorPatientsProvider.notifier).loadPatients();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredPatients.length,
                  itemBuilder: (context, index) {
                    final patient = filteredPatients[index];
                    return _PatientCard(patient: patient);
                  },
                ),
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
                      ref.read(doctorPatientsProvider.notifier).loadPatients();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionsTab(AsyncValue prescriptionsState) {
    return prescriptionsState.when(
      data: (prescriptions) {
        if (prescriptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No prescriptions sent yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(doctorPrescriptionsProvider.notifier).loadPrescriptions();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) {
              final prescription = prescriptions[index];
              return _PrescriptionCard(prescription: prescription);
            },
          ),
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
                ref.read(doctorPrescriptionsProvider.notifier).loadPrescriptions();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionCard extends ConsumerWidget {
  final PrescriptionModel prescription;

  const _PrescriptionCard({required this.prescription});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientName = prescription.patient?.fullName ?? 'Unknown Patient';
    final patientEmail = prescription.patient?.email ?? '';
    final createdAt = prescription.createdAt;
    
    // Parse medicines from content if it's text type
    List<String> medicines = [];
    if (prescription.type == 'text' && prescription.content.isNotEmpty) {
      // Try to parse medicines from content
      final lines = prescription.content.split('\n');
      for (var line in lines) {
        if (line.trim().isNotEmpty && !line.toLowerCase().contains('diagnosis') && 
            !line.toLowerCase().contains('notes')) {
          medicines.add(line.trim());
        }
      }
    }
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Show prescription details dialog
          showDialog(
            context: context,
            builder: (context) => _PrescriptionDetailDialog(prescription: prescription),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.secondaryTeal.withOpacity(0.2),
                  child: Text(
                    patientName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryTeal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        patientEmail,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: prescription.type == 'image' ? Colors.purple[50] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        prescription.type == 'image' ? Icons.image : Icons.description,
                        size: 14,
                        color: prescription.type == 'image' ? Colors.purple[700] : Colors.blue[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        prescription.type == 'image' ? 'Image' : 'Text',
                        style: TextStyle(
                          fontSize: 12,
                          color: prescription.type == 'image' ? Colors.purple[700] : Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Prescribed on ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            if (prescription.diagnosis.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.medical_information, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diagnosis:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prescription.diagnosis,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (prescription.type == 'text' && medicines.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Prescription:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 6),
              ...medicines.take(3).map((med) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.medication, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        med,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              )),
              if (medicines.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${medicines.length - 3} more...',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

class _PrescriptionDetailDialog extends StatelessWidget {
  final PrescriptionModel prescription;

  const _PrescriptionDetailDialog({required this.prescription});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Prescription Details',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.secondaryTeal.withOpacity(0.2),
                          child: Text(
                            (prescription.patient?.fullName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryTeal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prescription.patient?.fullName ?? 'Unknown Patient',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                prescription.patient?.email ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Date',
                      '${prescription.createdAt.day}/${prescription.createdAt.month}/${prescription.createdAt.year}',
                    ),
                    if (prescription.diagnosis.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.medical_information,
                        'Diagnosis',
                        prescription.diagnosis,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.description, size: 20, color: Colors.grey[700]),
                        const SizedBox(width: 12),
                        Text(
                          'Prescription:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (prescription.type == 'text')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          prescription.content,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.image, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Image Prescription',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'URL: ${prescription.content}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    if (prescription.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.note,
                        'Notes',
                        prescription.notes,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientInfo patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.push('/doctor/prescriptions/create', extra: patient);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                child: Text(
                  patient.fullName[0].toUpperCase(),
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
                      patient.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patient.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (patient.phone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        patient.phone!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
