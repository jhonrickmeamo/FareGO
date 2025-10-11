import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isEditing = false;
  bool emailLocked = false;
  String? userId; // unique ID per device
  String? phoneError;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initUserId();
  }

  // ✅ Get a unique ID based on device hardware
  Future<String> _getDeviceUniqueId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      // Use the Android ID, which is unique per device (not shared)
      return androidInfo.id ?? "unknown_android";
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "unknown_ios";
    } else {
      return "unsupported_platform";
    }
  }

  // ✅ Initialize and load or create a unique user profile
  Future<void> _initUserId() async {
    userId = await _getDeviceUniqueId();

    final userDoc = await _firestore.collection("User").doc(userId).get();

    if (userDoc.exists) {
      // Existing user → load their info
      await _loadUserInfo();
    } else {
      // New user → create a blank profile (optional)
      await _firestore.collection("User").doc(userId).set({
        "name": "",
        "email": "",
        "phone": "",
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      loading = false;
    });
  }

  // ✅ Load the user data for this specific device
  Future<void> _loadUserInfo() async {
    if (userId == null) return;

    DocumentSnapshot userDoc =
        await _firestore.collection("User").doc(userId).get();

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      setState(() {
        nameController.text = data["name"] ?? "";
        emailController.text = data["email"] ?? "";
        phoneController.text = data["phone"] ?? "";
        emailLocked = emailController.text.isNotEmpty;
      });
    }
  }

  // ✅ Save the user info to Firestore
  Future<void> _saveUserInfo() async {
    setState(() {
      phoneError = null;
    });

    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields before saving."),
        ),
      );
      return;
    }

    String phone = phoneController.text.trim();
    if (!(phone.startsWith("+63") || phone.startsWith("09"))) {
      setState(() {
        phoneError =
            "Please input a valid phone number that starts with +63 or 09";
      });
      return;
    }

    try {
      await _firestore.collection("User").doc(userId).set({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phone,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Information Saved!")),
      );

      setState(() {
        isEditing = false;
        emailLocked = true;
      });

      _loadUserInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "User Profile",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header
          Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.teal.shade200],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
            child: Center(
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Image.asset(
                    "assets/images/logo.png",
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildTextField("Name", nameController,
                        editable: isEditing),
                    _buildTextField("Email", emailController,
                        editable: isEditing && !emailLocked),
                    _buildTextField("Mobile Number", phoneController,
                        editable: isEditing,
                        isPhone: true,
                        errorText: phoneError),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        if (isEditing) {
                          _saveUserInfo();
                        } else {
                          setState(() {
                            isEditing = true;
                          });
                        }
                      },
                      child: Text(
                        isEditing
                            ? "Save Information"
                            : "Edit Information",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    required bool editable,
    bool isPhone = false,
    String? errorText,
  }) {
    bool hasError = errorText != null && errorText.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: AbsorbPointer(
        absorbing: !editable,
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          readOnly: !editable,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.black, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.teal,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.teal,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}