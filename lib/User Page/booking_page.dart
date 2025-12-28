import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../colors.dart';
import 'menu_page.dart';
import 'user_dashboard_page.dart';

class BookingPage extends StatefulWidget {
  final MenuPackage package;

  const BookingPage({super.key, required this.package});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  int pax = 1;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 12, minute: 0);
  bool isBooking = false;

  double get subtotal => pax * widget.package.pricePerPax;
  double get tax => subtotal * 0.06;
  double get totalPrice => subtotal + tax;

  // Logic for date and time picker
  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: black, onPrimary: white, onSurface: black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  void _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      confirmText: 'Apply',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: black, onPrimary: white, onSurface: black),
            timePickerTheme: TimePickerThemeData(
              dayPeriodColor: MaterialStateColor.resolveWith((states) =>
              states.contains(MaterialState.selected) ? black : Colors.transparent),
              dayPeriodTextColor: MaterialStateColor.resolveWith((states) =>
              states.contains(MaterialState.selected) ? white : black),
              dayPeriodBorderSide: const BorderSide(color: black),
              dialBackgroundColor: lightGrey,
              cancelButtonStyle: TextButton.styleFrom(foregroundColor: black),
              confirmButtonStyle: ElevatedButton.styleFrom(
                backgroundColor: black, foregroundColor: white, elevation: 2.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  // Success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tick icon
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    color: black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: white, size: 40),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  "Booking Successful!",
                  style: TextStyle(color: black, fontFamily: 'Rubik', fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Message
                const Text(
                  "Your reservation has been placed successfully.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: darkGrey, fontFamily: 'Rubik', fontSize: 14),
                ),
                const SizedBox(height: 25),

                // Back to home button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: black,
                      foregroundColor: white,
                      elevation: 2.0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const UserDashboardPage()),
                            (route) => false,
                      );
                    },
                    child: const Text("Back to Home", style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Save booking to firebase
  Future<void> _confirmBooking() async {
    setState(() => isBooking = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      String guestName = userData['fullName'] ?? 'Unknown';
      String email = userData['email'] ?? 'No Email';
      String phone = userData['phone'] ?? 'No Phone';

      String orderId = "ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
      String dateStr = "${selectedDate.day.toString().padLeft(2,'0')}-${selectedDate.month.toString().padLeft(2,'0')}-${selectedDate.year}";

      await FirebaseFirestore.instance.collection('reservations').add({
        'orderId': orderId,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'date': dateStr,
        'time': selectedTime.format(context),
        'guestId': user.uid,
        'guestName': guestName,
        'email': email,
        'phone': phone,
        'packageName': widget.package.name,
        'packagePrice': widget.package.pricePerPax,
        'pax': pax,
        'tax': tax,
        'totalPrice': totalPrice,
        'image': widget.package.imagePath,
      });

      // Show success dialog
      if (mounted) {
        _showSuccessDialog();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: errorRed, content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => isBooking = false);
    }
  }

  Widget _buildPaxCircle(int number) {
    bool isSelected = (pax == number);
    return GestureDetector(
      onTap: () => setState(() => pax = number),
      child: Container(
        width: 40, height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? black : white,
          border: Border.all(color: black),
        ),
        child: Center(
          child: Text(
            "$number",
            style: TextStyle(color: isSelected ? white : black, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isNetworkImage = widget.package.imagePath.startsWith('http');

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: black,
        surfaceTintColor: Colors.transparent,
        elevation: 4.0,
        shadowColor: Colors.black,
        leading: const BackButton(color: white),
        title: const Text('Booking', style: TextStyle(color: white, fontFamily: 'Rubik', fontSize: 20.0, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: black, borderRadius: BorderRadius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  isNetworkImage
                      ? CachedNetworkImage(
                    imageUrl: widget.package.imagePath, height: 180, width: double.infinity, fit: BoxFit.cover,
                    placeholder: (c, u) => Container(height: 180, color: Colors.grey[200]),
                    errorWidget: (c, u, e) => Container(height: 180, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 50)),
                  )
                      : Image.asset(widget.package.imagePath, height: 180, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(height: 180, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 50))),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(widget.package.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Rubik', color: white)),
                        const SizedBox(height: 5),
                        Text("RM ${widget.package.pricePerPax.toStringAsFixed(0)} / pax", style: const TextStyle(color: white, fontSize: 16, fontFamily: 'Rubik')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Number of pax selector
            const Row(children: [Icon(Icons.person, color: black), SizedBox(width: 8), Text("Number of pax", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Rubik'))]),
            const SizedBox(height: 15),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: List.generate(10, (index) => _buildPaxCircle(index + 1)))),
            const SizedBox(height: 20),
            const Divider(color: lightGrey),
            const SizedBox(height: 20),

            // Date and time display
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("${selectedDate.day}-${selectedDate.month}-${selectedDate.year}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(selectedTime.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),

            const SizedBox(height: 15),

            // Date and time buttons
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_today, size: 16, color: black), label: const Text("Choose Date", style: TextStyle(color: black)), style: OutlinedButton.styleFrom(side: const BorderSide(color: black), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 12)))),
              const SizedBox(width: 15),
              Expanded(child: OutlinedButton.icon(onPressed: _pickTime, icon: const Icon(Icons.access_time, size: 16, color: black), label: const Text("Choose Time", style: TextStyle(color: black)), style: OutlinedButton.styleFrom(side: const BorderSide(color: black), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 12)))),
            ]),

            const SizedBox(height: 20),
            const Divider(color: lightGrey),
            const SizedBox(height: 20),

            // Booking summary section
            _buildSummaryRow("Menu Package", widget.package.name),
            const SizedBox(height: 10),
            _buildSummaryRow("Pax.", "$pax", isBold: false),
            const SizedBox(height: 10),
            _buildSummaryRow("Price", "RM ${subtotal.toStringAsFixed(2)}"),
            const SizedBox(height: 10),
            _buildSummaryRow("Tax (6%)", "RM ${tax.toStringAsFixed(2)}"),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Total Price", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Rubik')),
              Text("RM ${totalPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Rubik')),
            ]),
            const SizedBox(height: 30),

            // Action buttons
            Row(children: [
              Expanded(child: TextButton(style: ElevatedButton.styleFrom(backgroundColor: white, foregroundColor: black, elevation: 2.0, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)))),
              const SizedBox(width: 15),
              Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: black, foregroundColor: white, elevation: 2.0, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), onPressed: isBooking ? null : _confirmBooking, child: isBooking ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: white, strokeWidth: 2)) : const Text("Book", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = true}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: darkGrey, fontSize: 14)),
      Text(value, style: TextStyle(color: black, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
    ]);
  }
}