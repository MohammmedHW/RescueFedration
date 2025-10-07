import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/userModal.dart';

class UserService {
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('users');

  Future<void> createUser(AppUser user) async {
    await usersCollection.doc(user.uid).set(user.toMap());
  }
}
