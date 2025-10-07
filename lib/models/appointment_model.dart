import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DoctorAppointment {
  final String id;
  final String doctorId;
  final String patientName;
  final String patientContact;
  final String date; // formatted date
  final String time; // formatted time
  final String status;
  final Timestamp createdAt;

  DoctorAppointment({
    required this.id,
    required this.doctorId,
    required this.patientName,
    required this.patientContact,
    required this.date,
    required this.time,
    required this.status,
    required this.createdAt,
  });

  factory DoctorAppointment.fromMap(Map<String, dynamic> map, String docId) {
    final ts = map['timestamp'] as Timestamp? ?? Timestamp.now();
    final dateTime = ts.toDate();
    final date = DateFormat('dd MMM yyyy').format(dateTime);
    final time = DateFormat('hh:mm a').format(dateTime);

    return DoctorAppointment(
      id: docId,
      doctorId: map['doctorId'] ?? '',
      patientName: map['userName'] ?? 'Unknown',
      patientContact: map['userContact'] ?? 'N/A', // optional, add to Firestore
      date: date,
      time: time,
      status: map['status'] ?? 'Pending',
      createdAt: ts,
    );
  }
}
