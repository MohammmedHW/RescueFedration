import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/userModal.dart';
import '../../services/service.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with TickerProviderStateMixin {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String role = "User";
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _containerColorAnimation;
  late Animation<double> _iconScaleAnimation;
  bool _obscurePassword = true;
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }
  // In _SignupPageState
  // In _SignupPageState

  void _signup() async {
    // Input validation
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      showTopBanner(context, this, "Please fill all fields", bgColor: Colors.red);
      return;
    }
    setState(() {
      _isLoading = true; // Start loading
    });
    try {
      // 1. FIREBASE AUTHENTICATION
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Create user object
      final user = AppUser(
        uid: credential.user!.uid,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        role: role,
      );

      // 2. FIRESTORE WRITE
      try {
        await UserService().createUser(user);

        // Success
        showTopBanner(context, this, "Account created successfully", bgColor: Colors.green);

        // Navigate after a short delay to let user see the Snackbar
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        });

      } on FirebaseException catch (e) {
        print("FIRESTORE ERROR CODE: ${e.code}");
        showTopBanner(context, this, "Failed to save profile. Check security rules.", bgColor: Colors.red);


        // Delete Auth user to allow retry
        await credential.user?.delete();

      } catch (e) {
        print("General Firestore/User creation error: $e");
        showTopBanner(context, this, "Profile creation failed unexpectedly.", bgColor: Colors.red);

      }

    } on FirebaseAuthException catch (e) {
      print("AUTH ERROR CODE: ${e.code}");
      showTopBanner(context, this, "Something went wrong during signup.", bgColor: Colors.red);
    } catch (e) {
      print("GENERAL CATCH-ALL ERROR: $e");

      showTopBanner(context, this, "Something went wrong during signup.", bgColor: Colors.red);
    }finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading on completion/error
        });
      }
      }
  }



  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    _containerColorAnimation = ColorTween(
      begin: Colors.teal.shade50,
      end: Colors.white,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }


  @override
  void dispose() {
    _controller.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade900,
      body: SafeArea(
        child: Center(

          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 50, 24, 50), // top & bottom padding
            child: ScaleTransition(

              scale: _scaleAnimation,
              child: Container(

                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white, // fixed color
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
                    ScaleTransition(
                      scale: _iconScaleAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.teal.shade600, Colors.teal.shade800],
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
                          Icons.person_add_alt_1,
                          size: 60,
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
                            "Create Account",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Join our medical community",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Full Name
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: Icon(Icons.person, color: Colors.teal.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Phone Number
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: Icon(Icons.phone, color: Colors.teal.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Email
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email, color: Colors.teal.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Password
                    TextField(
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
                    const SizedBox(height: 15),

                    // Role Dropdown
                    DropdownButtonFormField<String>(
                      value: role,
                      items: ["User", "Admin"].map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(r, style: TextStyle(color: Colors.teal.shade800)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => role = val!),
                      decoration: InputDecoration(
                        labelText: "Role",
                        prefixIcon: Icon(Icons.medical_services, color: Colors.teal.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Signup Button
                    ElevatedButton(
                      // The button is disabled when _isLoading is true
                      onPressed: _isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      // *** Conditional Child Content ***
                      child: _isLoading
                          ? const SizedBox(
                        height: 24, // Control the size of the loader
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white, // Loader color matches foreground color
                          strokeWidth: 3,
                        ),
                      )
                          : const Text(
                        "Create Account",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),


                    const SizedBox(height: 10),

                    // Login link
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const LoginPage(),
                          transitionsBuilder: (_, animation, __, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(-1.0, 0.0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                              ),
                              child: child,
                            );
                          },
                        ),
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(color: Colors.teal.shade700),
                          children: [
                            TextSpan(
                              text: "Login",
                              style: TextStyle(
                                color: Colors.teal.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
      ),
    );
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
// The function now requires a TickerProvider as an argument.
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