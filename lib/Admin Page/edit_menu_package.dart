import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for database
import '../colors.dart';

class EditPackageDialog extends StatefulWidget {
  final String docId;
  final String initialTitle;
  final String initialPrice;
  final String initialDescription;
  final String imagePath;

  const EditPackageDialog({
    super.key,
    required this.docId,
    required this.initialTitle,
    required this.initialPrice,
    required this.initialDescription,
    required this.imagePath,
  });

  @override
  State<EditPackageDialog> createState() => _EditPackageDialogState();
}

class _EditPackageDialogState extends State<EditPackageDialog> {
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _imageController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    // Logic: Keep original text for controller, logic functions handle parsing later
    _priceController = TextEditingController(text: widget.initialPrice.replaceAll('RM', '').trim());
    _descController = TextEditingController(text: widget.initialDescription);
    _imageController = TextEditingController(text: widget.imagePath);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  // --- LOGIC FUNCTIONS ---

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

  Future<void> _updateMenuPackage() async {
    await FirebaseFirestore.instance.collection('menu').doc(widget.docId).update({
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'image': _imageController.text.trim(),
    });
  }

  Future<void> _deleteMenuPackage() async {
    await FirebaseFirestore.instance.collection('menu').doc(widget.docId).delete();
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    bool isNetworkImage = _imageController.text.startsWith('http');

    return Dialog(
      backgroundColor: white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image header section
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      color: white,
                      child: isNetworkImage
                          ? Image.network(_imageController.text, fit: BoxFit.cover, errorBuilder: (c,o,s) => const Icon(Icons.broken_image))
                          : Image.asset(_imageController.text, fit: BoxFit.cover, errorBuilder: (c,o,s) => const Icon(Icons.broken_image)),
                    ),
                  ),

                  Positioned(
                    bottom: 15, right: 15,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: white,
                        surfaceTintColor: Colors.transparent,
                        foregroundColor: black,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: _showImageEditDialog,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text("Edit Image URL", style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 12.0)),
                    ),
                  ),
                ],
              ),

              // Text fields
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

              // Buttons section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // DELETE MENU button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: black,
                        foregroundColor: white,
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      ),
                      onPressed: () {
                        // Pass 'true' to indicate we want to delete
                        _showSaveConfirmation(context, isDeleting: true);
                      },
                      child: const Text(
                        'Delete menu',
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // CANCEL button
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: black,
                              fontFamily: 'Rubik',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // SAVE Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: black,
                            foregroundColor: white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                          ),
                          onPressed: () {
                            // Pass 'false' to indicate we want to save (update)
                            _showSaveConfirmation(context, isDeleting: false);
                          },
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontFamily: 'Rubik',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  // Image edit dialog
  void _showImageEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        title: const Text("Edit Image Path", style: TextStyle(color: darkGrey, fontFamily: 'Rubik', fontWeight: FontWeight.bold)),
        content: TextField(
            controller: _imageController,
            decoration: const InputDecoration(hintText: "Enter URL or assets/...")
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("Done", style: TextStyle(color: black)),
          ),
        ],
      ),
    );
  }

  // Confirmation dialog
  void _showSaveConfirmation(BuildContext context, {required bool isDeleting}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: const Center(
          child: Text(
            'Confirm changes?',
            style: TextStyle(
              color: black,
              fontFamily: 'Rubik',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // No button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'No',
                    style: TextStyle(
                      color: black,
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Yes button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: black,
                    foregroundColor: white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    // Pass the decision to the password dialog
                    _showPasswordDialog(context, isDeleting: isDeleting);
                  },
                  child: const Text(
                    'Yes',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Password dialog
  void _showPasswordDialog(BuildContext context, {required bool isDeleting}) {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),

        title: const Center(
          child: Text(
            'Enter admin password:',
            style: TextStyle(
              color: black,
              fontFamily: 'Rubik',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(5.0),
                border: Border.all(color: black, width: 1.0),
              ),

              // Password text field
              child: TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: darkGrey, fontFamily: 'Rubik'),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: darkGrey),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: black,
                  foregroundColor: white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                onPressed: () async {
                  // Verify password
                  bool success = await _verifyPassword(passwordController.text);

                  if (success) {
                    // Perform action (delete or update)
                    if (isDeleting) {
                      await _deleteMenuPackage();
                    } else {
                      await _updateMenuPackage();
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      // Show success message
                      _showSuccessDialog(context, isDeleting ? 'Menu deleted.' : 'Changes saved.');
                    }
                  } else {
                    // Wrong password error
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(backgroundColor: Colors.red, content: Text("Wrong Password"))
                      );
                    }
                  }
                },
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Success dialog
  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),

            // Tick icon
            const Icon(
              Icons.check,
              size: 60,
              color: black,
            ),

            const SizedBox(height: 15),

            Text(
              message,
              style: const TextStyle(
                color: black,
                fontFamily: 'Rubik',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 25),

            // Back to home button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: black,
                foregroundColor: white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                elevation: 4,
              ),
              onPressed: () {
                // Close success dialog
                Navigator.pop(context);
                // Close edit dialog and go back to list
                Navigator.pop(context);
              },
              child: const Text(
                'Back to home',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Label fields
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Text(
        text,
        style: const TextStyle(
          color: darkGrey,
          fontFamily: 'Rubik',
          fontWeight: FontWeight.bold,
          fontSize: 14.0,
        ),
      ),
    );
  }

  // Text fields
  // Text fields
  Widget _buildTextField(TextEditingController controller, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: black,
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: black, fontFamily: 'Rubik'),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          suffixIcon: IconButton(
            icon: const Icon(Icons.cancel_outlined, color: black),
            onPressed: () => controller.clear(),
          ),
        ),
      ),
    );
  }
}