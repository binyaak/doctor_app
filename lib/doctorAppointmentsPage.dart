import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_app/doctorAppointmentDetailsPage.dart';
import 'package:flutter/material.dart';

// ===========================================================
// DOCTOR APPOINTMENTS PAGE
// ===========================================================
// Shows all appointments belonging to the logged-in doctor.
//
// How filtering works:
//   - We query the 'appointments' collection where:
//     'doctorName' == doctorName (passed from dashboard)
//   - Includes filter tabs: All, Booked (Pending), Accepted, Completed, Cancelled
//   - Provides clear error handling and troubleshooting info if
//     Firestore rules block permissions.
// ===========================================================

class DoctorAppointmentsPage extends StatefulWidget {
  final String doctorName;

  const DoctorAppointmentsPage({
    super.key,
    required this.doctorName,
  });

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  String selectedFilter = 'All';
  int _refreshKey = 0;

  // -------------------------------------------------------
  // STATUS BADGE COLOR
  // -------------------------------------------------------
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'booked':
      default:
        return Colors.orange;
    }
  }

  void _retry() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cleanDocName = widget.doctorName.trim();

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Appointments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _retry,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Booked'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Accepted'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Cancelled'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xffE2E8F0)),

          // Main Appointments Stream
          Expanded(
            child: cleanDocName.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Doctor name is missing. Please update your profile.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    key: ValueKey(_refreshKey),
                    stream: FirebaseFirestore.instance
                        .collection('appointments')
                        .where('doctorName', isEqualTo: cleanDocName)
                        .snapshots(),
                    builder: (context, snapshot) {
                      // LOADING STATE
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.teal),
                        );
                      }

                      // ERROR STATE (Permissions / Firestore error)
                      if (snapshot.hasError) {
                        final isPermissionError = snapshot.error
                            .toString()
                            .contains('permission-denied');

                        return Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPermissionError
                                          ? Icons.lock_outline
                                          : Icons.error_outline,
                                      size: 54,
                                      color: Colors.red.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      isPermissionError
                                          ? 'Permission Denied'
                                          : 'Failed to Load Appointments',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      isPermissionError
                                          ? 'Firestore Security Rules in Firebase Console are blocking access to appointments for this doctor account.\n\nPlease update and publish your firestore.rules in Firebase Console.'
                                          : 'Error: ${snapshot.error}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: _retry,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Try Again'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final allDocs = snapshot.data?.docs ?? [];

                      // Apply Client Filter
                      final filteredDocs = allDocs.where((doc) {
                        if (selectedFilter == 'All') return true;
                        final data = doc.data() as Map<String, dynamic>;
                        final status = (data['status'] ?? 'Booked').toString();
                        if (selectedFilter == 'Cancelled') {
                          return status.toLowerCase() == 'cancelled' ||
                              status.toLowerCase() == 'rejected';
                        }
                        return status.toLowerCase() ==
                            selectedFilter.toLowerCase();
                      }).toList();

                      // EMPTY STATE
                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                selectedFilter == 'All'
                                    ? 'No appointments yet'
                                    : 'No $selectedFilter appointments',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedFilter == 'All'
                                    ? 'Patient appointments booked for you will appear here.'
                                    : 'There are no appointments with status "$selectedFilter".',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      // Sort by createdAt (newest first)
                      final sortedDocs =
                          List<QueryDocumentSnapshot>.from(filteredDocs);
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

                      // APPOINTMENTS LIST
                      return RefreshIndicator(
                        color: Colors.teal,
                        onRefresh: () async => _retry(),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: sortedDocs.length,
                          itemBuilder: (context, index) {
                            final doc = sortedDocs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final appointmentId = doc.id;

                            // Read appointment fields
                            final patientName = data['patientName'] ??
                                data['userName'] ??
                                'Patient';
                            final date = data['date'] ?? 'N/A';
                            final time = data['time'] ?? 'N/A';
                            final rawDocName = (data['doctorName'] ?? '').toString();
                            String cleanDocName = rawDocName.replaceAll('"', '').trim();
                            if (cleanDocName.isNotEmpty &&
                                !cleanDocName.toLowerCase().startsWith('dr.') &&
                                !cleanDocName.toLowerCase().startsWith('dr ')) {
                              cleanDocName = 'Dr. $cleanDocName';
                            }
                            final status = data['status'] ?? 'Booked';
                            final paymentStatus =
                                data['paymentStatus'] ?? 'Paid';
                            final fee = data['fee'] ?? '';

                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DoctorAppointmentDetailsPage(
                                        appointmentId: appointmentId,
                                        appointmentData: data,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // TOP ROW: Patient Name + Status Badge
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor:
                                                    Colors.teal.shade50,
                                                child: const Icon(
                                                  Icons.person,
                                                  color: Colors.teal,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              _PatientNameWidget(
                                                initialName: patientName,
                                                userId: data['userId']?.toString(),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _statusColor(status)
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: _statusColor(status),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const Divider(height: 20),

                                      // DATE + TIME ROW
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            date,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          const Icon(
                                            Icons.access_time_outlined,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            time,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (fee.isNotEmpty)
                                            Text(
                                              'Fee: $fee',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      // DOCTOR NAME + PAYMENT STATUS
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.medical_services_outlined,
                                            size: 16,
                                            color: Colors.teal,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              cleanDocName,
                                              style: TextStyle(
                                                color: Colors.teal.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (paymentStatus.isNotEmpty) ...[
                                            const Icon(
                                              Icons.check_circle_outline,
                                              size: 15,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              paymentStatus,
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      // TAP TO VIEW DETAILS ROW
                                      const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'View Details',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.teal,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 11,
                                            color: Colors.teal,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.teal.shade50,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.teal : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? Colors.teal : Colors.grey.shade300,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            selectedFilter = label;
          });
        }
      },
    );
  }
}

// ===========================================================
// PATIENT NAME RESOLVER WIDGET
// ===========================================================
// Displays the patient's name. If the appointment record only
// has 'Patient' or is missing the name, it looks up the 'users'
// collection using userId with in-memory caching.
// ===========================================================
class _PatientNameWidget extends StatelessWidget {
  final String? initialName;
  final String? userId;

  const _PatientNameWidget({
    this.initialName,
    this.userId,
  });

  static final Map<String, String> _nameCache = {};

  @override
  Widget build(BuildContext context) {
    final cleanInitial = initialName?.trim();

    // If a real name already exists on the appointment, use it directly
    if (cleanInitial != null &&
        cleanInitial.isNotEmpty &&
        cleanInitial.toLowerCase() != 'patient') {
      return Text(
        cleanInitial,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // If no userId, fall back to default
    if (userId == null || userId!.trim().isEmpty) {
      return const Text(
        'Patient',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final trimmedUid = userId!.trim();

    // Check in-memory cache
    if (_nameCache.containsKey(trimmedUid)) {
      return Text(
        _nameCache[trimmedUid]!,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Asynchronously resolve from 'users' collection
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(trimmedUid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final realName = data?['name']?.toString().trim();
          if (realName != null && realName.isNotEmpty) {
            _nameCache[trimmedUid] = realName;
            return Text(
              realName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            );
          }
        }

        return Text(
          cleanInitial?.isNotEmpty == true ? cleanInitial! : 'Patient',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}
