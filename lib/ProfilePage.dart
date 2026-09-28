import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_app/EditPage.dart';
import 'package:doctor_app/PatientHealthProfilePage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctor_app/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String name = "";
  String email = "";
  String phone = "";

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final document = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (document.exists) {
        final data = document.data()!;

        setState(() {
          name = data['name'] ?? "";
          email = data['email'] ?? user.email ?? "";
          phone = data['phone'] ?? "";
          isLoading = false;
        });
      } else {
        setState(() {
          email = user.email ?? "";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showMessage("Unable to load profile");
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> logout() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }

   File? _profileImage;

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo),
                title: Text('Choose from Gallery'),
                onTap: () {
                  _getImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera),
                title: Text('Take a Photo'),
                onTap: () {
                  _getImage(ImageSource.camera);
                  Navigator.pop(context);
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
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [

                  const SizedBox(height: 20),

                  // PROFILE PHOTO
                 Center(
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: _pickProfileImage,
              child: _profileImage == null
                  ? CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.grey,
                      child: Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.white,
                      ),
                    )
                  : CircleAvatar(
                      radius: 80,
                      backgroundImage: FileImage(_profileImage!),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton(
                onPressed: _pickProfileImage,
                tooltip: 'Pick Profile Picture',
                child: Icon(Icons.camera_alt),
              ),
            ),
          ],
        ),
      ),

                  const SizedBox(height: 15),

                  // NAME
                  Text(
                    name.isEmpty ? "User" : name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 35),

                  // NAME
                  profileItem(
                    icon: Icons.person,
                    title: "Full Name",
                    value: name.isEmpty ? "Not available" : name,
                  ),

                  // EMAIL
                  profileItem(
                    icon: Icons.email,
                    title: "Email",
                    value: email.isEmpty ? "Not available" : email,
                  ),

                  // PHONE
                  profileItem(
                    icon: Icons.phone,
                    title: "Phone Number",
                    value: phone.isEmpty ? "Not available" : phone,
                  ),

                  const SizedBox(height: 30),

                  // PATIENT HEALTH PROFILE
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PatientHealthProfilePage(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.medical_information_outlined,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Patient Health Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0C67B1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // EDIT PROFILE
              SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton.icon(
    onPressed: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
          
          EditProfilePage(name: name, phone: phone)
          
        ),
      );

      if (result == true) {
        loadProfile();
      }
    },

    icon: const Icon(
      Icons.edit,
      color: Colors.white,
    ),

    label: const Text(
      "Edit Profile",
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
    ),

    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),

                  const SizedBox(height: 15),
                  

                  // LOGOUT
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: logout,
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.red,
                      ),
                      label: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Colors.red,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget profileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [

          Container(
            padding: const EdgeInsets.all(10),

            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(
              icon,
              color: Colors.blue,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}