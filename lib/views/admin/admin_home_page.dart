import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ auth/login_page.dart';
import '../../models/doctor_profile_model.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_service.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> with TickerProviderStateMixin {
  final DoctorService _doctorService = DoctorService();

  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _feeController = TextEditingController();
  final _addressController = TextEditingController();
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;

  User? get _user => FirebaseAuth.instance.currentUser;



  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }
  void _loadDoctorProfile() async {
    if (_user == null) return;

    _doctorService.getDoctorProfile(_user!.uid).listen((profile) {
      if (profile != null) {
        // Prefill the text fields
        _nameController.text = profile.name;
        _specializationController.text = profile.specialization;
        _feeController.text = profile.consultationFee.toString();
        _addressController.text = profile.clinicAddress;

        // Parse clinic time if exists
        if (profile.clinicTime.isNotEmpty && profile.clinicTime.contains('-')) {
          final parts = profile.clinicTime.split('-');
          final open = parts[0].trim();
          final close = parts[1].trim();
          final openTime = _parseTimeOfDay(open);
          final closeTime = _parseTimeOfDay(close);
          setState(() {
            _openTime = openTime;
            _closeTime = closeTime;
          });
        }
      }
    });
  }
  TimeOfDay _parseTimeOfDay(String time) {
    final format = TimeOfDayFormat.H_colon_mm; // just a placeholder
    final parts = time.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1].split(' ')[0]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return TimeOfDay(hour: 0, minute: 0);
  }
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  void _saveProfile() async {
    if (_user == null) return;

    final profile = DoctorProfile(
      id: _user!.uid,
      name: _nameController.text.trim(),
      specialization: _specializationController.text.trim(),
      consultationFee: double.tryParse(_feeController.text.trim()) ?? 0.0,
      clinicAddress: _addressController.text.trim(),
      clinicTime: _openTime != null && _closeTime != null
          ? "${_openTime!.format(context)} - ${_closeTime!.format(context)}"
          : "",
      createdBy: _user!.uid,
      createdAt: Timestamp.now(),
    );

    await _doctorService.saveDoctorProfile(profile);
    showTopBanner(context, this, "Profile saved successfully", bgColor: Colors.green);
  }

  void _updateStatus(String id, String status) {
    _doctorService.updateAppointmentStatus(id, status);
    showTopBanner(context, this, "Appointment $status", bgColor: Colors.teal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        elevation: 4,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Clinic Details",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.teal.shade900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_nameController, "Doctor Name", Icons.person),
                      const SizedBox(height: 12),
                      _buildTextField(_specializationController, "Specialization", Icons.medical_information),
                      const SizedBox(height: 12),
                      _buildTextField(_feeController, "Consultation Fee", Icons.currency_rupee,
                          type: TextInputType.number),
                      const SizedBox(height: 12),
                      _buildTextField(_addressController, "Clinic Address", Icons.location_on),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _openTime = picked;
                                  });
                                }
                              },
                              child: AbsorbPointer(
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: _openTime != null
                                        ? " ${_openTime!.format(context)}"
                                        : "Select Opening Time",
                                    prefixIcon: const Icon(Icons.access_time, color: Colors.teal),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.teal.shade100),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _closeTime = picked;
                                  });
                                }
                              },
                              child: AbsorbPointer(
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: _closeTime != null
                                        ? " ${_closeTime!.format(context)}"
                                        : "Select Closing Time",
                                    prefixIcon: const Icon(Icons.access_time, color: Colors.teal),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.teal.shade100),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        label: const Text("Save Profile", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Appointments",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.teal.shade900,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.teal, size: 24),
                      tooltip: "Reload Appointments",
                      onPressed: () {
                        setState(() {
                          // This will trigger the StreamBuilder to rebuild
                          // Alternatively, call a refresh method in DoctorService if needed
                          _doctorService.getAppointments(_user?.uid ?? "");
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<DoctorAppointment>>(
                  stream: _doctorService.getAppointments(_user?.uid ?? ""),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text("Something went wrong!"));
                    }

                    final appointments = snapshot.data ?? [];
                    if (appointments.isEmpty) {
                      return const Center(
                        child: Text(
                          "No appointments yet",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: appointments.length,
                      itemBuilder: (context, i) {
                        final appt = appointments[i];
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.shade100,
                              child: const Icon(Icons.person, color: Colors.teal),
                            ),
                            title: Text(
                              appt.patientName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "${appt.date} • ${appt.time}\n${appt.patientContact}",
                                style: const TextStyle(fontSize: 13, height: 1.4),
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (status) => _updateStatus(appt.id, status),
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'accepted', child: Text("Accept")),
                                PopupMenuItem(value: 'completed', child: Text("Mark as Completed")),
                                PopupMenuItem(value: 'cancelled', child: Text("Cancel")),
                              ],
                              child: Chip(
                                label: Text(
                                  appt.status.toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: _statusColor(appt.status),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                )



              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController c, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: c,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal.shade600),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.teal.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.teal.shade400, width: 1.5),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green.shade100;
      case 'completed':
        return Colors.blue.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }
}
