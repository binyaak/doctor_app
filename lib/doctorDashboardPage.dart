import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_app/LoginPage.dart';
import 'package:doctor_app/doctorAppointmentsPage.dart';
import 'package:doctor_app/doctorLoginPage.dart';
import 'package:doctor_app/doctorProfilePage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// ===========================================================
// DOCTOR DASHBOARD PAGE
// ===========================================================
// This is the home screen for a logged-in doctor.
//
// It shows:
//   - Doctor name and specialization
//   - Profile picture with image picker (camera / gallery)
//   - Appointment count cards: Pending / Accepted / Completed
//   - Navigation buttons: My Profile, My Appointments, Logout
// ===========================================================

class DoctorDashboardPage extends StatefulWidget {
  // doctorId = Firestore document ID in the 'doctors' collection
  final String doctorId;
  // doctorData = all field values from that Firestore document
  final Map<String, dynamic> doctorData;

  const DoctorDashboardPage({
    super.key,
    required this.doctorId,
    required this.doctorData,
  });

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  late Map<String, dynamic> currentDoctorData;

  // Appointment counts - we will fill these from Firestore
  int pendingCount = 0;
  int acceptedCount = 0;
  int completedCount = 0;
  bool isLoadingCounts = true;

  // Profile image upload state
  bool isUploadingImage = false;
  Uint8List? _webImageBytes;
  File? _localImageFile;

  @override
  void initState() {
    super.initState();
    currentDoctorData = Map<String, dynamic>.from(widget.doctorData);
    _loadDoctorProfile();
    loadAppointmentCounts();
  }

  // -------------------------------------------------------
  // LOAD LATEST DOCTOR PROFILE FROM FIRESTORE
  // -------------------------------------------------------
  Future<void> _loadDoctorProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            currentDoctorData = data;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading doctor profile: $e');
    }
  }

  // -------------------------------------------------------
  // LOAD APPOINTMENT COUNTS FROM FIRESTORE
  // -------------------------------------------------------
  Future<void> loadAppointmentCounts() async {
    final String doctorName = (currentDoctorData['DocName'] ?? '').toString().trim();

    if (doctorName.isEmpty) {
      setState(() => isLoadingCounts = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorName', isEqualTo: doctorName)
          .get();

      int pending = 0;
      int accepted = 0;
      int completed = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? 'Booked').toString();

        if (status == 'Booked') {
          pending++;
        } else if (status == 'Accepted') {
          accepted++;
        } else if (status == 'Completed') {
          completed++;
        }
      }

      if (mounted) {
        setState(() {
          pendingCount = pending;
          acceptedCount = accepted;
          completedCount = completed;
          isLoadingCounts = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading appointment counts: $e');
      if (mounted) setState(() => isLoadingCounts = false);
    }
  }

  // -------------------------------------------------------
  // IMAGE PICKER & UPLOADER
  // -------------------------------------------------------
  Future<void> _pickAndUploadImage() async {
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
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Change Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
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

      if (pickedFile == null) return;

      setState(() => isUploadingImage = true);

      Uint8List? imageBytes;
      File? nativeFile;

      if (kIsWeb) {
        imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = imageBytes;
          _localImageFile = null;
        });
      } else {
        nativeFile = File(pickedFile.path);
        imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _localImageFile = nativeFile;
          _webImageBytes = null;
        });
      }

      String? downloadUrl;

      // 1. Try uploading to Firebase Storage
      try {
        final String fileName =
            '${widget.doctorId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pics')
            .child(fileName);

        final metadata = SettableMetadata(contentType: 'image/jpeg');

        if (kIsWeb && imageBytes != null) {
          await storageRef.putData(imageBytes, metadata);
        } else if (nativeFile != null) {
          await storageRef.putFile(nativeFile, metadata);
        }

        downloadUrl = await storageRef.getDownloadURL();
      } catch (storageErr) {
        debugPrint('Firebase Storage upload warning: $storageErr');
        // Fallback: Convert to Base64 data URL if Firebase Storage is unavailable/unconfigured
        if (imageBytes != null && imageBytes.isNotEmpty) {
          final base64String = base64Encode(imageBytes);
          downloadUrl = 'data:image/jpeg;base64,$base64String';
        }
      }

      if (downloadUrl == null) {
        throw Exception('Failed to process picked image file.');
      }

      // 2. Update Firestore doctor document
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .set({'docPic': downloadUrl}, SetOptions(merge: true));

      // 3. Mirror to auth user document if UID differs
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null && authUser.uid != widget.doctorId) {
        try {
          await FirebaseFirestore.instance
              .collection('doctors')
              .doc(authUser.uid)
              .set({'docPic': downloadUrl}, SetOptions(merge: true));
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        currentDoctorData['docPic'] = downloadUrl;
        isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } on PlatformException catch (pe) {
      debugPrint('ImagePicker PlatformException: $pe');
      if (!mounted) return;
      setState(() {
        _localImageFile = null;
        _webImageBytes = null;
        isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image picker error: ${pe.message ?? pe.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('Error uploading doctor profile picture: $e');
      if (!mounted) return;
      setState(() {
        _localImageFile = null;
        _webImageBytes = null;
        isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update picture: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ImageProvider _getDoctorAvatarImage() {
    if (_webImageBytes != null) {
      return MemoryImage(_webImageBytes!);
    }
    if (_localImageFile != null) {
      return FileImage(_localImageFile!);
    }
    final docPic = (currentDoctorData['docPic'] ?? '').toString().trim();
    if (docPic.startsWith('data:image')) {
      try {
        final base64Str = docPic.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {}
    }
    if (docPic.startsWith('http://') || docPic.startsWith('https://')) {
      return NetworkImage(docPic);
    }
    if (docPic.isNotEmpty) {
      return AssetImage(docPic);
    }
    return const AssetImage('asset/doc1.png');
  }

  // -------------------------------------------------------
  // LOGOUT FUNCTION
  // -------------------------------------------------------
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DoctorLoginPage()),
      (route) => false,
    );
  }

  // -------------------------------------------------------
  // BUILD
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final rawName = (currentDoctorData['DocName'] ?? 'Doctor').toString().replaceAll('"', '').trim();
    final String doctorName = rawName.toLowerCase().startsWith('dr.')
        ? rawName.substring(3).trim()
        : rawName.toLowerCase().startsWith('dr ')
            ? rawName.substring(2).trim()
            : rawName;
    final String specialization = currentDoctorData['specialist'] ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
        title: const Text(
          'Doctor Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() => isLoadingCounts = true);
              _loadDoctorProfile();
              loadAppointmentCounts();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================
            // DOCTOR WELCOME CARD WITH IMAGE PICKER
            // ============================================
            Card(
              color: Colors.teal.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Doctor avatar with camera picker badge
                    Tooltip(
                      message: 'Tap to change profile picture',
                      child: GestureDetector(
                        onTap: isUploadingImage ? null : _pickAndUploadImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 38,
                              backgroundColor: Colors.teal.shade100,
                              backgroundImage: _getDoctorAvatarImage(),
                              onBackgroundImageError: (error, stackTrace) {},
                            ),
                            if (isUploadingImage)
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.teal,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Doctor info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. $doctorName',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            specialization.isNotEmpty
                                ? specialization
                                : 'General Physician',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Welcome back!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ============================================
            // APPOINTMENT COUNTS SECTION
            // ============================================
            const Text(
              'Appointment Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // Show loading or counts
            isLoadingCounts
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Colors.teal),
                    ),
                  )
                : Row(
                    children: [
                      // PENDING CARD
                      Expanded(
                        child: _buildCountCard(
                          label: 'Pending',
                          count: pendingCount,
                          color: Colors.orange,
                          icon: Icons.access_time,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // ACCEPTED CARD
                      Expanded(
                        child: _buildCountCard(
                          label: 'Accepted',
                          count: acceptedCount,
                          color: Colors.green,
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // COMPLETED CARD
                      Expanded(
                        child: _buildCountCard(
                          label: 'Completed',
                          count: completedCount,
                          color: Colors.blue,
                          icon: Icons.done_all,
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 28),

            // ============================================
            // NAVIGATION BUTTONS
            // ============================================
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            // MY PROFILE BUTTON
            _buildActionCard(
              icon: Icons.person_outline,
              title: 'My Profile',
              subtitle: 'View and edit your doctor profile',
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorProfilePage(
                      doctorId: widget.doctorId,
                      doctorData: currentDoctorData,
                    ),
                  ),
                ).then((_) {
                  // Refresh dashboard when returning from profile
                  _loadDoctorProfile();
                  loadAppointmentCounts();
                });
              },
            ),

            const SizedBox(height: 12),

            // MY APPOINTMENTS BUTTON
            _buildActionCard(
              icon: Icons.calendar_today_outlined,
              title: 'My Appointments',
              subtitle: 'View and manage patient appointments',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorAppointmentsPage(
                      doctorName: (currentDoctorData['DocName'] ?? '').toString().trim(),
                    ),
                  ),
                ).then((_) {
                  // Refresh counts when returning
                  setState(() => isLoadingCounts = true);
                  loadAppointmentCounts();
                });
              },
            ),  

            const SizedBox(height: 12),

            // LOGOUT BUTTON
            _buildActionCard(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out of the doctor portal',
              color: Colors.red,
              onTap:(){
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>LoginPage())
              );

              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // WIDGET HELPER: COUNT CARD
  // -------------------------------------------------------
  Widget _buildCountCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // WIDGET HELPER: ACTION CARD BUTTON
  // -------------------------------------------------------
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
