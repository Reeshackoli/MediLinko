import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/map_provider.dart';

class SpecialtyFilterChips extends ConsumerWidget {
  const SpecialtyFilterChips({super.key});

  // Common specializations
  static const List<String> commonSpecializations = [
    'Cardiologist',
    'Dentist',
    'Dermatologist',
    'Pediatrician',
    'Orthopedic',
    'ENT',
    'Gynecologist',
    'General Physician',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapProvider);
    final availableSpecs = ref.read(mapProvider.notifier).getAvailableSpecializations();
    
    // Use available specializations if any, otherwise use common ones
    final specializations = availableSpecs.isNotEmpty
        ? availableSpecs
        : commonSpecializations;

    if (specializations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: specializations.length,
        itemBuilder: (context, index) {
          final specialty = specializations[index];
          final isActive = mapState.activeFilters.contains(specialty);

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Material(
              elevation: isActive ? 2 : 0,
              shadowColor: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  ref.read(mapProvider.notifier).toggleFilter(specialty);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF4C9AFF)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF4C9AFF)
                          : const Color(0xFF4C9AFF).withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: !isActive
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isActive)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      Text(
                        specialty,
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
