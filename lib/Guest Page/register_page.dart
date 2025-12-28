import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // For storing User Names/Phone
import '../colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  // Text controllers to capture what the user types
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Sign up method
  Future<void> signUserUp() async {
    // Show loading circle
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: darkGrey)),
    );

    // Validation: Check if passwords match
    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      Navigator.pop(context);
      _showErrorMessage("Passwords do not match!");
      return;
    }

    try {
      // Create user in firebase (email and password)
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save user details to firebase
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'user',
        'createdAt': DateTime.now(),
      });

      if (context.mounted) Navigator.pop(context);

      // Success notification. Go back to login page
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully! Please Login.")),
        );
        Navigator.pop(context);
      }

    } on FirebaseAuthException catch (e) {

      if (context.mounted) Navigator.pop(context);
      // Show error (e.g., "Email already in use")
      _showErrorMessage(e.message ?? "An error occurred");
    }
  }

  // Helper to show error messages
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
    // Clean up controllers to free memory
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: black,
        surfaceTintColor: Colors.transparent,
        elevation: 4.0,
        shadowColor: black,
        leading: const BackButton(color: white),
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
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              margin: const EdgeInsets.symmetric(vertical: 25),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: black,
                  width: 2.0,
                )
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: black,
                      fontFamily: 'Rubik',
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // FIELDS (Now connected to Controllers)
                  _buildRegisterField('Full Name', 'your name here', controller: _fullNameController),
                  const SizedBox(height: 10),
                  _buildRegisterField('Phone Number', '+xxx xxxxxxx', controller: _phoneController),
                  const SizedBox(height: 10),
                  _buildRegisterField('Email', 'example@gmail.com', controller: _emailController),
                  const SizedBox(height: 10),
                  _buildRegisterField('Password', 'password', isPassword: true, controller: _passwordController),
                  const SizedBox(height: 10),
                  _buildRegisterField('Confirm Password', 'confirm password', isPassword: true, controller: _confirmPasswordController),

                  SizedBox(height: screenHeight * 0.04),

                  // Sign up button
                  SizedBox(
                    width: 160,
                    child: ElevatedButton(
                      onPressed: signUserUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: black,
                        foregroundColor: white,
                        elevation: 5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'SIGN UP',
                        style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Rubik', fontSize: 16.0),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Footer link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(fontSize: 13, color: darkGrey),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Login here',
                          style: TextStyle(fontSize: 13, color: black, fontWeight: FontWeight.bold),
                        ),
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
  }

  // Helper updated to accept controller
  Widget _buildRegisterField(String label, String hint, {bool isPassword = false, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: darkGrey, fontFamily: 'Rubik'),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: darkGrey),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: darkGrey)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: darkGrey)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: darkGrey, width: 2)),
          ),
        ),
      ],
    );
  }
}