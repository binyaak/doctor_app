import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class BookingService {
  /// Normalizes date string to 'D/M/YYYY' without leading zeroes
  static String normalizeDateString(String dateStr) {
    final parts = dateStr.trim().split(RegExp(r'[/.-]'));
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        return "$d/$m/$y";
      }
    }
    return dateStr.trim();
  }

  /// Normalizes time string (e.g. '09:00 AM' -> '09.00 AM')
  static String normalizeTimeString(String timeStr) {
    return timeStr
        .trim()
        .replaceAll(':', '.')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toUpperCase();
  }

  /// Generates a deterministic document ID for a doctor's date & time slot
  static String generateSlotDocId({
    required String doctorName,
    required String date,
    required String time,
  }) {
    final normDoc = doctorName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final normDate = normalizeDateString(date).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final normTime = normalizeTimeString(time).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return "slot_${normDoc}_${normDate}_$normTime";
  }

  /// Checks if a time matches any booked time slot
  static bool isTimeSlotBooked(String time, Iterable<String> bookedTimes) {
    final target = normalizeTimeString(time);
    return bookedTimes.any((booked) => normalizeTimeString(booked) == target);
  }

  /// Returns a stream of booked time slot strings for the given doctor & selected date
  static Stream<Set<String>> getBookedSlotsStream({
    required String doctorName,
    required DateTime selectedDay,
    FirebaseFirestore? firestore,
  }) {
    final db = firestore ?? FirebaseFirestore.instance;
    final cleanDocName = doctorName.trim();
    final formattedDate = "${selectedDay.day}/${selectedDay.month}/${selectedDay.year}";
    final paddedDate =
        "${selectedDay.day.toString().padLeft(2, '0')}/${selectedDay.month.toString().padLeft(2, '0')}/${selectedDay.year}";

    return db
        .collection('appointments')
        .where('doctorName', isEqualTo: cleanDocName)
        .snapshots()
        .map((snapshot) {
      final booked = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? 'Booked').toString().toLowerCase();
        if (status == 'cancelled') continue;

        final docDate = data['date']?.toString().trim() ?? '';
        final normDocDate = normalizeDateString(docDate);
        if (docDate == formattedDate ||
            docDate == paddedDate ||
            normDocDate == normalizeDateString(formattedDate)) {
          final docTime = data['time']?.toString().trim();
          if (docTime != null && docTime.isNotEmpty) {
            booked.add(docTime);
          }
        }
      }
      return booked;
    });
  }

  /// Checks whether a specific doctor's slot is available in Firestore
  static Future<bool> checkSlotAvailability({
    required String doctorName,
    required String date,
    required String time,
    FirebaseFirestore? firestore,
  }) async {
    final db = firestore ?? FirebaseFirestore.instance;
    final cleanDoc = doctorName.trim();
    final normDate = normalizeDateString(date);
    final normTime = normalizeTimeString(time);

    // 1. Check deterministic slot doc ID
    final slotDocId = generateSlotDocId(
      doctorName: cleanDoc,
      date: date,
      time: time,
    );

    try {
      final slotDoc = await db.collection('appointments').doc(slotDocId).get();
      if (slotDoc.exists) {
        final data = slotDoc.data();
        final status = (data?['status'] ?? 'Booked').toString().toLowerCase();
        if (status != 'cancelled') {
          return false; // occupied
        }
      }
    } catch (e) {
      debugPrint("Error checking slot doc: $e");
    }

    // 2. Check query for doctor's appointments
    try {
      final query = await db
          .collection('appointments')
          .where('doctorName', isEqualTo: cleanDoc)
          .get();

      for (final doc in query.docs) {
        if (doc.id == slotDocId) continue;
        final data = doc.data();
        final status = (data['status'] ?? 'Booked').toString().toLowerCase();
        if (status == 'cancelled') continue;

        final docDate = normalizeDateString(data['date']?.toString() ?? '');
        final docTime = normalizeTimeString(data['time']?.toString() ?? '');

        if (docDate == normDate && docTime == normTime) {
          return false; // occupied
        }
      }
    } catch (e) {
      debugPrint("Error checking appointment query: $e");
    }

    return true; // available
  }

  /// Uses a Firestore transaction to book the slot atomically and prevent double booking
  static Future<void> bookAppointmentWithTransaction({
    required String userId,
    required String patientName,
    required String doctorName,
    required String specialist,
    required String docPic,
    required String date,
    required String time,
    required String fee,
    String paymentId = 'razorpay_demo',
    String paymentStatus = 'Paid',
    String symptoms = '',
    String healthCondition = '',
    String allergies = '',
    String medications = '',
    FirebaseFirestore? firestore,
  }) async {
    final db = firestore ?? FirebaseFirestore.instance;
    final cleanDoc = doctorName.trim();
    final normDate = normalizeDateString(date);
    final normTime = normalizeTimeString(time);

    final slotDocId = generateSlotDocId(
      doctorName: cleanDoc,
      date: date,
      time: time,
    );
    final slotRef = db.collection('appointments').doc(slotDocId);

    // 1. Check for legacy bookings that might have an auto-generated doc ID
    final legacyQuery = await db
        .collection('appointments')
        .where('doctorName', isEqualTo: cleanDoc)
        .get();

    for (final doc in legacyQuery.docs) {
      if (doc.id == slotDocId) continue;
      final data = doc.data();
      final status = (data['status'] ?? 'Booked').toString().toLowerCase();
      if (status == 'cancelled') continue;

      final docDate = normalizeDateString(data['date']?.toString() ?? '');
      final docTime = normalizeTimeString(data['time']?.toString() ?? '');

      if (docDate == normDate && docTime == normTime) {
        throw Exception("This time slot is already booked. Please select another slot.");
      }
    }

    // 2. Transactionally check slotRef and book if available
    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(slotRef);

      if (snapshot.exists) {
        final data = snapshot.data();
        final status = (data?['status'] ?? 'Booked').toString().toLowerCase();
        if (status != 'cancelled') {
          throw Exception("This time slot is already booked. Please select another slot.");
        }
      }

      transaction.set(slotRef, {
        'userId': userId,
        'patientName': patientName,
        'doctorName': cleanDoc,
        'specialist': specialist,
        'doctorImage': docPic.isNotEmpty ? docPic : 'asset/doc1.png',
        'docPic': docPic.isNotEmpty ? docPic : 'asset/doc1.png',
        'date': date,
        'time': time,
        'fee': fee,
        'paymentId': paymentId,
        'paymentStatus': paymentStatus,
        'status': 'Booked',
        'createdAt': FieldValue.serverTimestamp(),
        'symptoms': symptoms,
        'healthCondition': healthCondition,
        'allergies': allergies,
        'medications': medications,
      });
    });
  }
}
