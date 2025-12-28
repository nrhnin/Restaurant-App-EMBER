import 'package:flutter/material.dart';
import '../colors.dart';
import 'guest_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: white,
      body: Stack(
        children: [
          // Layer 1: Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/welcome_background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: white);
              },
            ),
          ),

          // Layer 2: Dark Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7), // Slightly darker for better readability
            ),
          ),

          // Layer 3: Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  const Spacer(flex: 2),

                  // Header section
                  const Text(
                    'WELCOME TO EMBER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      color: white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),

                  SizedBox(height: 30.0), // Dynamic spacing

                  const Text(
                    'About Us',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      color: white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  SizedBox(height: 30.0),

                  // Description section
                  const Text(
                    'Where culinary artistry meets private luxury. We curate exclusive Western, Japanese, and Malaysian dining experiences designed to ignite your senses and elevate your gatherings. Every menu is a curated masterpiece; every event is an occasion.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      color: white,
                      fontSize: 14.0, // Reduced to 14 for elegance
                      height: 1.5, // Good line spacing
                    ),
                  ),

                  const Text(
                    'Ignite the moment with us.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      color: white,
                      fontSize: 14.0,
                      fontStyle: FontStyle.italic,
                      height: 2.0,
                    ),
                  ),

                  SizedBox(height: 30.0),

                  // Button section
                  SizedBox(
                    width: 220,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GuestPage())
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lightGrey,
                        foregroundColor: black,
                        elevation: 0,
                        alignment: Alignment.center, // Ensures text is centered
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      child: const Text(
                        'BROWSE OUR MENU',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30.0),

                  const Column(
                    children: [
                      Text(
                          'Contact Info',
                          style: TextStyle(fontFamily: 'Rubik', color: white, fontSize: 16, fontWeight: FontWeight.bold)
                      ),

                      SizedBox(height: 5),

                      Text(
                          'emberrestaurant@gmail.com\n03-331 6941',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Rubik', color: white, fontSize: 13, height: 1.4)
                      ),

                      SizedBox(height: 15.0),

                      Text(
                          'Location',
                          style: TextStyle(fontFamily: 'Rubik', color: white, fontSize: 16, fontWeight: FontWeight.bold)
                      ),

                      SizedBox(height: 5),

                      Text(
                          textAlign: TextAlign.center,
                          'C43 L5 Quill City Mall,\n1018, Jalan Sultan Ismail,\n50250 Kuala Lumpur, Malaysia',
                          style: TextStyle(fontFamily: 'Rubik', color: white, fontSize: 13, height: 1.4)
                      ),
                    ],
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}