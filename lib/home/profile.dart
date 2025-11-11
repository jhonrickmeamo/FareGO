import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:pdfx/pdfx.dart';
import 'package:image/image.dart' as img;

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

  bool isEditing = true; // New users start in editing mode
  bool emailLocked = false;
  String? userId;
  String? phoneError;
  bool loading = true;
  bool registered = false; // 🔹 Track if the user has registered

  // Discount + Base64 Image field
  String? selectedDiscount;
  String? uploadedPhotoBase64;

  @override
  void initState() {
    super.initState();
    _initUserId();
  }

  Future<String> _getDeviceUniqueId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id ?? "unknown_android";
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "unknown_ios";
    } else {
      return "unsupported_platform";
    }
  }

  Future<void> _initUserId() async {
    userId = await _getDeviceUniqueId();

    final userDoc = await _firestore.collection("User").doc(userId).get();

    if (userDoc.exists) {
      await _loadUserInfo();
      setState(() {
        isEditing = false; // Existing users cannot edit
        emailLocked = true;
        registered = true; // 🔹 Hide register button
      });
    } else {
      await _firestore.collection("User").doc(userId).set({
        "name": "",
        "email": "",
        "phone": "",
        "discountType": "",
        "photoBase64": "",
        "createdAt": FieldValue.serverTimestamp(),
      });
      setState(() {
        isEditing = true; // New users can register
        registered = false;
      });
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> _loadUserInfo() async {
    if (userId == null) return;

    DocumentSnapshot userDoc = await _firestore
        .collection("User")
        .doc(userId)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      setState(() {
        nameController.text = data["name"] ?? "";
        emailController.text = data["email"] ?? "";
        phoneController.text = data["phone"] ?? "";
        selectedDiscount = data["discountType"];
        uploadedPhotoBase64 = data["photoBase64"];
        emailLocked = emailController.text.isNotEmpty;
      });
    }
  }

  Future<void> _saveUserInfo() async {
    setState(() {
      phoneError = null;
    });

    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        selectedDiscount == null ||
        uploadedPhotoBase64 == null) {
      // Require ID upload
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields and upload your ID."),
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
        "discountType": selectedDiscount,
        "photoBase64": uploadedPhotoBase64,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (selectedDiscount != null && uploadedPhotoBase64 != null) {
        await _firestore
            .collection("User")
            .doc(userId)
            .collection("Discounts")
            .add({
              "discountType": selectedDiscount,
              "photoBase64": uploadedPhotoBase64,
              "submittedAt": FieldValue.serverTimestamp(),
              "status": "pending",
            });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Registration Complete!")));

      setState(() {
        isEditing = false;
        emailLocked = true;
        registered = true; // 🔹 Hide register button
      });

      _loadUserInfo();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
    }
  }

  Future<void> _uploadPhoto() async {
    try {
      final picker = ImagePicker();

      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Upload Type"),
          content: const Text("Choose the file type to upload."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, "image"),
              child: const Text("Image"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, "pdf"),
              child: const Text("PDF"),
            ),
          ],
        ),
      );

      if (choice == null) return;

      File? file;

      if (choice == "image") {
        final XFile? picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        if (picked == null) return;
        file = File(picked.path);
      } else if (choice == "pdf") {
        final XFile? pickedPdf = await openFile(
          acceptedTypeGroups: [
            XTypeGroup(label: 'PDF', extensions: ['pdf']),
          ],
        );
        if (pickedPdf == null) return;
        File pdfFile = File(pickedPdf.path);

        final pdfDoc = await PdfDocument.openFile(pdfFile.path);
        final page = await pdfDoc.getPage(1);
        final pageImage = await page.render(
          width: page.width,
          height: page.height,
        );
        final img.Image? image = img.decodeImage(pageImage!.bytes);
        final convertedFile = File("${pdfFile.path.replaceAll('.pdf', '')}.jpg")
          ..writeAsBytesSync(img.encodeJpg(image!));
        file = convertedFile;
      }

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() {
        uploadedPhotoBase64 = base64Image;
      });

      await _firestore.collection("User").doc(userId).update({
        "photoBase64": base64Image,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo uploaded successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                child: const Icon(Icons.person, size: 50, color: Colors.teal),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildTextField(
                      "Name",
                      nameController,
                      editable: isEditing,
                    ),
                    _buildTextField(
                      "Email",
                      emailController,
                      editable: isEditing && !emailLocked,
                    ),
                    _buildTextField(
                      "Mobile Number",
                      phoneController,
                      editable: isEditing,
                      isPhone: true,
                      errorText: phoneError,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 10,
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedDiscount,
                        decoration: InputDecoration(
                          labelText: "Discount Type",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ["Student", "PWD", "Elderly"]
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                        onChanged: isEditing
                            ? (v) => setState(() => selectedDiscount = v)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: isEditing ? _uploadPhoto : null,
                      icon: const Icon(Icons.upload),
                      label: const Text("Upload ID / Proof Photo"),
                    ),
                    const SizedBox(height: 30),

                    if (!registered)
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
                        onPressed: _saveUserInfo,
                        child: const Text(
                          "Register",
                          style: TextStyle(fontSize: 16, color: Colors.black),
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
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        readOnly: !editable, // 🔹 Fixed: text fields are now clickable
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
    );
  }
}
