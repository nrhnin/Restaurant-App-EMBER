import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../colors.dart';
import '../Guest Page/welcome_page.dart';

class AppDrawer extends StatelessWidget {
  final String role;

  const AppDrawer({Key? key, this.role = 'User'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            color: black,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20, // Safe area padding
              bottom: 20,
              left: 20,
              right: 20,
            ),
            child: Row(
              children: [

                // User icon
                const Icon(Icons.account_circle, size: 50, color: white),

                const SizedBox(width: 15),

                // Username section
                Expanded(
                  child: Text(
                    role,
                    style: const TextStyle(
                      color: white,
                      fontFamily: 'Rubik',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Back arrow
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Logout button
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
                onPressed: () async {
                  // Sign out from firebase
                  await FirebaseAuth.instance.signOut();

                  // Navigate back to welcome page
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const WelcomePage()),
                          (route) => false,
                    );
                  }
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
}