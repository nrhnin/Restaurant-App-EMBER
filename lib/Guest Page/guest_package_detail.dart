import 'package:flutter/material.dart';
import '../colors.dart';
import 'login_page.dart';

class GuestPackageDetail extends StatelessWidget {
  final String title;
  final String price;
  final String imagePath;
  final String description;

  const GuestPackageDetail({
    super.key,
    required this.title,
    required this.price,
    required this.imagePath,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {

    return Dialog(
      backgroundColor: white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),

      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Image section
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
              child: Image.asset(
                imagePath,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.grey,
                    child: const Center(child: Icon(Icons.broken_image, size: 50)),
                  );
                },
              ),
            ),

            // Content section
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          color: black,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.bold,
                          fontSize: 24.0,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Description
                      Text(
                        description,
                        style: const TextStyle(
                          color: black,
                          fontFamily: 'Rubik',
                          fontSize: 14.0,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Price label
                      Text(
                        'Price: $price',
                        style: const TextStyle(
                          color: black,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Buttons section
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
              child: Row(
                children: [
                  // CLOSE button
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: black,
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ORDER button
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
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage())
                      );
                    },
                    child: const Text(
                      'Order',
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
      ),
    );
  }
}