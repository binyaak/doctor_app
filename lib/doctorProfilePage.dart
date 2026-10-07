import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// ===========================================================
// DOCTOR PROFILE PAGE
// ===========================================================
// Shows the logged-in doctor's profile from Firestore.
//
// Actual Firestore field names (from homePage.dart):
//   DocName       -> doctor's full name
//   specialist    -> specialization
//   experience    -> years of experience
//   Rating        -> rating (stored as number or string)
//   Review        -> review count text
//   fee           -> consultation fee
//   docPic        -> image path (asset path like 'asset/doc1.png')
//
// Editable fields: DocName, specialist, experience, fee
// Read-only fields: Rating, Review, docPic
//   (These are usually set by admin, not the doctor themselves)
// ===========================================================

class DoctorProfilePage extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;

  const DoctorProfilePage({
    super.key,
    required this.doctorId,
    required this.doctorData,
  });

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  // Controllers for editable fields
  late TextEditingController nameController;
  late TextEditingController specializationController;
  late TextEditingController experienceController;
  late TextEditingController feeController;

  bool isEditing = false;
  bool isSaving = false;

  File? _profileImage;
  Uint8List? _webProfileImage;

  Future<void> _pickProfileImage() async {
    if (!isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Click "Edit" in top right to change profile picture'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    child: const Icon(Icons.photo_library, color: Colors.teal),
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _getImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    child: const Icon(Icons.camera_alt, color: Colors.teal),
                  ),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _getImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final webImage = await pickedFile.readAsBytes();
          setState(() {
            _webProfileImage = webImage;
          });
        } else {
          setState(() {
            _profileImage = File(pickedFile.path);
          });
        }
      }
    } on PlatformException catch (pe) {
      debugPrint('ImagePicker PlatformException: $pe');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image picker error: ${pe.message ?? pe.toString()}')),
      );
    } catch (e) {
      debugPrint('ImagePicker error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers from the doctor data passed in
    nameController = TextEditingController(
      text: widget.doctorData['DocName'] ?? '',
    );
    specializationController = TextEditingController(
      text: widget.doctorData['specialist'] ?? '',
    );
    experienceController = TextEditingController(
      text: widget.doctorData['experience']?.toString() ?? '',
    );
    feeController = TextEditingController(
      text: widget.doctorData['fee']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    specializationController.dispose();
    experienceController.dispose();
    feeController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------
  // SAVE PROFILE TO FIRESTORE
  // -------------------------------------------------------
  Future<void> saveProfile() async {
    final name = nameController.text.trim();
    final specialization = specializationController.text.trim();
    final experience = experienceController.text.trim();
    final fee = feeController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor name cannot be empty')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      String? imageUrl;

      // 1. Upload Image to Firebase Storage if a new one was selected
      if (_webProfileImage != null || _profileImage != null) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_pics')
              .child('${widget.doctorId}_${DateTime.now().millisecondsSinceEpoch}.jpg');

          if (kIsWeb && _webProfileImage != null) {
            await storageRef.putData(_webProfileImage!);
          } else if (_profileImage != null) {
            await storageRef.putFile(_profileImage!);
          }
          
          imageUrl = await storageRef.getDownloadURL();
        } catch (storageErr) {
          debugPrint('Storage upload fallback: $storageErr');
          Uint8List? bytes;
          if (kIsWeb && _webProfileImage != null) {
            bytes = _webProfileImage;
          } else if (_profileImage != null) {
            bytes = await _profileImage!.readAsBytes();
          }
          if (bytes != null && bytes.isNotEmpty) {
            final base64String = base64Encode(bytes);
            imageUrl = 'data:image/jpeg;base64,$base64String';
          }
        }
      }

      // 2. Prepare Firestore update data
      final updateData = <String, dynamic>{
        'DocName': name,
        'specialist': specialization,
        'experience': experience,
        'fee': fee,
      };

      if (imageUrl != null) {
        updateData['docPic'] = imageUrl;
      }

      // 3. Update Firestore
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .update(updateData);

      if (!mounted) return;

      setState(() {
        isSaving = false;
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  ImageProvider _getDoctorProfileAvatarImage(String docPic) {
    if (_webProfileImage != null) {
      return MemoryImage(_webProfileImage!);
    }
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    }
    final cleanPic = docPic.trim();
    if (cleanPic.startsWith('data:image')) {
      try {
        final base64Str = cleanPic.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {}
    }
    if (cleanPic.startsWith('http://') || cleanPic.startsWith('https://')) {
      return NetworkImage(cleanPic);
    }
    if (cleanPic.isNotEmpty) {
      return AssetImage(cleanPic);
    }
    return const AssetImage('asset/doc1.png');
  }

  // -------------------------------------------------------
  // BUILD
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Read-only fields (not editable by doctor)
    final String rating = widget.doctorData['Rating']?.toString() ?? 'N/A';
    final String review = widget.doctorData['Review']?.toString() ?? '';
    final String docPic = widget.doctorData['docPic'] ?? 'asset/doc1.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Toggle Edit / View mode
          TextButton.icon(
            onPressed: () {
              setState(() => isEditing = !isEditing);
            },
            icon: Icon(
              isEditing ? Icons.visibility : Icons.edit,
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              isEditing ? 'View' : 'Edit',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ============================================
            // DOCTOR IMAGE + NAME HEADER
            // ============================================
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Doctor Image
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.teal.shade100,
                            backgroundImage: _getDoctorProfileAvatarImage(docPic),
                            onBackgroundImageError: (_, e) {},
                          ),
                          if (isEditing)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.teal,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Doctor Name
                    Text(
                      'Dr. ${nameController.text}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specializationController.text,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Rating display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (review.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            review,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ============================================
            // EDITABLE FIELDS SECTION
            // ============================================
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Doctor Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // NAME
                    _buildField(
                      controller: nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      enabled: isEditing,
                    ),

                    const SizedBox(height: 12),

                    // SPECIALIZATION
                    _buildField(
                      controller: specializationController,
                      label: 'Specialization',
                      icon: Icons.medical_services_outlined,
                      enabled: isEditing,
                    ),

                    const SizedBox(height: 12),

                    // EXPERIENCE
                    _buildField(
                      controller: experienceController,
                      label: 'Experience (years)',
                      icon: Icons.work_outline,
                      enabled: isEditing,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 12),

                    // FEE
                    _buildField(
                      controller: feeController,
                      label: 'Consultation Fee (₹)',
                      icon: Icons.currency_rupee,
                      enabled: isEditing,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ============================================
            // READ-ONLY FIELDS (Rating - admin managed)
            // ============================================
            Card(
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rating & Reviews (Admin Managed)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.star, color: Colors.amber),
                      title: const Text('Rating'),
                      subtitle: Text(rating),
                      dense: true,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.rate_review_outlined,
                          color: Colors.blue),
                      title: const Text('Reviews'),
                      subtitle: Text(review.isEmpty ? 'No reviews yet' : review),
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ============================================
            // SAVE BUTTON (only shown when editing)
            // ============================================
            if (isEditing)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isSaving ? null : saveProfile,
                  icon: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    isSaving ? 'Saving...' : 'Save Profile',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // REUSABLE TEXT FIELD BUILDER
  // -------------------------------------------------------
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal, size: 20),
        filled: !enabled,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
