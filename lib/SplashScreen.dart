import 'dart:async';
import 'package:doctor_app/doctorLoginPage.dart';
import 'package:flutter/material.dart';
import 'loginPage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? timer;

  @override
  void initState() {
    super.initState();

   timer= Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

     Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (context) => const LoginPage(),
  ),
);
    });
  }

  @override
  void dispose(){
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     backgroundColor: Colors.blue,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // App Icon
            Container(
              height: 110,
              width: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.medical_services,
                size: 65,
                color: Colors.blue,
              ),
          /*  child: SizedBox(
              width: 65,height: 65,
              child: Image.asset("asset/logo.jpg")),*/
            ),

            const SizedBox(height: 25),

            const Text(
              "Doctor App",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Book your doctor appointment easily",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 40),

            const CircularProgressIndicator(
              color: Colors.white,
            ),

            const SizedBox(height: 30),

            // DOCTOR LOGIN BUTTON
            // Doctors tap this to go directly to DoctorLoginPage.
            // Patient login flow is not affected — it still loads after
            // the 3-second timer via Navigator.pushReplacement.
            TextButton(
              onPressed: () {
                timer?.cancel();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorLoginPage(),
                  ),
                );
              },
              child: const Text(
                'Doctor? Login Here',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}