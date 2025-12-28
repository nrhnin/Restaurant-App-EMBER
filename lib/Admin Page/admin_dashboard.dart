import 'package:flutter/material.dart';
import 'package:mini_project/Guest%20Page/welcome_page.dart';
import '../colors.dart';
import 'manage_menu.dart';
import 'manage_users.dart';
import 'manage_orders.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: white,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: black,
        elevation: 4.0,
        surfaceTintColor: Colors.transparent,
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Admin!',
              style: TextStyle(
                color: black,
                fontFamily: 'Rubik',
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Manage Menu Package
            _DashboardCard(
              text: 'Manage menu packages',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageMenu()),
                );
              },
            ),

            const SizedBox(height: 10),

            // Manage User Accounts
            _DashboardCard(
              text: 'Manage user accounts',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageUsers()),
                );
              },
            ),

            const SizedBox(height: 10),

            // Manage Order Reservations
            _DashboardCard(
              text: 'Manage reservations',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageOrders()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildDrawer(BuildContext context) {

  return Drawer(
    backgroundColor: white,
    surfaceTintColor: Colors.transparent,
    child: Column(
      children: [
        Container(
          color: black,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            bottom: 20,
            left: 20,
            right: 20,
          ),

          child: Row(
            children: [
              const Icon(Icons.account_circle, size: 50, color: white),
              const SizedBox(width: 15),
              const Text(
                'Admin',
                style: TextStyle(
                  color: white,
                  fontFamily: 'Rubik',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              IconButton(
                icon: const Icon(Icons.arrow_back, color: white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),

        const Spacer(),

        Padding(
          padding: const EdgeInsets.all(30.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: black,
                foregroundColor: white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                elevation: 4.0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WelcomePage())
                );
              },
              child: const Text(
                'Log out',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DashboardCard extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: double.infinity,
      height: 120,
      child: Card(
        color: black,
        surfaceTintColor: Colors.transparent,
        shadowColor: black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 4.0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                text,
                style: const TextStyle(
                  color: white,
                  fontFamily: 'Rubik',
                  fontSize: 22.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}