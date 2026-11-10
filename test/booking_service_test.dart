import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_app/bookingService.dart';

void main() {
  group('BookingService - Double Booking Prevention Tests', () {
    test('generateSlotDocId produces consistent, deterministic IDs', () {
      final id1 = BookingService.generateSlotDocId(
        doctorName: 'Dr. Jenny Wilson',
        date: '10/11/2026',
        time: '09.00 AM',
      );

      final id2 = BookingService.generateSlotDocId(
        doctorName: 'Dr. Jenny Wilson',
        date: '10/11/2026',
        time: '09.00 AM',
      );

      expect(id1, equals(id2));
      expect(id1, contains('slot_dr__jenny_wilson'));
      expect(id1, contains('10_11_2026'));
      expect(id1, contains('09_00_AM'));
    });

    test('generateSlotDocId matches formatted and unformatted variations', () {
      // Different date padding (e.g. 5/3/2026 vs 05/03/2026)
      final idWithLeadingZero = BookingService.generateSlotDocId(
        doctorName: 'Dr. John Doe',
        date: '05/03/2026',
        time: '10:00 AM',
      );

      final idWithoutLeadingZero = BookingService.generateSlotDocId(
        doctorName: 'Dr. John Doe',
        date: '5/3/2026',
        time: '10.00 AM',
      );

      expect(idWithLeadingZero, equals(idWithoutLeadingZero));
    });

    test('isTimeSlotBooked detects occupied slots with time formatting variations', () {
      final bookedList = {'09.00 AM', '10.30 AM', '04.00 PM'};

      // Exact match
      expect(BookingService.isTimeSlotBooked('09.00 AM', bookedList), isTrue);

      // Colon format match ('09:00 AM' vs '09.00 AM')
      expect(BookingService.isTimeSlotBooked('09:00 AM', bookedList), isTrue);

      // Lowercase match ('09.00 am')
      expect(BookingService.isTimeSlotBooked('09.00 am', bookedList), isTrue);

      // Available slot
      expect(BookingService.isTimeSlotBooked('11.00 AM', bookedList), isFalse);
      expect(BookingService.isTimeSlotBooked('03.00 PM', bookedList), isFalse);
    });

    test('normalizeDateString normalizes different date delimiters and leading zeroes', () {
      expect(BookingService.normalizeDateString('05/03/2026'), equals('5/3/2026'));
      expect(BookingService.normalizeDateString('5/3/2026'), equals('5/3/2026'));
      expect(BookingService.normalizeDateString('10/11/2026'), equals('10/11/2026'));
      expect(BookingService.normalizeDateString('01-09-2025'), equals('1/9/2025'));
    });

    test('normalizeTimeString standardizes dots, colons and whitespace', () {
      expect(BookingService.normalizeTimeString('09:00 AM'), equals('09.00 AM'));
      expect(BookingService.normalizeTimeString('09.00  AM'), equals('09.00 AM'));
      expect(BookingService.normalizeTimeString('09.00 am'), equals('09.00 AM'));
    });

    test('Two different patients booking the exact same doctor slot target the same ID', () {
      const doctor = 'Dr. Jenny Wilson';
      const date = '15/12/2026';
      const time = '10.30 AM';

      // Patient A booking attempt
      final patientASlotId = BookingService.generateSlotDocId(
        doctorName: doctor,
        date: date,
        time: time,
      );

      // Patient B booking attempt
      final patientBSlotId = BookingService.generateSlotDocId(
        doctorName: doctor,
        date: date,
        time: time,
      );

      // Both target the exact same Firestore document reference
      expect(patientASlotId, equals(patientBSlotId));
    });

    test('Different slots produce different IDs', () {
      const doctor = 'Dr. Jenny Wilson';

      final slot1 = BookingService.generateSlotDocId(
        doctorName: doctor,
        date: '15/12/2026',
        time: '10.00 AM',
      );

      final slot2 = BookingService.generateSlotDocId(
        doctorName: doctor,
        date: '15/12/2026',
        time: '10.30 AM',
      );

      final slot3 = BookingService.generateSlotDocId(
        doctorName: doctor,
        date: '16/12/2026',
        time: '10.00 AM',
      );

      expect(slot1, isNot(equals(slot2)));
      expect(slot1, isNot(equals(slot3)));
      expect(slot2, isNot(equals(slot3)));
    });

    test('Simulated transaction prevents two patients from booking the same slot simultaneously', () async {
      final Map<String, Map<String, dynamic>> firestoreData = {};

      Future<void> simulateTransactionBooking({
        required String patientId,
        required String doctor,
        required String date,
        required String time,
      }) async {
        final slotId = BookingService.generateSlotDocId(
          doctorName: doctor,
          date: date,
          time: time,
        );

        // Transaction read
        if (firestoreData.containsKey(slotId)) {
          final existing = firestoreData[slotId]!;
          final status = (existing['status'] ?? 'Booked').toString().toLowerCase();
          if (status != 'cancelled') {
            throw Exception("This time slot is already booked. Please select another slot.");
          }
        }

        // Transaction write
        firestoreData[slotId] = {
          'userId': patientId,
          'doctorName': doctor,
          'date': date,
          'time': time,
          'status': 'Booked',
        };
      }

      const doctor = 'Dr. Jenny Wilson';
      const date = '20/11/2026';
      const time = '10.00 AM';

      // 1. Patient 1 books the slot -> succeeds
      await simulateTransactionBooking(
        patientId: 'patient_1',
        doctor: doctor,
        date: date,
        time: time,
      );

      final slotId = BookingService.generateSlotDocId(
        doctorName: doctor,
        date: date,
        time: time,
      );
      expect(firestoreData[slotId]!['userId'], equals('patient_1'));
      expect(firestoreData[slotId]!['status'], equals('Booked'));

      // 2. Patient 2 tries to book the same slot -> must throw double booking exception
      expect(
        () async => await simulateTransactionBooking(
          patientId: 'patient_2',
          doctor: doctor,
          date: date,
          time: time,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('This time slot is already booked. Please select another slot.'),
          ),
        ),
      );

      // Verify Patient 1's booking remained intact and was not overwritten
      expect(firestoreData[slotId]!['userId'], equals('patient_1'));

      // 3. If Patient 1 cancels the appointment
      firestoreData[slotId]!['status'] = 'Cancelled';

      // 4. Now Patient 2 can book the slot -> succeeds
      await simulateTransactionBooking(
        patientId: 'patient_2',
        doctor: doctor,
        date: date,
        time: time,
      );
      expect(firestoreData[slotId]!['userId'], equals('patient_2'));
      expect(firestoreData[slotId]!['status'], equals('Booked'));
    });
  });
}
