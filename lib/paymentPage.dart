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
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;

  bool agree = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      handlePaymentSuccess,
    );

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      handlePaymentError,
    );

    _razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      handleExternalWallet,
    );
  }

  // -----------------------------
  // OPEN RAZORPAY
  // -----------------------------
  void openRazorpay() {
    final int consultationFee =
        int.tryParse(
          widget.fee.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    const int platformFee = 20;
    const int gst = 10;

    final int total =
        consultationFee + platformFee + gst;

    final options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag',

      // Amount must be in paise
      'amount': total * 100,

      'name': 'Doctor App',
      'description': 'Doctor Consultation',

      'retry': {
        'enabled': true,
        'max_count': 1,
      },

      'prefill': {
        'contact': '8888888888',
        'email': 'test@razorpay.com',
      },

      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay Error: $e");
    }
  }

  // -----------------------------
  // SAVE APPOINTMENT
  // -----------------------------
  Future<void> saveAppointment() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint("User is not logged in");
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .add({
        'userId': user.uid,

        'doctorName': widget.docName,
        'specialist': widget.specialist,
        'doctorImage': widget.docPic ?? 'asset/doc1.png',

        'date': widget.date,
        'time': widget.time,
        'fee': widget.fee,

        'status': 'Booked',
        'paymentStatus': 'Paid',

        'createdAt': FieldValue.serverTimestamp(),

        'symptoms': widget.symptoms ?? '',
        'healthCondition': widget.healthCondition ?? '',
        'allergies': widget.allergies ?? '',
        'medications': widget.medications ?? '',
      });

      debugPrint("Appointment saved successfully");
    } catch (e) {
      debugPrint("Error saving appointment: $e");
    }
  }

  // -----------------------------
  // PAYMENT SUCCESS
  // -----------------------------
 void handlePaymentSuccess(
  PaymentSuccessResponse response,
) async {
  // Prevent duplicate Firestore entries
  if (isSaving) return;

  isSaving = true;

  await saveAppointment();

  Fluttertoast.showToast(
    msg: "Appointment Booked Successfully!",
    toastLength: Toast.LENGTH_SHORT,
  );

  if (!mounted) return;

  Navigator.popUntil(
    context,
    (route) => route.isFirst,
  );
}

  // -----------------------------
  // PAYMENT ERROR
  // -----------------------------
  void handlePaymentError(
    PaymentFailureResponse response,
  ) {
    Fluttertoast.showToast(
      msg: "Payment Failed",
      toastLength: Toast.LENGTH_SHORT,
    );

    debugPrint(
      "Payment Error: ${response.code} - ${response.message}",
    );
  }

  // -----------------------------
  // EXTERNAL WALLET
  // -----------------------------
  void handleExternalWallet(
    ExternalWalletResponse response,
  ) {
    Fluttertoast.showToast(
      msg: "External Wallet: ${response.walletName}",
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // Convert fee safely
    final int consultationFee =
        int.tryParse(
          widget.fee.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    const int platformFee = 20;
    const int gst = 10;

    final int total =
        consultationFee + platformFee + gst;

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
            // DOCTOR
            // -----------------------------
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),

              child: ListTile(
                leading: const CircleAvatar(
                  radius: 28,
                  child: Icon(Icons.person),
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
            // APPOINTMENT
            // -----------------------------
            Card(
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

                  const Divider(),

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
            // PAYMENT SUMMARY
            // -----------------------------
            Card(
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
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,

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

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,

                      children: const [
                        Text("Platform Fee"),
                        Text("₹20"),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,

                      children: const [
                        Text("GST"),
                        Text("₹10"),
                      ],
                    ),

                    const Divider(
                      height: 30,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,

                      children: [

                        const Text(
                          "Total",

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
            // PAYMENT METHODS
            // -----------------------------
            Card(
              child: Column(
                children: const [

                  ListTile(
                    leading: Icon(
                      Icons.account_balance_wallet,
                      color: Colors.blue,
                    ),

                    title: Text(
                      "Razorpay",
                    ),

                    trailing: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),

                  Divider(),

                  ListTile(
                    leading: Icon(
                      Icons.credit_card,
                    ),

                    title: Text(
                      "Credit / Debit Card",
                    ),
                  ),

                  Divider(),

                  ListTile(
                    leading: Icon(
                      Icons.account_balance,
                    ),

                    title: Text(
                      "Net Banking",
                    ),
                  ),

                  Divider(),

                  ListTile(
                    leading: Icon(
                      Icons.currency_rupee,
                    ),

                    title: Text(
                      "UPI",
                    ),
                  ),
                ],
              ),
            ),

            // -----------------------------
            // TERMS
            // -----------------------------
            CheckboxListTile(
              value: agree,

              onChanged: (value) {
                setState(() {
                  agree = value ?? false;
                });
              },

              title: const Text(
                "I agree to the Terms & Conditions",
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

      // -----------------------------
      // PAY BUTTON
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
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),

              onPressed: agree
                  ? openRazorpay
                  : null,

              child: Text(
                "Pay ₹$total",

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}