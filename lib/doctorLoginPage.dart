import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_app/doctorDashboardPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ===========================================================
// DOCTOR LOGIN PAGE
// ===========================================================
// How it works:
// 1. Doctor enters email + password.
// 2. We sign in using FirebaseAuth (same Auth project, no duplicate setup).
// 3. After login, we look up the 'doctors' collection in Firestore
//    to find a document whose 'DocName' or email matches.
//    We search by the logged-in user's email field.
// 4. If found -> go to DoctorDashboardPage.
// 5. If NOT found -> show error: "Not a registered doctor account".
//    This prevents a patient account from accessing the doctor panel.
// ===========================================================

class DoctorLoginPage extends StatefulWidget {
  const DoctorLoginPage({super.key});

  @override
  State<DoctorLoginPage> createState() => _DoctorLoginPageState();
}

class _DoctorLoginPageState extends State<DoctorLoginPage> {
  // Text controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  // -------------------------------------------------------
  // DOCTOR LOGIN FUNCTION
  // -------------------------------------------------------
  Future<void> loginDoctor() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Step 1: Sign in with FirebaseAuth
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception("Authentication succeeded but user is null.");
      }

      print("LOGIN UID: ${user.uid}");
      print("LOGIN EMAIL: ${user.email}");

      // Step 2: Check the doctor's Firestore record using the SAME UID created during registration
      DocumentSnapshot<Map<String, dynamic>> doctorDoc = await FirebaseFirestore
          .instance
          .collection('doctors')
          .doc(user.uid)
          .get();

      print("DOCTOR DOCUMENT EXISTS: ${doctorDoc.exists}");
      print("DOCTOR DATA: ${doctorDoc.data()}");

      Map<String, dynamic>? doctorData;
      String doctorId = user.uid;

      if (doctorDoc.exists && doctorDoc.data() != null) {
        doctorData = doctorDoc.data();
      } else {
        // Fallback: If not found by UID, check if document was created with an auto-id
        // (e.g. by admin or older registration) matching this email
        final cleanEmail = email.toLowerCase();
        var querySnapshot = await FirebaseFirestore.instance
            .collection('doctors')
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          querySnapshot = await FirebaseFirestore.instance
              .collection('doctors')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
        }

        if (querySnapshot.docs.isEmpty && user.email != null) {
          querySnapshot = await FirebaseFirestore.instance
              .collection('doctors')
              .where('email', isEqualTo: user.email)
              .limit(1)
              .get();
        }

        if (querySnapshot.docs.isNotEmpty) {
          final matchedDoc = querySnapshot.docs.first;
          doctorData = matchedDoc.data();
          doctorId = matchedDoc.id;
          print("DOCTOR FOUND VIA EMAIL FALLBACK: ${matchedDoc.id}");
          print("DOCTOR DATA: $doctorData");

          // Link to doc(user.uid) so future logins use direct UID lookup
          try {
            await FirebaseFirestore.instance
                .collection('doctors')
                .doc(user.uid)
                .set({
              ...doctorData,
              'uid': user.uid,
              'role': 'doctor',
            }, SetOptions(merge: true));
            doctorId = user.uid;
          } catch (e) {
            print("Sync doc error: $e");
          }
        }
      }

      if (!mounted) return;

      if (doctorData == null) {
        // This Firebase account exists (e.g. Patient account) but is NOT a doctor.
        final messenger = ScaffoldMessenger.of(context);
        await FirebaseAuth.instance.signOut();

        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'This account is not registered as a doctor. Please use Patient Login.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Step 3: Navigate to Doctor Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DoctorDashboardPage(
            doctorId: doctorId,
            doctorData: doctorData!,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------
  // BUILD
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Icon
              const Center(
                child: Icon(
                  Icons.medical_services,
                  size: 80,
                  color: Colors.teal,
                ),
              ),

              const SizedBox(height: 16),

              // Title
              const Center(
                child: Text(
                  'Doctor Portal',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  'Login to manage your appointments',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Doctor Login',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              // EMAIL FIELD
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email, color: Colors.teal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // PASSWORD FIELD
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock, color: Colors.teal),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isLoading ? null : loginDoctor,
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // BACK TO PATIENT LOGIN
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Patient Login'),
                ),
              ),

              const SizedBox(height: 30),

              // INFO CARD
              Card(
                color: Colors.teal.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.teal, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This login is only for registered doctors. '
                          'Your email must be saved in the doctors database. '
                          'Patients should use the Patient Login screen.',
                          style: TextStyle(fontSize: 13, color: Colors.teal),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
