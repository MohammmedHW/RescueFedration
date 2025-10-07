import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/serviceModal.dart';


class ServiceService {
  final CollectionReference serviceCollection =
  FirebaseFirestore.instance.collection('services');

  Future<void> createService(AppService service) async {
    await serviceCollection.doc(service.id).set(service.toMap());
  }
  Future<void> updateService(AppService service) async {
    await serviceCollection.doc(service.id).update(service.toMap());
  }

  // Delete a service
  Future<void> deleteService(String serviceId) async {
    await serviceCollection.doc(serviceId).delete();
  }
  Stream<List<AppService>> getServices() {
    return serviceCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AppService.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

}
