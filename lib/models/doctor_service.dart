import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_profile_model.dart';
import '../models/appointment_model.dart';

class DoctorService {
  final _doctorCollection = FirebaseFirestore.instance.collection('doctors');
  final _appointmentCollection = FirebaseFirestore.instance.collection('appointments');

  // Doctor profile
  Future<void> saveDoctorProfile(DoctorProfile profile) async {
    await _doctorCollection.doc(profile.id).set(profile.toMap());
  }

  Stream<DoctorProfile?> getDoctorProfile(String doctorId) {
    return _doctorCollection.doc(doctorId).snapshots().map((doc) {
      if (doc.exists) return DoctorProfile.fromMap(doc.data()!);
      return null;
    });
  }

  // Appointments - simple, no indexing needed
  Stream<List<DoctorAppointment>> getAppointments(String doctorId) {
    return _appointmentCollection
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((d) => DoctorAppointment.fromMap(d.data(), d.id))
        .toList());
  }

  Future<void> updateAppointmentStatus(String id, String status) async {
    await _appointmentCollection.doc(id).update({'status': status});
  }
}
