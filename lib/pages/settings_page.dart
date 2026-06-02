import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F1EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F1EE),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingsTile(Icons.notifications_none, 'Push Notifications', Colors.blue.shade50, Colors.blue),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              _buildSettingsTile(Icons.verified_user_outlined, 'Security & Password', Colors.orange.shade50, Colors.orange),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              _buildSettingsTile(Icons.language, 'Language', Colors.red.shade50, Colors.redAccent),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              _buildSettingsTile(Icons.info_outline, 'About App', Colors.grey.shade100, Colors.grey.shade700),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, Color bgIconColor, Color iconColor) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgIconColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: () {},
    );
  }
}
