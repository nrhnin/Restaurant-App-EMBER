import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mini_project/User%20Page/user_dashboard_page.dart';
import '../colors.dart';
import 'guest_page.dart';
import 'register_page.dart';
import '../Admin Page/admin_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers to capture input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;

  // Login logic
  Future<void> loginUser() async {
    // Show loading circle
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: darkGrey)),
    );

    try {
      // Authenticate with email and password
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Fetch user data from firebase to check user role
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (context.mounted) Navigator.pop(context);

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String role = userData['role'];

        // Route based on role
        if (context.mounted) {
          if (role == 'admin') {
            // If role is admin, navigate to admin dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboard()),
            );
          } else {
            // If role is user, navigate to user dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserDashboardPage()),
            );
          }
        }
      } else {
        _showErrorMessage("User record not found in database.");
      }

    } on FirebaseAuthException catch (e) {
      if (context.mounted) Navigator.pop(context);
      // Show error (Wrong password, user not found, etc.)
      _showErrorMessage(e.message ?? "Authentication failed");
    }
  }

  // Helper to show errors
  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: white,
        title: const Text("Error", style: TextStyle(color: black, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: darkGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: black)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: black,
        surfaceTintColor: Colors.transparent,
        elevation: 4.0,
        shadowColor: black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const GuestPage()),
            );
          },
        ),
        title: const Text(
          'EMBER',
          style: TextStyle(
            color: white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Rubik',
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Login card
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: black,
                        width: 2.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: black,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Email Input
                        _buildInputField('Email', controller: _emailController),
                        const SizedBox(height: 20),

                        // Password Input
                        _buildInputField('Password', isPassword: true, controller: _passwordController),
                        const SizedBox(height: 15),

                        // Remember me section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: black,
                                    checkColor: white,
                                    side: const BorderSide(color: darkGrey, width: 2),
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value!;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Remember me',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: black,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: black,
                                      fontWeight: FontWeight.bold
                                  )
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // LOGIN Button
                        SizedBox(
                          width: 150,
                          child: ElevatedButton(
                            onPressed: loginUser, // Connect to login function
                            style: ElevatedButton.styleFrom(
                              backgroundColor: black,
                              foregroundColor: white,
                              elevation: 5,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                                'LOGIN',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Rubik'
                                )
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        _buildFooterLink("Don't have an account?", "Create account"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to accept controller
  Widget _buildInputField(String label, {bool isPassword = false, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: darkGrey,
              fontFamily: 'Rubik'
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: black),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: darkGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: darkGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: darkGrey, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // Helper for footer link
  Widget _buildFooterLink(String normalText, String linkText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
            normalText,
            style: const TextStyle(fontSize: 12, color: darkGrey)
        ),
        const SizedBox(width: 5),
        GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage())
            );
          },
          child: Text(
            linkText,
            style: const TextStyle(
                fontSize: 12,
                color: black,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
      ],
    );
  }
}