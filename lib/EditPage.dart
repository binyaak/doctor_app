import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final String name;
  final String phone;
  final File? profileImage;

  const EditProfilePage({
    super.key,
    required this.name,
    required this.phone,
    this.profileImage,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController nameController;
  late TextEditingController phoneController;

  File? _profileImage;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.name);
    phoneController = TextEditingController(text: widget.phone);

    _profileImage = widget.profileImage;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take a Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    if (nameController.text.trim().isEmpty) {
      _showMessage("Please enter your name");
      return;
    }

    if (phoneController.text.trim().isEmpty) {
      _showMessage("Please enter your phone number");
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await _firestore.collection('users').doc(user.uid).set(
        {
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': user.email ?? "",
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      Navigator.pop(context, {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'profileImage': _profileImage,
      });
    } catch (e) {
      setState(() {
        isSaving = false;
      });

      _showMessage("Unable to update profile");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            const SizedBox(height: 20),

            // PROFILE IMAGE
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [

                  GestureDetector(
                    onTap: _pickImage,

                    child: CircleAvatar(
                      radius: 75,

                      backgroundColor: Colors.grey.shade300,

                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,

                      child: _profileImage == null
                          ? const Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),

                  GestureDetector(
                    onTap: _pickImage,

                    child: Container(
                      padding: const EdgeInsets.all(10),

                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            // NAME
            TextField(
              controller: nameController,

              decoration: InputDecoration(
                labelText: "Full Name",
                hintText: "Enter your full name",
                prefixIcon: const Icon(Icons.person),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // EMAIL
            TextField(
              controller: TextEditingController(
                text: _auth.currentUser?.email ?? "",
              ),

              readOnly: true,

              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email),

                filled: true,
                fillColor: Colors.grey.shade100,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // PHONE
            TextField(
              controller: phoneController,

              keyboardType: TextInputType.phone,

              decoration: InputDecoration(
                labelText: "Phone Number",
                hintText: "Enter your phone number",
                prefixIcon: const Icon(Icons.phone),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 35),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton(
                onPressed: isSaving ? null : _saveProfile,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Save Changes",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 15),

            // CANCEL
            SizedBox(
              width: double.infinity,
              height: 52,

              child: OutlinedButton(
                onPressed: isSaving
                    ? null
                    : () {
                        Navigator.pop(context);
                      },

                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}