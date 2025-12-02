import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/doctor_location_model.dart';
import '../../providers/map_provider.dart';

class DoctorInfoCard extends ConsumerWidget {
  final DoctorLocationModel doctor;

  const DoctorInfoCard({
    super.key,
    required this.doctor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      elevation: 8,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.fullName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            if (doctor.specialization != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                doctor.specialization!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref.read(mapProvider.notifier).clearSelection();
                        },
                        icon: const Icon(Icons.close),
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Clinic name
                  if (doctor.clinicName != null)
                    _buildInfoRow(
                      Icons.local_hospital,
                      'Clinic',
                      doctor.clinicName!,
                    ),

                  // Experience
                  if (doctor.experience != null)
                    _buildInfoRow(
                      Icons.work_outline,
                      'Experience',
                      '${doctor.experience} years',
                    ),

                  // Consultation fee
                  if (doctor.consultationFee != null)
                    _buildInfoRow(
                      Icons.currency_rupee,
                      'Consultation Fee',
                      '₹${doctor.consultationFee}',
                    ),

                  // Distance
                  if (doctor.distance != null)
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      'Distance',
                      doctor.distanceText,
                      color: const Color(0xFF4C9AFF),
                    ),

                  // City/Address
                  if (doctor.city != null || doctor.clinicAddress != null)
                    _buildInfoRow(
                      Icons.place_outlined,
                      'Location',
                      doctor.clinicAddress ?? doctor.city ?? '',
                      maxLines: 2,
                    ),

                  const SizedBox(height: 20),

                  // Book Appointment button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: null, // Disabled for now
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Book Appointment (Coming Soon)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Coming soon note
                  Center(
                    child: Text(
                      'Appointment booking will be available soon',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: color ?? const Color(0xFF2D3748),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
