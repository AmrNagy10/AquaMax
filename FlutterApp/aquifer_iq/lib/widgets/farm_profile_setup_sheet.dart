import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/farm_profile.dart';
import '../services/farm_profile_service.dart';

/// بتتفتح أول ما المستخدم يفعّل Agricultural mode ومفيش profile محفوظ.
/// بترجّع لما تتقفل — مفيش return value، الحفظ بيحصل جوا نفسها عن طريق
/// [FarmProfileService] مباشرة.
Future<void> showFarmProfileSetupSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const FarmProfileSetupSheet(),
  );
}

class FarmProfileSetupSheet extends StatefulWidget {
  const FarmProfileSetupSheet({super.key});

  @override
  State<FarmProfileSetupSheet> createState() => _FarmProfileSetupSheetState();
}

class _FarmProfileSetupSheetState extends State<FarmProfileSetupSheet> {
  CropType? _selectedCrop;
  SoilType? _selectedSoil;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey[600]!;
    final chipBorder = isDark ? const Color(0xFF30363D) : Colors.grey.shade300;

    final bool canSave = _selectedCrop != null && _selectedSoil != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 12,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: subtitleColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: const BoxDecoration(color: Color(0xFF27500A), shape: BoxShape.circle),
                    child: const Icon(Icons.eco_rounded, color: Color(0xFF97C459), size: 19),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Set up your field", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                        Text("Tailors readings to your crop and soil", style: TextStyle(fontSize: 12, color: subtitleColor)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text("WHAT ARE YOU GROWING", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: subtitleColor)),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.8,
                children: CropType.values.map((crop) {
                  final selected = _selectedCrop == crop;
                  return _SelectableTile(
                    icon: crop.icon,
                    label: crop.label,
                    selected: selected,
                    cardColor: cardColor,
                    borderColor: chipBorder,
                    textColor: textColor,
                    onTap: () => setState(() => _selectedCrop = crop),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Text("WHAT'S YOUR SOIL LIKE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: subtitleColor)),
              const SizedBox(height: 8),
              ...SoilType.values.map((soil) {
                final selected = _selectedSoil == soil;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SelectableSoilCard(
                    soil: soil,
                    selected: selected,
                    cardColor: cardColor,
                    borderColor: chipBorder,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    onTap: () => setState(() => _selectedSoil = soil),
                  ),
                );
              }),
              const SizedBox(height: 12),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: canSave
                      ? () {
                    context.read<FarmProfileService>().setProfile(
                      FarmProfile(cropType: _selectedCrop!, soilType: _selectedSoil!),
                    );
                    Navigator.pop(context);
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF185FA5),
                    disabledBackgroundColor: const Color(0xFF185FA5).withOpacity(0.35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text("Save and continue", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () {
                  context.read<FarmProfileService>().skipWithDefault();
                  Navigator.pop(context);
                },
                child: Text("Skip for now", style: TextStyle(color: subtitleColor, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color cardColor, borderColor, textColor;
  final VoidCallback onTap;

  const _SelectableTile({
    required this.icon, required this.label, required this.selected,
    required this.cardColor, required this.borderColor, required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF639922).withOpacity(0.12) : cardColor,
          border: Border.all(color: selected ? const Color(0xFF639922) : borderColor, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: selected ? const Color(0xFF639922) : textColor.withOpacity(0.6)),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: textColor), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class _SelectableSoilCard extends StatelessWidget {
  final SoilType soil;
  final bool selected;
  final Color cardColor, borderColor, textColor, subtitleColor;
  final VoidCallback onTap;

  const _SelectableSoilCard({
    required this.soil, required this.selected,
    required this.cardColor, required this.borderColor, required this.textColor, required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF639922).withOpacity(0.12) : cardColor,
          border: Border.all(color: selected ? const Color(0xFF639922) : borderColor, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(soil.icon, size: 18, color: selected ? const Color(0xFF639922) : subtitleColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(soil.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                  Text(soil.description, style: TextStyle(fontSize: 11, color: selected ? const Color(0xFF639922) : subtitleColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}