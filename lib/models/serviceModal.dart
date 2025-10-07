import 'package:cloud_firestore/cloud_firestore.dart';

class AppService {
  final String id;
  final String name;
  final String description;
  final double price; // optional
  final Timestamp createdAt;
  final String createdBy;

  AppService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }

  factory AppService.fromMap(Map<String, dynamic> map) {
    return AppService(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price']?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      createdBy: map['createdBy'] ?? 'unknown',
    );
  }
}
