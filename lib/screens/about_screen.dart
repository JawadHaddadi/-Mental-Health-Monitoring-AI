import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const Color _teal = Color(0xFF0891B2);
  static const Color _navy = Color(0xFF0A2540);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : _navy;
    final subtextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : _teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // ── 1. App Header ──
            _buildCard(
              cardColor: cardColor,
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [_teal, Color(0xFF0E7490)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.psychology_alt,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mental Health Companion',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI-Powered Support Application',
                    style: TextStyle(fontSize: 14, color: subtextColor),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 13,
                        color: _teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── 2. About the App ──
            _buildCard(
              cardColor: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(Icons.info_outline, 'About the App', textColor),
                  const SizedBox(height: 12),
                  Text(
                    'Mental Health Companion is a mobile application that empowers '
                    'individuals to understand, monitor, and improve their mental '
                    'well-being through AI-powered tools \u2014 all running fully '
                    'on-device for maximum privacy. No data ever leaves your phone.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Key Features',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _featureRow(Icons.chat_bubble_outline,
                      'AI Chat with emotion classification', isDark),
                  _featureRow(Icons.show_chart,
                      'Mood tracking with visual insights', isDark),
                  _featureRow(Icons.assignment_outlined,
                      'PHQ-9, GAD-7, PSS-10, WHO-5 assessments', isDark),
                  _featureRow(Icons.air,
                      'Guided breathing & CBT exercises', isDark),
                  _featureRow(Icons.shield_outlined,
                      'Crisis detection & safety resources', isDark),
                  _featureRow(Icons.phonelink_lock,
                      '100% on-device processing (no cloud)', isDark),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── 3. Development Team ──
            _buildCard(
              cardColor: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(Icons.group_outlined, 'Development Team', textColor),
                  const SizedBox(height: 12),
                  _teamMember('Anas Asiri', 'Developer', Icons.code, isDark),
                  _teamMember('Abdulrahman Hadri', 'Developer', Icons.code, isDark),
                  _teamMember('Jawad Haddadi', 'Developer', Icons.code, isDark),
                  _teamMember('Nawaf Al-Shehri', 'Developer', Icons.code, isDark),
                  _teamMember('Adel Al-Asmari', 'Developer', Icons.code, isDark),
                  const Divider(height: 24),
                  _teamMember(
                      'Dr. Abdulqader Al-Shehri', 'Supervisor', Icons.school, isDark),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── 4. Technology Stack ──
            _buildCard(
              cardColor: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(Icons.layers_outlined, 'Technology Stack', textColor),
                  const SizedBox(height: 12),
                  _techChip('Flutter + Dart', Icons.widgets_outlined, isDark),
                  _techChip('ONNX Runtime (on-device AI)', Icons.memory, isDark),
                  _techChip(
                      'DistilBERT (emotion classification)', Icons.psychology, isDark),
                  _techChip('SQLite (local database)', Icons.storage, isDark),
                  _techChip('fl_chart (visualization)', Icons.bar_chart, isDark),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── 5. Medical Disclaimer ──
            _buildCard(
              cardColor: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                      Icons.warning_amber_rounded, 'Medical Disclaimer', textColor),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(isDark ? 0.15 : 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'This app is NOT a substitute for professional medical advice, '
                      'diagnosis, or treatment. The indicators provided are '
                      'pattern-based and should not be used as medical diagnoses. '
                      'If you are experiencing a mental health crisis, please contact '
                      'emergency services or a mental health professional immediately.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark ? Colors.red.shade200 : Colors.red.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _emergencyContact(
                    Icons.phone,
                    'KSA MOH Hotline',
                    '920033360',
                    isDark,
                  ),
                  const SizedBox(height: 8),
                  _emergencyContact(
                    Icons.language,
                    'International Help',
                    'findahelpline.com',
                    isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── 6. Privacy Policy Summary ──
            _buildCard(
              cardColor: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                      Icons.lock_outline, 'Privacy Policy Summary', textColor),
                  const SizedBox(height: 12),
                  _privacyRow(Icons.smartphone,
                      'All data stored locally on device', isDark),
                  _privacyRow(Icons.cloud_off,
                      'No cloud sync or data transmission', isDark),
                  _privacyRow(Icons.analytics_outlined,
                      'No third-party analytics', isDark),
                  _privacyRow(Icons.delete_outline,
                      'User can delete all data at any time', isDark),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Footer
            Text(
              '\u00a9 2026 Mental Health Companion',
              style: TextStyle(fontSize: 12, color: subtextColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Built with \u2764 for better mental health',
              style: TextStyle(fontSize: 12, color: subtextColor),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Shared Widgets ──

  static Widget _buildCard({
    required Color cardColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  static Widget _sectionHeader(IconData icon, String title, Color textColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _teal, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  static Widget _featureRow(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _teamMember(
      String name, String role, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _teal.withOpacity(0.15),
              child: Icon(icon, size: 18, color: _teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : _navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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

  static Widget _techChip(String label, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: _teal),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _emergencyContact(
      IconData icon, String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.red.shade400),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : _navy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _privacyRow(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.green.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
