import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/pharmacy_location_model.dart';
import '../../core/theme/app_theme.dart';

class PharmacyInfoCard extends StatelessWidget {
  final PharmacyLocationModel pharmacy;

  const PharmacyInfoCard({super.key, required this.pharmacy});

  Future<void> _makePhoneCall(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openMaps() async {
    // Try geo URI first (works best on Android)
    final Uri geoUri = Uri.parse(
      'geo:${pharmacy.latitude},${pharmacy.longitude}?q=${pharmacy.latitude},${pharmacy.longitude}(${Uri.encodeComponent(pharmacy.storeName)})',
    );
    
    // Fallback to Google Maps web URL
    final Uri webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${pharmacy.latitude},${pharmacy.longitude}',
    );
    
    try {
      // Try geo URI first (opens Maps app on Android)
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        // Fallback to web URL
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening maps: $e');
      // Last resort - try web URL
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (e2) {
        print('Failed to open maps: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF5FD4C4)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.local_pharmacy,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pharmacy.storeName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (pharmacy.distance != null)
                            Text(
                              '${pharmacy.distance!.toStringAsFixed(1)} km away',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Info rows
                if (pharmacy.address != null)
                  _buildInfoRow(
                    Icons.location_on,
                    pharmacy.address!,
                    const Color(0xFF4C9AFF),
                  ),
                
                if (pharmacy.phone != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.phone,
                    pharmacy.phone!,
                    const Color(0xFF10B981),
                  ),
                ],
                
                if (pharmacy.operatingHours != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.access_time,
                    pharmacy.operatingHours!,
                    const Color(0xFF8B5CF6),
                  ),
                ],
                
                if (pharmacy.services != null && pharmacy.services!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pharmacy.services!.take(3).map((service) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          service,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Action buttons
                Row(
                  children: [
                    if (pharmacy.phone != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _makePhoneCall(pharmacy.phone!),
                          icon: const Icon(Icons.phone, size: 20),
                          label: const Text('Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (pharmacy.phone != null) const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openMaps,
                        icon: const Icon(Icons.directions, size: 20),
                        label: const Text('Directions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          side: const BorderSide(color: Color(0xFF10B981)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
