import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'adminDoctorsPage.dart';
import 'adminUsersPage.dart';
import 'adminAppointmentsPage.dart';
import 'LoginPage.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int totalUsers = 0;
  int totalDoctors = 0;
  int totalAppointments = 0;
  bool isLoadingCounts = true;

  @override
  void initState() {
    super.initState();
    loadDashboardCounts();
  }

  // ----------------------------------------------------
  // LOAD FIRESTORE COUNTS
  // ----------------------------------------------------
  Future<void> loadDashboardCounts() async {
    setState(() {
      isLoadingCounts = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Get count of users collection
      final usersSnap = await firestore.collection('users').get();
      // Get count of doctors collection
      final doctorsSnap = await firestore.collection('doctors').get();
      // Get count of appointments collection
      final appointmentsSnap = await firestore.collection('appointments').get();

      if (!mounted) return;

      setState(() {
        totalUsers = usersSnap.docs.length;
        totalDoctors = doctorsSnap.docs.length;
        totalAppointments = appointmentsSnap.docs.length;
        isLoadingCounts = false;
      });
    } catch (e) {
      debugPrint("Error loading admin dashboard counts: $e");
      if (mounted) {
        setState(() {
          isLoadingCounts = false;
        });
      }
    }
  }

  // ----------------------------------------------------
  // LOGOUT
  // ----------------------------------------------------
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  // ----------------------------------------------------
  // HELPER METRIC CARD
  // ----------------------------------------------------
  Widget _buildMetricCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withAlpha(35),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh counts",
            onPressed: loadDashboardCounts,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboardCounts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              const Text(
                "Welcome, Administrator",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Overview of platform statistics and controls",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 16),

              // Summary Cards Row
              if (isLoadingCounts)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: "Total Users",
                        count: totalUsers.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        title: "Total Doctors",
                        count: totalDoctors.toString(),
                        icon: Icons.medical_services,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        title: "Total Appts",
                        count: totalAppointments.toString(),
                        icon: Icons.calendar_month,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              const Text(
                "Management Actions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              // 1. Manage Doctors
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withAlpha(30),
                    child: const Icon(Icons.people_alt, color: Colors.blue),
                  ),
                  title: const Text(
                    "Manage Doctors",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("View, add, edit, or delete doctors"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDoctorsPage(),
                      ),
                    ).then((_) => loadDashboardCounts());
                  },
                ),
              ),

              const SizedBox(height: 8),

              // 2. View Users
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.withAlpha(30),
                    child: const Icon(Icons.badge, color: Colors.teal),
                  ),
                  title: const Text(
                    "View Users",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("View registered patients & health records"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminUsersPage(),
                      ),
                    ).then((_) => loadDashboardCounts());
                  },
                ),
              ),

              const SizedBox(height: 8),

              // 3. View Appointments
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withAlpha(30),
                    child: const Icon(Icons.event_note, color: Colors.orange),
                  ),
                  title: const Text(
                    "View Appointments",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("View all booked & completed appointments"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminAppointmentsPage(),
                      ),
                    ).then((_) => loadDashboardCounts());
                  },
                ),
              ),

              const SizedBox(height: 24),

              // 4. Logout Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: logout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
