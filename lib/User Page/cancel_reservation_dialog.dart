import 'package:flutter/material.dart';
import '../colors.dart';
import 'user_dashboard_page.dart'; // <--- 1. IMPORT THIS

Future<bool?> showCancelReservationDialog(
    BuildContext context, {
      required String date,
      required String time,
      required String pax,
    }) async {

  final bool? result = await showDialog<bool>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header section
            const Text(
              'Cancel Reservation?',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: black,
              ),
            ),
            const SizedBox(height: 20),

            // Booking details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Date:', date),
                const SizedBox(height: 5),
                _detailRow('Time:', time),
                const SizedBox(height: 5),
                _detailRow('Number of pax:', pax),
              ],
            ),

            const SizedBox(height: 30),

            // Buttons section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // No button
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
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

                const SizedBox(width: 20), // Spacing

                // Yes button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: black,
                    foregroundColor: white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    elevation: 2.0,
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    'Yes',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  // If user click yes, show success cancellation dialog
  if (result == true) {
    if (!context.mounted) return result;
    await _showCancelledSuccess(context);
  }

  return result;
}

// Helper for the text rows
Widget _detailRow(String label, String value) {
  return SizedBox(
    width: 180,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold, color: black, fontSize: 16.0)),
        Text(value, style: const TextStyle(fontFamily: 'Rubik', color: black, fontSize: 16.0)),
      ],
    ),
  );
}

// Success confirmation dialog
Future<void> _showCancelledSuccess(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false, // Prevent clicking outside
    builder: (_) => Dialog(
      backgroundColor: white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 50, color: black),
            const SizedBox(height: 15),
            const Text(
              'Reservation has been canceled.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Rubik', color: black, fontSize: 16),
            ),
            const SizedBox(height: 20),

            // --- UPDATED BUTTON ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: black,
                foregroundColor: white,
                elevation: 2.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                // Navigate to Dashboard and clear history
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const UserDashboardPage()),
                      (route) => false,
                );
              },
              child: const Text('Back to home', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ),
  );
}