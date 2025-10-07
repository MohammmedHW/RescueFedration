import 'package:flutter/material.dart';
import 'package:rescuefedration/views/%20auth/signup_page.dart';
import '../admin/admin_home_page.dart';
import '../user/user_home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _containerColorAnimation;
  bool _obscurePassword = true;
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6)),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _containerColorAnimation = ColorTween(
      begin: Colors.teal.shade50,
      end: Colors.white,
    ).animate(_controller);

    _controller.forward();
  }

  void _login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      showTopBanner(context, this, "Please enter email and password", bgColor: Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
      _controller.animateTo(0.8, duration: const Duration(milliseconds: 200));
    });

    try {
      // 1. Authenticate User
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final userUid = userCredential.user!.uid;

      // 2. Fetch User Role from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .get();

      if (!userDoc.exists) {
        throw Exception("User profile not found. Please contact support.");
      }


      final role = userDoc.data()?['role'] as String?;

      if (role == null) {
        throw Exception("User role not defined. Access denied.");
      }

      // 3. Navigate Based on Role
      await Future.delayed(const Duration(milliseconds: 300)); // Animation delay
      if (!mounted) return;

      if (role == "Admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DoctorDashboard()),
        );
      } else { // Assumes "User" is the default and only other valid role
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserHomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = "Login Failed";
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = "Invalid credentials.";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email format.";
      } else {
        message = e.message ?? "Login failed.";
      }

      showTopBanner(context, this, "Something Went Wrong", bgColor: Colors.red);
    } catch (e) {
      if (!mounted) return;
      print("Login Error: $e");

      showTopBanner(context, this, "profile not found", bgColor: Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
        _controller.animateTo(1.0, duration: const Duration(milliseconds: 300));
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade800,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.8,
                  colors: [
                    Colors.teal.shade800.withOpacity(0.8),
                    Colors.teal.shade800,
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: _containerColorAnimation.value,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.teal.shade600,
                                    Colors.teal.shade800,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.teal.shade600.withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: const Icon(
                                Icons.medical_services,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Title
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                Text(
                                  "Welcome Back",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Sign in to continue",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Email
                          _buildAnimatedFormField(
                            child: TextField(
                              controller: emailController,
                              decoration: InputDecoration(
                                labelText: "Email",
                                prefixIcon: Icon(Icons.email,
                                    color: Colors.teal.shade600),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Password
                          _buildAnimatedFormField(
                            child: TextField(
                              controller: passwordController,
                              obscureText: _obscurePassword,

                              decoration: InputDecoration(
                                labelText: "Password",
                                prefixIcon: Icon(Icons.lock, color: Colors.teal.shade600),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                // Eye button to toggle visibility
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.teal.shade600,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),


                          // Login button
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login, // Disable while loading
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade600,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 8,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                                  : const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Signup
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignupPage()),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  text: "Don't have an account? ",
                                  style: TextStyle(
                                    color: Colors.teal.shade700,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Sign up",
                                      style: TextStyle(
                                        color: Colors.teal.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                                child: Text("OR",
                                    style:
                                    TextStyle(color: Colors.grey.shade600)),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Social buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _socialButton(
                                img:
                                "https://upload.wikimedia.org/wikipedia/commons/0/09/IOS_Google_icon.png",
                                onTap: () {},
                              ),
                              const SizedBox(width: 20),
                              _socialButton(
                                icon: Icons.apple,
                                color: Colors.black,
                                onTap: () {},
                              ),
                              const SizedBox(width: 20),
                              _socialButton(
                                img:
                                "https://upload.wikimedia.org/wikipedia/commons/0/05/Facebook_Logo_%282019%29.png",
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedFormField({required Widget child}) {
    return FadeTransition(opacity: _fadeAnimation, child: child);
  }

  Widget _socialButton({String? img, IconData? icon, Color? color, Function()? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: img != null
            ? Image.network(img, height: 22, width: 22)
            : Icon(icon, size: 22, color: color),
      ),
    );
  }
}
void showTopBanner(BuildContext context, TickerProvider vsync, String message, {Color bgColor = Colors.green}) {

  // Create the AnimationController correctly using the passed vsync
  final animationController = AnimationController(
    vsync: vsync,
    duration: const Duration(milliseconds: 300),
  );

  final animation = Tween<Offset>(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: animationController,
      curve: Curves.fastOutSlowIn,
    ),
  );

  animationController.forward(); // Start the animation

  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      right: 10,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: animation, // Use the prepared animation
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ),
  );

  // Insert and remove logic remains the same
  Overlay.of(context).insert(overlayEntry);

  Future.delayed(const Duration(seconds: 3), () {
    if (overlayEntry.mounted) {
      // Add a reverse animation before removal for a smooth exit
      animationController.reverse().then((_) {
        overlayEntry.remove();
        animationController.dispose(); // Dispose the controller when done
      });
    } else {
      animationController.dispose();
    }
  });
}