import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ===========================================================
// DOCTOR APPOINTMENT DETAILS PAGE
// ===========================================================
// Shows full details of a single appointment.
//
// Two sections:
//   1. Appointment Info: date, time, fee, status, paymentStatus
//   2. Patient Health Info: loaded from the 'users' collection
//      using the 'userId' stored in the appointment document.
//
// Patient Health Fields (from PatientHealthProfilePage.dart):
//   age, height, weight, bloodPressure, bloodGroup,
//   healthCondition, allergies, medications, medicalHistory,
//   emergencyContactName, emergencyContactPhone
//   (BMI is calculated from height + weight, not stored)
//
// Also shows appointment-level health notes:
//   symptoms, healthCondition, allergies, medications
//   (entered by patient during booking)
//
// Action Buttons:
//   - Accept Appointment  (shown if status == 'Booked')
//   - Reject Appointment  (shown if status == 'Booked' or 'Accepted')
//   - Mark as Completed   (shown if status == 'Accepted')
//   Updates are written to the existing Firestore appointment document.
// ===========================================================

class DoctorAppointmentDetailsPage extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;

  const DoctorAppointmentDetailsPage({
    super.key,
    required this.appointmentId,
    required this.appointmentData,
  });

  @override
  State<DoctorAppointmentDetailsPage> createState() =>
      _DoctorAppointmentDetailsPageState();
}

class _DoctorAppointmentDetailsPageState
    extends State<DoctorAppointmentDetailsPage> {
  // Patient health profile data (loaded from 'users' collection)
  Map<String, dynamic>? patientHealthData;
  bool isLoadingHealth = true;

  // Current status of this appointment
  late String currentStatus;

  @override
  void initState() {
    super.initState();
    // Copy status from appointment data so UI can update locally
    currentStatus = widget.appointmentData['status'] ?? 'Booked';
    // Load patient health info using userId from appointment
    loadPatientHealth();
  }

  // -------------------------------------------------------
  // LOAD PATIENT HEALTH PROFILE FROM FIRESTORE
  // -------------------------------------------------------
  Future<void> loadPatientHealth() async {
    final userId = widget.appointmentData['userId'];

    if (userId == null || userId.toString().isEmpty) {
      setState(() => isLoadingHealth = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId.toString())
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          patientHealthData = data;
          isLoadingHealth = false;
        });

        // If the appointment document was missing patientName or had placeholder 'Patient',
        // backfill the real patient name from the user profile
        final existingName = widget.appointmentData['patientName']?.toString().trim();
        final realName = data?['name']?.toString().trim();
        if ((existingName == null || existingName.isEmpty || existingName == 'Patient') &&
            realName != null &&
            realName.isNotEmpty) {
          try {
            await FirebaseFirestore.instance
                .collection('appointments')
                .doc(widget.appointmentId)
                .update({'patientName': realName});
            widget.appointmentData['patientName'] = realName;
            if (mounted) setState(() {});
          } catch (_) {}
        }
      } else {
        if (mounted) setState(() => isLoadingHealth = false);
      }
    } catch (e) {
      debugPrint('Error loading patient health: $e');
      if (mounted) setState(() => isLoadingHealth = false);
    }
  }

  // -------------------------------------------------------
  // BMI CALCULATION (from height in cm + weight in kg)
  // -------------------------------------------------------
  String calculateBmi(dynamic height, dynamic weight) {
    final double? h = double.tryParse(height?.toString() ?? '');
    final double? w = double.tryParse(weight?.toString() ?? '');
    if (h != null && w != null && h > 0 && w > 0) {
      final double hm = h / 100.0;
      final double bmi = w / (hm * hm);
      return bmi.toStringAsFixed(1);
    }
    return 'N/A';
  }

  // -------------------------------------------------------
  // BUILD
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Appointment fields
    // If patientName in appointment was 'Patient' or null, resolve from patient health profile
    final String? healthProfileName = patientHealthData?['name']?.toString().trim();
    final String appointmentPatientName =
        (widget.appointmentData['patientName'] ?? '').toString().trim();

    final String patientName = (healthProfileName != null && healthProfileName.isNotEmpty)
        ? healthProfileName
        : (appointmentPatientName.isNotEmpty && appointmentPatientName != 'Patient')
            ? appointmentPatientName
            : 'Patient';

    final String date = widget.appointmentData['date'] ?? 'N/A';
    final String time = widget.appointmentData['time'] ?? 'N/A';
    final String fee = widget.appointmentData['fee'] ?? 'N/A';
    final String paymentStatus =
        widget.appointmentData['paymentStatus'] ?? 'N/A';
    final String rawDoctorName = widget.appointmentData['doctorName'] ?? '';
    final String specialist = widget.appointmentData['specialist'] ?? '';

    // Clean up Doctor name formatting (avoid quotes and double "Dr.")
    String cleanDocName = rawDoctorName.replaceAll('"', '').trim();
    if (!cleanDocName.toLowerCase().startsWith('dr.') &&
        !cleanDocName.toLowerCase().startsWith('dr ')) {
      cleanDocName = 'Dr. $cleanDocName';
    }

    // Appointment-level health notes (entered at booking time)
    final String symptoms =
        (widget.appointmentData['symptoms'] ?? '').toString().trim();
    final String apptHealthCondition =
        (widget.appointmentData['healthCondition'] ?? '').toString().trim();
    final String apptAllergies =
        (widget.appointmentData['allergies'] ?? '').toString().trim();
    final String apptMedications =
        (widget.appointmentData['medications'] ?? '').toString().trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appointment Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================
            // STATUS BANNER
            // ============================================
            _buildStatusBanner(currentStatus),

            const SizedBox(height: 16),

            // ============================================
            // APPOINTMENT INFORMATION CARD
            // ============================================
            _buildSectionTitle('Appointment Information', Icons.event_note),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.person, 'Patient', patientName),
                  const Divider(height: 1),
                  _buildInfoRow(
                      Icons.medical_services, 'Doctor', cleanDocName),
                  const Divider(height: 1),
                  _buildInfoRow(Icons.local_hospital, 'Specialist', specialist),
                  const Divider(height: 1),
                  _buildInfoRow(Icons.calendar_today, 'Date', date),
                  const Divider(height: 1),
                  _buildInfoRow(Icons.access_time, 'Time', time),
                  const Divider(height: 1),
                  _buildInfoRow(
                      Icons.currency_rupee, 'Consultation Fee', '₹$fee'),
                  const Divider(height: 1),
                  _buildInfoRow(
                    Icons.payment,
                    'Payment Status',
                    paymentStatus,
                    valueColor: Colors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ============================================
            // APPOINTMENT-LEVEL HEALTH NOTES
            // (entered by patient during booking)
            // ============================================
            if (symptoms.isNotEmpty ||
                apptHealthCondition.isNotEmpty ||
                apptAllergies.isNotEmpty ||
                apptMedications.isNotEmpty) ...[
              _buildSectionTitle(
                  'Health Notes (At Booking)', Icons.note_outlined),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    if (symptoms.isNotEmpty) ...[
                      _buildInfoRow(
                          Icons.sick_outlined, 'Symptoms', symptoms),
                      const Divider(height: 1),
                    ],
                    if (apptHealthCondition.isNotEmpty) ...[
                      _buildInfoRow(Icons.healing_outlined, 'Health Condition',
                          apptHealthCondition),
                      const Divider(height: 1),
                    ],
                    if (apptAllergies.isNotEmpty) ...[
                      _buildInfoRow(Icons.warning_amber_outlined, 'Allergies',
                          apptAllergies),
                      const Divider(height: 1),
                    ],
                    if (apptMedications.isNotEmpty)
                      _buildInfoRow(Icons.medication_outlined, 'Medications',
                          apptMedications),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ============================================
            // PATIENT HEALTH PROFILE SECTION
            // (loaded from users collection)
            // ============================================
            _buildSectionTitle(
                'Patient Health Profile', Icons.health_and_safety_outlined),
            const SizedBox(height: 8),

            isLoadingHealth
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Colors.teal),
                    ),
                  )
                : patientHealthData == null
                    ? Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No health profile found for this patient.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    : Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Patient Name from users
                            _buildInfoRow(
                              Icons.person_outline,
                              'Patient Name',
                              patientHealthData!['name'] ?? 'N/A',
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              Icons.calendar_today_outlined,
                              'Age',
                              patientHealthData!['age']?.toString() ?? 'N/A',
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              Icons.height,
                              'Height',
                              patientHealthData!['height']?.toString() != null &&
                                      patientHealthData!['height']
                                          .toString()
                                          .isNotEmpty
                                  ? '${patientHealthData!['height']} cm'
                                  : 'N/A',
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              Icons.monitor_weight_outlined,
                              'Weight',
                              patientHealthData!['weight']?.toString() != null &&
                                      patientHealthData!['weight']
                                          .toString()
                                          .isNotEmpty
                                  ? '${patientHealthData!['weight']} kg'
                                  : 'N/A',
                            ),
                            const Divider(height: 1),
                            // BMI - calculated from height + weight
                            _buildInfoRow(
                              Icons.speed,
                              'BMI',
                              calculateBmi(
                                patientHealthData!['height'],
                                patientHealthData!['weight'],
                              ),
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              Icons.favorite_border,
                              'Blood Pressure',
                              patientHealthData!['bloodPressure']
                                      ?.toString() ??
                                  'N/A',
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              Icons.bloodtype_outlined,
                              'Blood Group',
                              patientHealthData!['bloodGroup']?.toString() ??
                                  'N/A',
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              Icons.healing_outlined,
                              'Health Condition',
                              patientHealthData!['healthCondition']
                                      ?.toString() ??
                                  'N/A',
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              Icons.warning_amber_outlined,
                              'Allergies',
                              patientHealthData!['allergies']?.toString() ??
                                  'N/A',
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              Icons.medication_outlined,
                              'Current Medications',
                              patientHealthData!['medications']?.toString() ??
                                  'N/A',
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              Icons.history_outlined,
                              'Medical History',
                              patientHealthData!['medicalHistory']
                                      ?.toString() ??
                                  'N/A',
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              Icons.contact_phone_outlined,
                              'Emergency Contact',
                              [
                                patientHealthData!['emergencyContactName']
                                    ?.toString(),
                                patientHealthData!['emergencyContactPhone']
                                    ?.toString(),
                              ]
                                  .where((v) => v != null && v.isNotEmpty)
                                  .join(' | ')
                                  .isEmpty
                                  ? 'N/A'
                                  : [
                                      patientHealthData![
                                              'emergencyContactName']
                                          ?.toString(),
                                      patientHealthData![
                                              'emergencyContactPhone']
                                          ?.toString(),
                                    ]
                                      .where((v) => v != null && v.isNotEmpty)
                                      .join(' | '),
                            ),
                          ],
                        ),
                      ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // STATUS BANNER WIDGET
  // -------------------------------------------------------
  Widget _buildStatusBanner(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'accepted':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'completed':
        color = Colors.blue;
        icon = Icons.done_all;
        break;
      case 'rejected':
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'booked':
      default:
        color = Colors.orange;
        icon = Icons.access_time;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Text(
            'Status: $status',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // SECTION TITLE WIDGET
  // -------------------------------------------------------
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------
  // INFO ROW WIDGET
  // -------------------------------------------------------
  // A single label + value row used inside cards.
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.teal, size: 20),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value.isEmpty ? 'N/A' : value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: valueColor ?? Colors.black87,
        ),
      ),
    );
  }
}
