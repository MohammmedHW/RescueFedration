import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../ auth/login_page.dart';
import '../../models/doctor_service.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<Map<String, dynamic>> bookedAppointments = [];
  final DoctorService _doctorService = DoctorService();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    _fetchUserAppointments();
  }
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }
  Future<void> _fetchUserAppointments() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      bookedAppointments.clear();
      bookedAppointments.addAll(snapshot.docs.map((doc) => doc.data()));
    });
  }

  Future<void> _bookAppointment(Map<String, dynamic> doctor) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 🔹 Fetch user data from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data();
    final userName = userData?['name'] ?? 'User';
    final userPhone = userData?['phone'] ?? 'N/A';

    await _firestore.collection('appointments').add({
      'doctorId': doctor['id'],
      'doctorName': doctor['name'],
      'specialization': doctor['specialization'],
      'userId': user.uid,
      'userName': userName,
      'userContact': userPhone,        // 🔹 Save phone number
      'status': 'Pending',
      'isEmergency': false,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      bookedAppointments.insert(0, {
        'doctorName': doctor['name'],
        'status': 'Pending',
        'specialization': doctor['specialization'],
        'isEmergency': false,
        'userName': userName,
        'userContact': userPhone,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appointment booked with ${doctor['name']}!'),
        backgroundColor: Colors.teal.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        automaticallyImplyLeading: false,
        elevation: 4,
        title: const Text(
          "User Dashboard",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [
                  // Available Doctors Section
                  Row(

                    children: [
                      Icon(Icons.local_hospital,
                          color: Colors.teal.shade700, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "Available Doctors",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Doctors List
                  SizedBox(
                    height: 300, // adjust as needed

                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('doctors').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                              child: CircularProgressIndicator(
                                  color: Colors.teal.shade600));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text("No doctors available currently."));
                        }

                        final doctors = snapshot.data!.docs;


                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 8),
                          itemCount: doctors.length,
                          itemBuilder: (context, index) {
                            final data =
                            doctors[index].data() as Map<String, dynamic>;


                            return Card(
                              elevation: 6,
                              color: Colors.white,
                              shadowColor: Colors.teal.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name & Specialization
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['name'] ?? "Doctor",
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                data['specialization'] ??
                                                    "Specialist",
                                                style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if ((data['clinicAddress'] ?? "").isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              data['clinicAddress'] ?? "",
                                              style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Timing: ${data['clinicTime'] ?? 'N/A'}",
                                          style:
                                          const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "₹${data['consultationFee'] ?? 0}",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal.shade800,
                                              fontSize: 18),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => _bookAppointment({
                                            'id': doctors[index].id,
                                            'name': data['name'],
                                            'specialization':
                                            data['specialization'],
                                          }),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal.shade700,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(16)),
                                            elevation: 2,
                                          ),
                                          child: const Text("Book Now",
                                              style: TextStyle(fontSize: 14)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Booked Appointments Section
                  Row(
                    children: [
                      Icon(Icons.history, color: Colors.teal.shade700, size: 24),
                      const SizedBox(width: 8),
                      Text("Your Appointments",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 300, // adjust as needed
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('appointments')
                          .where('userId', isEqualTo: _auth.currentUser?.uid ?? '')

                          .snapshots(),
                      builder: (context, snapshot) {

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.teal));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text("No appointments yet"));
                        }

                        final appointments = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            final data = appointments[index].data() as Map<String, dynamic>;
                            if (data == null) return SizedBox();
                            final isEmergency = data['isEmergency'] ?? false;
                            final doctorName = data['doctorName'] ?? "Doctor";
                            final specialization = data['specialization'] ?? "Specialist";
                            final status = data['status'] ?? "Pending";

                            final timestamp = data['timestamp'] as Timestamp?;
                            final bookingTime = timestamp != null
                                ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
                                : "N/A";

                            return Card(
                              elevation: 4,
                              shadowColor: Colors.teal.withOpacity(0.3),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Doctor name and specialization
                                    Text(
                                      doctorName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      specialization,
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),

                                    Text("Booked on: $bookingTime",
                                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 12),

                                    // Status and buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Chip(
                                          label: Text(
                                            status.toUpperCase(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          backgroundColor: isEmergency ? Colors.red : Colors.teal.shade700,
                                        ),
                                        Row(
                                          children: [
                                            TextButton.icon(
                                              onPressed: () async {
                                                try {
                                                  final appointmentId = appointments[index].id; // Firestore doc id

                                                  // Delete the appointment from Firestore
                                                  await FirebaseFirestore.instance
                                                      .collection('appointments')
                                                      .doc(appointmentId)
                                                      .delete();

                                                  // Remove locally from list to refresh UI immediately
                                                  setState(() {
                                                    bookedAppointments.removeWhere((a) =>
                                                    a['id'] == appointmentId || a['doctorName'] == doctorName);
                                                  });

                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Appointment with $doctorName deleted!'),
                                                      backgroundColor: Colors.red.shade400,
                                                    ),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Failed to delete appointment: $e'),
                                                      backgroundColor: Colors.red.shade700,
                                                    ),
                                                  );
                                                }
                                              },
                                              icon: const Icon(Icons.cancel, color: Colors.red),
                                              label: const Text(
                                                "Cancel",
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),


                                            const SizedBox(width: 8),

                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );

                          },
                        );

                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
