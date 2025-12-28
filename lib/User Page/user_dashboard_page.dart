import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../colors.dart';
import 'my_reservations_page.dart';
import 'menu_page.dart';
import 'shared_drawer.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  String _userName = "User";

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  // Fetch name from firebase
  Future<void> _fetchUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          setState(() {
            // Get the full name of user
            _userName = userDoc['fullName'] ?? "User";
          });
        }
      } catch (e) {
        print("Error fetching name: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      drawer: AppDrawer(role: _userName),
      appBar: AppBar(
        backgroundColor: black,
        surfaceTintColor: Colors.transparent,
        elevation: 4.0,
        shadowColor: black,
        iconTheme: const IconThemeData(color: white),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: white,
            fontFamily: 'Rubik',
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $_userName!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: black,
                fontFamily: 'Rubik',
              ),
            ),
            const SizedBox(height: 20),

            _dashboardCard(
              context,
              'Menu',
                  () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MenuPage()),
              ),
            ),

            const SizedBox(height: 15),

            _dashboardCard(
              context,
              'My Reservations',
                 () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyReservationsPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard(BuildContext context, String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: Card(
        color: black,
        surfaceTintColor: Colors.transparent,
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w500,
                  color: white,
                  fontFamily: 'Rubik',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}