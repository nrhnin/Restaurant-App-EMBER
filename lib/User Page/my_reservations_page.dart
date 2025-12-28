import 'package:flutter/material.dart';
import 'history_page.dart';
import 'upcoming_bookings_page.dart';
import '../colors.dart';

class MyReservationsPage extends StatelessWidget {
  const MyReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: black,
        surfaceTintColor: Colors.transparent,
        elevation: 4.0,
        shadowColor: black,
        leading: const BackButton(color: white),
        title: const Text(
          'My Reservations',
          style: TextStyle(
            color: white,
            fontFamily: 'Rubik',
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildReservationCard(
              context,
              'History',
              Icons.receipt_long,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
              },
            ),

            const SizedBox(height: 20),

            _buildReservationCard(
              context,
              'Upcoming Bookings',
              Icons.notifications,
                  () {
                // Navigation Logic
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UpcomingBookingsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper for widget cards
  Widget _buildReservationCard(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onTap,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: Card(
        color: black,
        surfaceTintColor: Colors.transparent,
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: white, size: 28),
              const SizedBox(width: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w500,
                  color: white,
                  fontFamily: 'Rubik',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}