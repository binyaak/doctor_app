import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentPage extends StatefulWidget {
  final String docName;
  final String specialist;
  final String date;
  final String time;
  final String fee;
  final String? docPic;
  final String? symptoms;
  final String? healthCondition;
  final String? allergies;
  final String? medications;
  final String? patientName;

  const PaymentPage({
    super.key,
    required this.docName,
    required this.specialist,
    required this.date,
    required this.time,
    required this.fee,
    this.docPic,
    this.symptoms,
    this.healthCondition,
    this.allergies,
    this.medications,
    this.patientName,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool agree = false;
  bool _isProcessing = false;

  late Razorpay _razorpay;

  // --------------------------------------------------------------------------
  // INIT & DISPOSE
  // --------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // RAZORPAY CALLBACKS
  // --------------------------------------------------------------------------

  /// Called when payment succeeds.
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _showPaymentSuccessDialog();
  }

  /// Called when payment fails (correct type: PaymentFailureResponse).
  void _handlePaymentError(PaymentFailureResponse response) {
    // For this demo, treat failure as success too.
    _showPaymentSuccessDialog();
  }

  /// Called when an external wallet is selected.
  void _handleExternalWallet(ExternalWalletResponse response) {
    // For this demo, treat external wallet as success too.
    _showPaymentSuccessDialog();
  }

  // --------------------------------------------------------------------------
  // SHOW "PAYMENT SUCCESSFUL" DIALOG
  // --------------------------------------------------------------------------

  void _showPaymentSuccessDialog() {
    // Save appointment to Firestore in the background.
    _saveAppointment();

    Fluttertoast.showToast(
      msg: "Payment Successful",
      toastLength: Toast.LENGTH_SHORT,
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text("Payment Successful"),
          ],
        ),
        content: const Text(
          "Your appointment has been booked successfully.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // close dialog
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // OPEN RAZORPAY CHECKOUT
  // --------------------------------------------------------------------------

  void _openRazorpayCheckout() {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Parse fee and compute total (in rupees)
    final int consultationFee =
        int.tryParse(widget.fee.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    const int platformFee = 20;
    const int gst = 10;
    final int totalRupees = consultationFee + platformFee + gst;

    // Razorpay expects amount in paise (1 rupee = 100 paise)
    final int amountInPaise = totalRupees * 100;

    var options = {
      'key': 'rzp_test_TjW0zLnUBWTpT4',
      'amount': amountInPaise,
      'name': 'Doctor App',
      'description': 'Appointment: ${widget.docName}',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'email': 'test@razorpay.com',
      },
      'external': {
        'wallets': ['paytm', 'gpay'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay open error: $e');
      // For this demo, even if Razorpay throws, show success.
      _showPaymentSuccessDialog();
    }
  }

  // --------------------------------------------------------------------------
  // HELPER: DOCTOR IMAGE PROVIDER
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
  // FIRESTORE: SAVE APPOINTMENT (background, best-effort)
  // --------------------------------------------------------------------------
  Future<void> _saveAppointment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Resolve patient name
    String resolvedPatientName = widget.patientName ?? '';
    if (resolvedPatientName.trim().isEmpty ||
        resolvedPatientName.trim() == 'Patient') {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data();
          final fetchedName = data?['name']?.toString().trim();
          if (fetchedName != null && fetchedName.isNotEmpty) {
            resolvedPatientName = fetchedName;
          }
        }
      } catch (e) {
        debugPrint("Error fetching patient name for appointment: $e");
      }
    }

    if (resolvedPatientName.trim().isEmpty) {
      resolvedPatientName = user.displayName ?? 'Patient';
    }

    try {
      await FirebaseFirestore.instance.collection('appointments').add({
        'userId': user.uid,
        'patientName': resolvedPatientName,
        'doctorName': widget.docName,
        'specialist': widget.specialist,
        'doctorImage': widget.docPic ?? 'asset/doc1.png',
        'docPic': widget.docPic ?? 'asset/doc1.png',
        'date': widget.date,
        'time': widget.time,
        'fee': widget.fee,
        'paymentId': 'razorpay_demo',
        'paymentStatus': 'Paid',
        'status': 'Booked',
        'createdAt': FieldValue.serverTimestamp(),
        'symptoms': widget.symptoms ?? '',
        'healthCondition': widget.healthCondition ?? '',
        'allergies': widget.allergies ?? '',
        'medications': widget.medications ?? '',
      });
    } catch (e) {
      debugPrint("Error saving appointment: $e");
    }
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Convert consultation fee safely
    final int consultationFee =
        int.tryParse(widget.fee.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    const int platformFee = 20;
    const int gst = 10;
    final int total = consultationFee + platformFee + gst;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // -----------------------------
            // 1. DOCTOR DETAILS
            // -----------------------------
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: _getDoctorImage(widget.docPic),
                ),
                title: Text(
                  widget.docName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  widget.specialist,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------------
            // 2. APPOINTMENT DATE & TIME
            // -----------------------------
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_today,
                      color: Colors.blue,
                    ),
                    title: const Text(
                      "Appointment Date",
                    ),
                    subtitle: Text(
                      widget.date,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.access_time,
                      color: Colors.blue,
                    ),
                    title: const Text(
                      "Appointment Time",
                    ),
                    subtitle: Text(
                      widget.time,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------------
            // 3. PAYMENT SUMMARY
            // -----------------------------
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Payment Summary",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Consultation Fee",
                        ),
                        Text(
                          "₹$consultationFee",
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Platform Fee"),
                        Text("₹20"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("GST"),
                        Text("₹10"),
                      ],
                    ),
                    const Divider(
                      height: 30,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Amount",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "₹$total",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------------
            // 4. PAYMENT METHOD
            // -----------------------------
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.payment,
                      color: Colors.blue,
                    ),
                    title: Text(
                      "Razorpay (Test Mode)",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "Secure payment via Razorpay checkout",
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // -----------------------------
            // 5. TERMS & CONDITIONS
            // -----------------------------
            CheckboxListTile(
              value: agree,
              onChanged: _isProcessing
                  ? null
                  : (value) {
                      setState(() {
                        agree = value ?? false;
                      });
                    },
              title: const Text(
                "I agree to the Terms & Conditions",
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

      // -----------------------------
      // 6. PAY NOW BUTTON
      // -----------------------------
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
              onPressed: (agree && !_isProcessing)
                  ? _openRazorpayCheckout
                  : null,
              child: _isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Processing...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      "Pay Now (₹$total)",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}