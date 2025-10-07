import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorProfile {
  final String id;
  final String name;
  final String specialization;
  final double consultationFee;
  final String clinicAddress;
  final String clinicTime; // e.g. "10:00 AM - 5:00 PM"
  final String createdBy; // doctor uid
  final Timestamp createdAt;

  DoctorProfile({
    required this.id,
    required this.name,
    required this.specialization,
    required this.consultationFee,
    required this.clinicAddress,
    required this.clinicTime,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialization': specialization,
      'consultationFee': consultationFee,
      'clinicAddress': clinicAddress,
      'clinicTime': clinicTime,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  factory DoctorProfile.fromMap(Map<String, dynamic> map) {
    return DoctorProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      specialization: map['specialization'] ?? '',
      consultationFee: (map['consultationFee'] ?? 0).toDouble(),
      clinicAddress: map['clinicAddress'] ?? '',
      clinicTime: map['clinicTime'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}
