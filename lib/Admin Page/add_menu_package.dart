import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../colors.dart';

class AddPackageDialog extends StatefulWidget {
  const AddPackageDialog({super.key});

  @override
  State<AddPackageDialog> createState() => _AddPackageDialogState();
}

class _AddPackageDialogState extends State<AddPackageDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<bool> _verifyPassword(String password) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _addMenuToFirestore() async {
    await FirebaseFirestore.instance.collection('menu').add({
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'price': double.tryParse(_priceController.text.replaceAll('RM', '').trim()) ?? 0.0,
      'image': _imageController.text.trim().isEmpty ? 'assets/package_a.jpg' : _imageController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder area
              Stack(
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                    ),
                    child: _imageController.text.isNotEmpty
                        ? (_imageController.text.startsWith('http')
                        ? Image.network(_imageController.text, fit: BoxFit.cover, errorBuilder: (c,o,s) => const Icon(Icons.broken_image))
                        : Image.asset(_imageController.text, fit: BoxFit.cover, errorBuilder: (c,o,s) => const Icon(Icons.image)))
                        : const Center(child: Icon(Icons.image, size: 50, color: Colors.white54)),
                  ),

                  Positioned(
                    bottom: 15,
                    right: 15,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: white,
                        surfaceTintColor: Colors.transparent,
                        foregroundColor: black,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: _showImageInputDialog,
                      icon: const Icon(Icons.add_photo_alternate, size: 18),
                      label: const Text("Set Image URL", style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),

              // Form fields
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Package Name:"),
                    _buildTextField(_titleController),
                    const SizedBox(height: 15),
                    _buildLabel("Description:"),
                    _buildTextField(_descController, maxLines: 5),
                    const SizedBox(height: 15),
                    _buildLabel("Price (RM):"),
                    _buildTextField(_priceController),
                  ],
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: black, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: black,
                        foregroundColor: white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                      ),
                      onPressed: () => _showSaveConfirmation(context),
                      child: const Text('Save', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // Image input dialog
  void _showImageInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Image Path"),
        content: TextField(
          controller: _imageController,
          decoration: const InputDecoration(
            hintText: "e.g., assets/package_a.jpg OR https://...",
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => setState((){}),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Done")),
        ],
      ),
    );
  }

  // Confirmation dialog
  void _showSaveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        title: const Center(child: Text('Confirm add package?', style: TextStyle(color: Colors.black, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 18))),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: black, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: black, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            onPressed: () {
              Navigator.pop(context);
              _showPasswordDialog(context);
            },
            child: const Text('Yes', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Password dialog
  void _showPasswordDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              title: const Center(child: Text('Enter admin password:', style: TextStyle(color: black, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 18))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading) const CircularProgressIndicator(color: black)
                  else Container(
                    decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(5.0), border: Border.all(color: black, width: 1.0)),
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: black, fontFamily: 'Rubik',),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: black),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.cancel_outlined, color: black),
                          onPressed: () => passwordController.clear(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: black, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
                      onPressed: isLoading ? null : () async {
                        setState(() => isLoading = true);
                        bool success = await _verifyPassword(passwordController.text);
                        if (success) {
                          await _addMenuToFirestore();
                          if (context.mounted) {
                            Navigator.pop(context);
                            _showSuccessDialog(context);
                          }
                        } else {
                          setState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: errorRed, content: Text("Wrong Password!")));
                          }
                        }
                      },
                      child: const Text('Save', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          }
      ),
    );
  }

  // Success dialog
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Icon(Icons.check, size: 60, color: black),
            const SizedBox(height: 15),
            const Text('Package added.', style: TextStyle(color: black, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: black, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12), elevation: 4),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Back to home', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 5.0), child: Text(text, style: const TextStyle(color: black, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 14.0)));
  }

  Widget _buildTextField(TextEditingController controller, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(10), border: Border.all(color: black, width: 1.0)),
      child: TextField(
        controller: controller, maxLines: maxLines,
        style: const TextStyle(color: black, fontFamily: 'Rubik'),
        decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            suffixIcon: IconButton(
                icon: const Icon(Icons.cancel_outlined, color: black),
                onPressed: () => controller.clear()
            )
        ),
      ),
    );
  }
}