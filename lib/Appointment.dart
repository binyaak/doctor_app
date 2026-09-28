import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_app/LoginPage.dart';
import 'package:doctor_app/NavigationPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum AppointmentTabType { upcoming, completed, cancelled }

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  // --------------------------------------------------------------------------
  // DOCTOR IMAGE RESOLVER (Asset vs Network)
  // --------------------------------------------------------------------------
  ImageProvider _getDoctorImage(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return const AssetImage('asset/doc1.png');
    }
    final trimmed = imagePath.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }
    return AssetImage(trimmed);
  }

  // --------------------------------------------------------------------------
  // STATUS BADGE COLOR CODING
  // --------------------------------------------------------------------------
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'cancelled':
        return Colors.red.shade700;
      case 'completed':
        return Colors.teal.shade700;
      case 'booked':
      case 'confirmed':
      case 'upcoming':
      default:
        return Colors.blue.shade700;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'cancelled':
        return Colors.red.shade50;
      case 'completed':
        return Colors.teal.shade50;
      case 'booked':
      case 'confirmed':
      case 'upcoming':
      default:
        return Colors.blue.shade50;
    }
  }

  // --------------------------------------------------------------------------
  // CANCEL APPOINTMENT CONFIRMATION DIALOG
  // --------------------------------------------------------------------------
  Future<void> _cancelAppointment(
    BuildContext context,
    String docId,
    String doctorName,
    String date,
    String time,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Cancel Appointment"),
          ],
        ),
        content: Text(
          "Are you sure you want to cancel your appointment with $doctorName on $date at $time?",
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Keep"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(docId)
            .update({
          'status': 'Cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Appointment has been cancelled"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to cancel: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // REMOVE APPOINTMENT FROM HISTORY
  // --------------------------------------------------------------------------
  Future<void> _deleteAppointment(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Remove Record"),
        content: const Text(
          "Do you want to permanently remove this appointment from your history?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(docId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Appointment removed from history"),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to remove: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // APPOINTMENT DETAILS BOTTOM SHEET
  // --------------------------------------------------------------------------
  void _showAppointmentDetails(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    final doctorName = data['doctorName'] ?? 'Doctor';
    final specialist = data['specialist'] ?? 'Specialist';
    final date = data['date'] ?? 'N/A';
    final time = data['time'] ?? 'N/A';
    final fee = data['fee'] ?? '0';
    final status = data['status'] ?? 'Booked';
    final paymentStatus = data['paymentStatus'] ?? 'Paid';
    final doctorImg = data['doctorImage'] ?? data['docPic'];

    // Patient health details
    final symptoms = (data['symptoms'] ?? '').toString().trim();
    final healthCondition = (data['healthCondition'] ?? '').toString().trim();
    final allergies = (data['allergies'] ?? '').toString().trim();
    final medications = (data['medications'] ?? '').toString().trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Drag Pill
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  const Text(
                    "Appointment Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Doctor Summary Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: _getDoctorImage(doctorImg),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctorName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                specialist,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusBgColor(status),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Booking Information
                  _buildDetailRow(
                    Icons.receipt_long_outlined,
                    "Appointment ID",
                    docId.length > 8 ? docId.substring(0, 8).toUpperCase() : docId,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    Icons.calendar_today_outlined,
                    "Date",
                    date,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    Icons.access_time_outlined,
                    "Time",
                    time,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    Icons.currency_rupee,
                    "Consultation Fee",
                    "₹$fee",
                  ),
                  const Divider(),
                  _buildDetailRow(
                    Icons.payment_outlined,
                    "Payment Status",
                    paymentStatus,
                    statusColor: Colors.green.shade700,
                  ),

                  // Patient Health Details (if provided)
                  if (symptoms.isNotEmpty ||
                      healthCondition.isNotEmpty ||
                      allergies.isNotEmpty ||
                      medications.isNotEmpty) ...[
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "Patient Health Details",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff0C67B1),
                        ),
                      ),
                    ),
                    if (symptoms.isNotEmpty)
                      _buildDetailRow(
                        Icons.sick_outlined,
                        "Symptoms",
                        symptoms,
                      ),
                    if (healthCondition.isNotEmpty)
                      _buildDetailRow(
                        Icons.healing_outlined,
                        "Condition",
                        healthCondition,
                      ),
                    if (allergies.isNotEmpty)
                      _buildDetailRow(
                        Icons.warning_amber_outlined,
                        "Allergies",
                        allergies,
                      ),
                    if (medications.isNotEmpty)
                      _buildDetailRow(
                        Icons.medication_outlined,
                        "Medications",
                        medications,
                      ),
                  ],

                  const SizedBox(height: 24),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: statusColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // MAIN BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // 1. Not Logged In State
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "My Appointments",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 64,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Please Log In",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Log in to your account to view your scheduled doctor appointments.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Go to Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Logged In: Stream Only This User's Appointments from Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                "My Appointments",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Error State
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                "My Appointments",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Error loading appointments: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];

        // ------------------------------------------------------------------
        // 3. EMPTY STATE: When patient has never booked an appointment
        // ------------------------------------------------------------------
        if (allDocs.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xffF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              title: const Text(
                "My Appointments",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "No appointments yet",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You haven't booked any doctor appointments yet. Browse top specialists and schedule your consultation.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.search, size: 20),
                        label: const Text(
                          "Book an Appointment",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          // Navigate to Home Page to explore doctors
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Navigationpage(),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ------------------------------------------------------------------
        // 4. BOOKED APPOINTMENTS: Sort newest first & display tabs
        // ------------------------------------------------------------------
        final sortedDocs = List<QueryDocumentSnapshot>.from(allDocs);
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'];
          final bTime = bData['createdAt'];
          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          return 0;
        });

        // Filter by status for tabs
        final upcomingList = sortedDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? 'Booked').toString().toLowerCase();
          return status != 'cancelled' && status != 'completed';
        }).toList();

        final completedList = sortedDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString().toLowerCase();
          return status == 'completed';
        }).toList();

        final cancelledList = sortedDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString().toLowerCase();
          return status == 'cancelled';
        }).toList();

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: const Color(0xffF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              title: const Text(
                "My Appointments",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              centerTitle: true,
              bottom: TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: "Upcoming (${upcomingList.length})"),
                  Tab(text: "Completed (${completedList.length})"),
                  Tab(text: "Cancelled (${cancelledList.length})"),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildAppointmentList(
                  context,
                  upcomingList,
                  AppointmentTabType.upcoming,
                ),
                _buildAppointmentList(
                  context,
                  completedList,
                  AppointmentTabType.completed,
                ),
                _buildAppointmentList(
                  context,
                  cancelledList,
                  AppointmentTabType.cancelled,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // LIST BUILDER FOR EACH TAB
  // --------------------------------------------------------------------------
  Widget _buildAppointmentList(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
    AppointmentTabType tabType,
  ) {
    if (docs.isEmpty) {
      String message;
      switch (tabType) {
        case AppointmentTabType.upcoming:
          message = "No upcoming appointments scheduled.";
          break;
        case AppointmentTabType.completed:
          message = "No completed appointments yet.";
          break;
        case AppointmentTabType.cancelled:
          message = "No cancelled appointments.";
          break;
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_note, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final docId = doc.id;

        return _buildAppointmentCard(context, data, docId, tabType);
      },
    );
  }

  // --------------------------------------------------------------------------
  // APPOINTMENT CARD (Only displays user's booked appointments)
  // --------------------------------------------------------------------------
  Widget _buildAppointmentCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    AppointmentTabType tabType,
  ) {
    final doctorName = data['doctorName'] ?? 'Doctor';
    final specialist = data['specialist'] ?? 'General Specialist';
    final date = data['date'] ?? '';
    final time = data['time'] ?? '';
    final fee = data['fee'] ?? '0';
    final status = data['status'] ?? 'Booked';
    final paymentStatus = data['paymentStatus'] ?? 'Paid';
    final doctorImg = data['doctorImage'] ?? data['docPic'];

    final symptoms = (data['symptoms'] ?? '').toString().trim();
    final isUpcoming = tabType == AppointmentTabType.upcoming;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAppointmentDetails(context, data, docId),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: _getDoctorImage(doctorImg),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          specialist,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date, Time & Fee Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xffF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          date.isNotEmpty ? date : "Date not set",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          time.isNotEmpty ? time : "Time not set",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "Fee: ₹$fee",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Payment: $paymentStatus",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Health Details note if provided
              if (symptoms.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.sick_outlined,
                        size: 15, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Symptoms: $symptoms",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  if (isUpcoming) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text(
                          "Cancel",
                          style: TextStyle(fontSize: 13),
                        ),
                        onPressed: () => _cancelAppointment(
                          context,
                          docId,
                          doctorName,
                          date,
                          time,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text(
                          "Details",
                          style: TextStyle(fontSize: 13),
                        ),
                        onPressed: () => _showAppointmentDetails(
                          context,
                          data,
                          docId,
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: BorderSide(color: Colors.blue.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text(
                          "Details",
                          style: TextStyle(fontSize: 13),
                        ),
                        onPressed: () => _showAppointmentDetails(
                          context,
                          data,
                          docId,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text(
                          "Book Again",
                          style: TextStyle(fontSize: 13),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Navigationpage(),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.grey.shade600,
                      tooltip: "Remove from history",
                      onPressed: () => _deleteAppointment(context, docId),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}