import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_app/bookingService.dart';
import 'package:doctor_app/paymentPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Appointmentconfirmation extends StatefulWidget {
  final String selectedTime;
  final String selectedDay;
  final String DocName;
  final String docspecialist;
  final String docPic;
  final String Rating;
  final String fee;

  const Appointmentconfirmation({
    super.key,
    required this.selectedDay,
    required this.selectedTime,
    required this.DocName,
    required this.docspecialist,
    required this.docPic,
    required this.Rating,
    required this.fee,
  });

  @override
  State<Appointmentconfirmation> createState() =>
      _AppointmentconfirmationState();
}

class _AppointmentconfirmationState
    extends State<Appointmentconfirmation> {
  // Optional Health Information Controllers
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _healthConditionController =
      TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();

  String _patientName = "Patient";
  String _patientPhone = "";
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _loadPatientHealthProfile();
  }

  // Pre-fill health information from the patient's saved Health Profile
  Future<void> _loadPatientHealthProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _patientName = data['name'] ?? user.displayName ?? "Patient";
            _patientPhone = data['phone'] ?? user.phoneNumber ?? "";

            // Pre-fill saved condition, allergies, medications if available
            _healthConditionController.text = data['healthCondition'] ?? "";
            _allergiesController.text = data['allergies'] ?? "";
            _medicationsController.text = data['medications'] ?? "";
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading patient profile in confirmation: $e");
    }
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _healthConditionController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Appointment"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// Doctor Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage(widget.docPic),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.DocName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            widget.docspecialist,
                            style: const TextStyle(
                              color: Colors.blue,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 5),
                              Text(widget.Rating),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Appointment Details
            Card(
              child: Column(
                children: [

                  ListTile(
                    leading: const Icon(
                      Icons.calendar_month,
                      color: Colors.blue,
                    ),
                    title: const Text("Appointment Date"),
                    subtitle: Text(widget.selectedDay),
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(
                      Icons.access_time,
                      color: Colors.blue,
                    ),
                    title: const Text("Appointment Time"),
                    subtitle: Text(widget.selectedTime),
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(
                      Icons.currency_rupee,
                      color: Colors.green,
                    ),
                    title: const Text("Consultation Fee"),
                    subtitle: Text("₹${widget.fee}"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Patient Details
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.blue),
                    title: const Text("Patient"),
                    subtitle: Text(_patientName),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.blue),
                    title: const Text("Phone"),
                    subtitle: Text(
                      _patientPhone.isNotEmpty
                          ? _patientPhone
                          : "Not provided",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Health Information (Optional)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.health_and_safety, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          "Health Details (Optional)",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Share any symptoms or current medical info for the doctor to review.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Symptoms
                    TextField(
                      controller: _symptomsController,
                      decoration: InputDecoration(
                        labelText: "Symptoms",
                        hintText: "e.g., Headache, mild fever, throat pain",
                        prefixIcon: const Icon(
                          Icons.sick_outlined,
                          color: Colors.blue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Current Health Condition
                    TextField(
                      controller: _healthConditionController,
                      decoration: InputDecoration(
                        labelText: "Current Health Condition",
                        hintText: "e.g., Hypertension, Diabetes (or None)",
                        prefixIcon: const Icon(
                          Icons.healing_outlined,
                          color: Colors.blue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Allergies
                    TextField(
                      controller: _allergiesController,
                      decoration: InputDecoration(
                        labelText: "Allergies",
                        hintText: "e.g., Penicillin, Dust, Peanuts (or None)",
                        prefixIcon: const Icon(
                          Icons.warning_amber_outlined,
                          color: Colors.blue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Current Medications
                    TextField(
                      controller: _medicationsController,
                      decoration: InputDecoration(
                        labelText: "Current Medications",
                        hintText:
                            "e.g., Metformin 500mg, Paracetamol (or None)",
                        prefixIcon: const Icon(
                          Icons.medication_outlined,
                          color: Colors.blue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Important Note
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Please arrive 15 minutes before your appointment and carry any previous medical reports if available.",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isChecking
                  ? null
                  : () async {
                      setState(() => _isChecking = true);
                      try {
                        final isAvailable =
                            await BookingService.checkSlotAvailability(
                          doctorName: widget.DocName,
                          date: widget.selectedDay,
                          time: widget.selectedTime,
                        );

                        if (!mounted || !context.mounted) return;

                        if (!isAvailable) {
                          setState(() => _isChecking = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "This time slot is already booked. Please select another slot.",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                      } catch (e) {
                        debugPrint("Availability check error: $e");
                      }

                      if (!mounted || !context.mounted) return;
                      setState(() => _isChecking = false);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: ((context) => PaymentPage(
                                docName: widget.DocName,
                                specialist: widget.docspecialist,
                                date: widget.selectedDay,
                                time: widget.selectedTime,
                                fee: widget.fee,
                                docPic: widget.docPic,
                                symptoms: _symptomsController.text.trim(),
                                healthCondition:
                                    _healthConditionController.text.trim(),
                                allergies: _allergiesController.text.trim(),
                                medications: _medicationsController.text.trim(),
                                patientName: _patientName,
                              )),
                        ),
                      );
                    },
              child: _isChecking
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Confirm Booking",
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),



      
    );
  }
}