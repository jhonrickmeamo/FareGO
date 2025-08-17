import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  final bool isRegistered;

  const UserProfileScreen({super.key, required this.isRegistered});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 🔷 Header with gradient and avatar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF66b2b2),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                const Icon(Icons.arrow_back, color: Colors.white),
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade300,
                  child: Text(
                    isRegistered ? "" : "",
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "User Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 🧾 Personal Information
          sectionTitle("Personal Information"),
          infoField("Name", isRegistered ? "" : ""),
          infoField("Email", isRegistered ? "" : ""),

          // 📞 Contact Information
          sectionTitle("Contact Information"),
          infoField("Mobile Number", isRegistered ? "" : ""),

          // ⚙️ Account Settings
          sectionTitle("Account Settings"),
          const Spacer(),

          // 🚪 Logout
          TextButton(
            onPressed: () {
              // Add logout logic here
            },
            child: const Text("logout", style: TextStyle(color: Colors.black)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget infoField(String label, String value) {
    final isClickable = label.toLowerCase().contains("change password");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black)),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: isClickable
                ? () {
                    // 🔐 Handle password change here
                  }
                : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: isClickable ? Colors.grey.shade100 : Colors.transparent,
              ),
              child: Text(
                value.isNotEmpty ? value : "—",
                style: TextStyle(
                  fontSize: 14,
                  color: isClickable ? Colors.blue : Colors.black,
                  decoration: isClickable
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
