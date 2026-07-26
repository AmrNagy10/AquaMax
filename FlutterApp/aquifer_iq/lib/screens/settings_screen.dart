import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/ble_service.dart';
import '../services/reports_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final bleService = context.watch<BleService>();
    final isDark = themeService.isDarkMode;

    // ألوان متكيفة مع الـ theme
    final bgColor = isDark ? const Color(0xFF0D1117) : const Color(0xFFF4F7F6);
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey[600]!;
    final dividerColor = isDark ? Colors.white12 : Colors.grey[200]!;
    final iconBg = isDark ? const Color(0xFF1F2937) : const Color(0xFFE6F1FB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── بروفايل / شعار التطبيق ──
            _buildAppHeader(isDark, cardColor, textColor, subtitleColor),

            const SizedBox(height: 28),

            // ── قسم المظهر ──
            _buildSectionTitle("Appearance", subtitleColor),
            const SizedBox(height: 10),
            _buildCard(
              cardColor: cardColor,
              dividerColor: dividerColor,
              children: [
                _buildToggleTile(
                  icon: Icons.dark_mode_rounded,
                  iconColor: const Color(0xFF185FA5),
                  iconBg: iconBg,
                  title: "Dark Mode",
                  subtitle: "Switch to dark theme",
                  value: isDark,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  onChanged: (val) => themeService.toggleDarkMode(val),
                ),
                Divider(height: 1, color: dividerColor),
                _buildThemeModeTile(
                  context: context,
                  themeService: themeService,
                  iconBg: iconBg,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── قسم الجهاز / BLE ──
            _buildSectionTitle("Device", subtitleColor),
            const SizedBox(height: 10),
            _buildCard(
              cardColor: cardColor,
              dividerColor: dividerColor,
              children: [
                _buildInfoTile(
                  icon: Icons.bluetooth_rounded,
                  iconColor: bleService.isConnected ? const Color(0xFF639922) : Colors.grey,
                  iconBg: iconBg,
                  title: "Sensor Status",
                  value: bleService.isConnected ? "Connected ✓" : bleService.isScanning ? "Scanning..." : "Disconnected",
                  valueColor: bleService.isConnected ? const Color(0xFF639922) : Colors.grey,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
                Divider(height: 1, color: dividerColor),
                _buildActionTile(
                  icon: Icons.refresh_rounded,
                  iconColor: const Color(0xFF185FA5),
                  iconBg: iconBg,
                  title: "Reconnect Device",
                  subtitle: "Scan for AquaMax sensor",
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  onTap: () {
                    if (!bleService.isConnected && !bleService.isScanning) {
                      bleService.startScan();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Scanning for AquaMax device..."),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── قسم البيانات ──
            _buildSectionTitle("Data", subtitleColor),
            const SizedBox(height: 10),
            _buildCard(
              cardColor: cardColor,
              dividerColor: dividerColor,
              children: [
                _buildActionTile(
                  icon: Icons.delete_sweep_rounded,
                  iconColor: Colors.redAccent,
                  iconBg: isDark ? const Color(0xFF2D1515) : const Color(0xFFFFF0F0),
                  title: "Clear All Reports",
                  subtitle: "Delete all saved analysis history",
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  onTap: () => _showClearDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── قسم عن التطبيق ──
            _buildSectionTitle("About", subtitleColor),
            const SizedBox(height: 10),
            _buildCard(
              cardColor: cardColor,
              dividerColor: dividerColor,
              children: [
                _buildInfoTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF185FA5),
                  iconBg: iconBg,
                  title: "App Version",
                  value: "1.0.0",
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
                Divider(height: 1, color: dividerColor),
                _buildInfoTile(
                  icon: Icons.code_rounded,
                  iconColor: const Color(0xFF185FA5),
                  iconBg: iconBg,
                  title: "AI Model",
                  value: "GPT-4o Vision",
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
                Divider(height: 1, color: dividerColor),
                _buildInfoTile(
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFF185FA5),
                  iconBg: iconBg,
                  title: "Standards",
                  value: "WHO & FAO",
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
              ],
            ),

            const SizedBox(height: 40),

            // ── Footer ──
            Center(
              child: Text(
                "AquaMax • Made by Brain",
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── App Header ──
  Widget _buildAppHeader(bool isDark, Color cardColor, Color textColor, Color subtitleColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: Color(0xFF185FA5), shape: BoxShape.circle),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("AquaMax", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
              const SizedBox(height: 4),
              Text("Smart Water Quality Monitor", style: TextStyle(fontSize: 13, color: subtitleColor)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section Title ──
  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.2),
      ),
    );
  }

  // ── Card Wrapper ──
  Widget _buildCard({
    required Color cardColor,
    required Color dividerColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dividerColor),
      ),
      child: Column(children: children),
    );
  }

  // ── Toggle Tile (for Dark Mode switch) ──
  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required Color textColor,
    required Color subtitleColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF185FA5),
          ),
        ],
      ),
    );
  }

  // ── Theme Mode Selector (System / Light / Dark) ──
  Widget _buildThemeModeTile({
    required BuildContext context,
    required ThemeService themeService,
    required Color iconBg,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.tune_rounded, color: Color(0xFF185FA5), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Theme Mode", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 8),
                // أزرار الاختيار الثلاثة
                Row(
                  children: [
                    _buildModeChip("System", ThemeMode.system, themeService, textColor),
                    const SizedBox(width: 8),
                    _buildModeChip("Light", ThemeMode.light, themeService, textColor),
                    const SizedBox(width: 8),
                    _buildModeChip("Dark", ThemeMode.dark, themeService, textColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, ThemeMode mode, ThemeService service, Color textColor) {
    final isSelected = service.themeMode == mode;
    return GestureDetector(
      onTap: () => service.setTheme(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF185FA5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF185FA5) : Colors.grey.withOpacity(0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }

  // ── Info Tile (read-only) ──
  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
    Color? valueColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF185FA5))),
        ],
      ),
    );
  }

  // ── Action Tile (tappable) ──
  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subtitleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: subtitleColor, size: 22),
          ],
        ),
      ),
    );
  }

  // ── Dialog تأكيد حذف التقارير ──
  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear All Reports?"),
        content: const Text("This will permanently delete all saved water analysis history. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              context.read<ReportsService>().clearAll(); // ✅ دالة بنضيفها في ReportsService
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All reports cleared."), backgroundColor: Colors.redAccent),
              );
            },
            child: const Text("Clear All"),
          ),
        ],
      ),
    );
  }
}