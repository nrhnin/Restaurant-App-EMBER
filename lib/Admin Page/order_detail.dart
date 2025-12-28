import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../colors.dart';

class OrderDetailDialog extends StatefulWidget {
  final String docId;
  final String orderId;
  final String date;
  final bool isPendingMode;

  final String guestName;
  final String email;
  final String phone;
  final String packageName;
  final int pax;
  final double currentPrice;

  const OrderDetailDialog({
    super.key,
    required this.docId,
    required this.orderId,
    required this.date,
    this.isPendingMode = false,
    required this.guestName,
    required this.email,
    required this.phone,
    required this.packageName,
    required this.pax,
    required this.currentPrice,
  });

  @override
  State<OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<OrderDetailDialog> {

  bool _isEditing = false;
  String _pendingAction = '';

  // Dropdown options
  final List<Map<String, dynamic>> _packages = [
    {'name': 'Package A', 'price': 375},
    {'name': 'Package B', 'price': 400},
    {'name': 'Package C', 'price': 350},
  ];

  late Map<String, dynamic> _selectedPackage;
  late TextEditingController _paxController;
  int _pax = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with data from firebase
    _pax = widget.pax;
    _paxController = TextEditingController(text: _pax.toString());

    // Find the matching package object or default to first one
    _selectedPackage = _packages.firstWhere(
            (pkg) => pkg['name'] == widget.packageName,
        orElse: () => _packages[0]
    );
  }

  @override
  void dispose() {
    _paxController.dispose();
    super.dispose();
  }

  // Calculation helpers
  double get _subtotal => (_selectedPackage['price'] as int) * _pax.toDouble();
  double get _tax => _subtotal * 0.06;
  double get _total => _subtotal + _tax;

  // Update changes to database
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

  Future<void> _executePendingAction() async {
    final docRef = FirebaseFirestore.instance.collection('reservations').doc(widget.docId);

    if (_pendingAction == 'accept') {
      await docRef.update({'status': 'Approved'});
    } else if (_pendingAction == 'reject') {
      await docRef.update({'status': 'Rejected'});
    } else if (_pendingAction == 'cancel_order') {
      await docRef.update({'status': 'Cancelled'});
    } else if (_pendingAction == 'save_edit') {
      await docRef.update({
        'packageName': _selectedPackage['name'],
        'pax': _pax,
        'totalPrice': _total,
      });
    }
  }

  final TextStyle _labelStyle = const TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold, color: darkGrey, fontSize: 14.0);
  final TextStyle _contentStyle = const TextStyle(fontFamily: 'Rubik', color: darkGrey, fontSize: 14.0);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: Center(child: Text(widget.orderId, style: const TextStyle(color: black, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 20.0)))),
                    if (widget.isPendingMode) GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: darkGrey)),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: darkGrey, thickness: 0.5),
                const SizedBox(height: 10),

                // Customer details
                _buildDetailRow("Name:", widget.guestName),
                const SizedBox(height: 8),
                _buildDetailRow("Email:", widget.email),
                const SizedBox(height: 8),
                _buildDetailRow("Phone:", widget.phone),
                const SizedBox(height: 8),
                _buildDetailRow("Date of Order:", widget.date),

                const SizedBox(height: 15),
                const Divider(color: darkGrey, thickness: 0.5),
                const SizedBox(height: 15),

                _isEditing ? _buildEditForm() : _buildReadView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // View dialog
  Widget _buildReadView() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: Text("Menu Package", style: _labelStyle)),
            Expanded(flex: 1, child: Text("Pax.", textAlign: TextAlign.center, style: _labelStyle)),
            Expanded(flex: 2, child: Text("Price", textAlign: TextAlign.right, style: _labelStyle)),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(color: darkGrey, thickness: 0.5),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(flex: 3, child: Text(_selectedPackage['name'], style: _contentStyle)),
            Expanded(flex: 1, child: Text("$_pax", textAlign: TextAlign.center, style: _contentStyle)),

            // Show current price from database
            Expanded(flex: 2, child: Text("RM${_total.toStringAsFixed(0)}", textAlign: TextAlign.right, style: _contentStyle)),
          ],
        ),

        const SizedBox(height: 20),
        const Divider(color: darkGrey, thickness: 0.5),
        const SizedBox(height: 10),

        _buildTotalsSection(),

        const SizedBox(height: 25),

        if (widget.isPendingMode) _buildPendingButtons() else _buildBookedButtons(),
      ],
    );
  }

  // Edit dialog
  Widget _buildEditForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: Text("Menu Package", style: _labelStyle)),
            Expanded(flex: 1, child: Text("Pax.", textAlign: TextAlign.center, style: _labelStyle)),
            Expanded(flex: 2, child: Text("Price", textAlign: TextAlign.right, style: _labelStyle)),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dropdown
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(15), border: Border.all(color: black)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>>(
                    value: _selectedPackage,
                    isDense: true,
                    dropdownColor: white,
                    items: _packages.map((pkg) => DropdownMenuItem(value: pkg, child: Text(pkg['name'], style: _contentStyle.copyWith(fontSize: 12)))).toList(),
                    onChanged: (newValue) => setState(() => _selectedPackage = newValue!),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            // Pax input field
            Expanded(
              flex: 1,
              child: Container(
                height: 40,
                decoration: BoxDecoration(color: white, border: Border.all(color: black), borderRadius: BorderRadius.circular(5)),
                child: TextField(
                  controller: _paxController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: _contentStyle,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.only(bottom: 12)),
                  onChanged: (value) => setState(() => _pax = int.tryParse(value) ?? 0),
                ),
              ),
            ),
            Expanded(flex: 2, child: Text("RM${_subtotal.toStringAsFixed(0)}", textAlign: TextAlign.right, style: _contentStyle)),
          ],
        ),

        const SizedBox(height: 20),
        const Divider(color: darkGrey, thickness: 0.5),
        const SizedBox(height: 10),

        _buildTotalsSection(),

        const SizedBox(height: 25),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: black, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), elevation: 2),
              onPressed: () => _showConfirmationDialog(context, 'cancel_order'),
              child: const Text('Cancel order', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold)),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('Cancel', style: TextStyle(color: black, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 5),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: black, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), elevation: 2),
                  onPressed: () => _showConfirmationDialog(context, 'save_edit'),
                  child: const Text('Save', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- BUTTONS ---
  Widget _buildBookedButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: black, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 16))),
        const SizedBox(width: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: black, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10), elevation: 2.0),
          onPressed: () => setState(() => _isEditing = true),
          child: const Text('Edit', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildPendingButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: () => _showConfirmationDialog(context, 'reject'), child: const Text('Reject', style: TextStyle(color: black, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 16))),
        const SizedBox(width: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: black, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10), elevation: 2.0,),
          onPressed: () => _showConfirmationDialog(context, 'accept'),
          child: const Text('Accept', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTotalsSection() {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Tax (6%)", style: _contentStyle), Text("RM${_tax.toStringAsFixed(2)}", style: _contentStyle)]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total Price", style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 16, color: black)),
          Text("RM${_total.toStringAsFixed(2)}", style: const TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 18, color: black))]),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: _labelStyle), Text(value, style: _contentStyle)]);
  }

  // --- DIALOGS (Confirm/Password/Success) ---
  void _showConfirmationDialog(BuildContext context, String action) {
    _pendingAction = action;
    String titleText = 'Confirm changes?';
    if (action == 'accept') titleText = 'Accept Order?';
    if (action == 'reject') titleText = 'Reject Order?';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        title: Center(child: Text(titleText, style: const TextStyle(color: darkGrey, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 18))),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No', style: TextStyle(color: black, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 16))),
          const SizedBox(width: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: black, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10), elevation: 2.0),
            onPressed: () { Navigator.pop(context); _showPasswordDialog(context); },
            child: const Text('Yes', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
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
              if (isLoading)
                const CircularProgressIndicator(color: black)
              else
              // --- UPDATED PASSWORD FIELD CONTAINER ---
                Container(
                  decoration: BoxDecoration(
                    color: white, // 1. White Background
                    borderRadius: BorderRadius.circular(10.0), // Rounded corners
                    border: Border.all(color: black, width: 1.5), // 2. Black Border
                  ),
                  child: TextField(
                    controller: passwordController,
                    obscureText: true,
                    // 3. Black Text
                    style: const TextStyle(color: black, fontFamily: 'Rubik'),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: darkGrey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.cancel_outlined, color: black), // Black Icon
                        onPressed: () => passwordController.clear(),
                      ),
                    ),
                  ),
                ),
              // ----------------------------------------

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
                    elevation: 2.0,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                    setState(() => isLoading = true);
                    bool success = await _verifyPassword(passwordController.text);
                    if (success) {
                      await _executePendingAction();
                      if (context.mounted) {
                        Navigator.pop(context);
                        _showSuccessDialog(context);
                      }
                    } else {
                      setState(() => isLoading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.red,
                            content: Text("Wrong Password"),
                          ),
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
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    String message = 'Changes saved.';
    if (_pendingAction == 'accept') message = 'Order Approved.';
    if (_pendingAction == 'reject') message = 'Order Rejected.';

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
            Text(message, style: const TextStyle(color: black, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: black, foregroundColor: white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12), elevation: 2.0),
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('Back to home', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}