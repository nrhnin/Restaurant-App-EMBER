import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../colors.dart';
import 'booking_page.dart';
import 'menu_page.dart';

class UserPackageDetail extends StatelessWidget {
  final MenuPackage package;

  const UserPackageDetail({
    super.key,
    required this.package,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the image is a URL or a local asset
    bool isNetworkImage = package.imagePath.startsWith('http');

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

            // --- IMAGE SECTION (Updated for Network/Asset Logic) ---
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
              child: isNetworkImage
                  ? CachedNetworkImage(
                imageUrl: package.imagePath,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 250,
                  color: lightGrey,
                  child: const Center(child: CircularProgressIndicator(color: black)),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 250,
                  color: lightGrey,
                  child: const Icon(Icons.broken_image, size: 50, color: darkGrey),
                ),
              )
                  : Image.asset(
                package.imagePath,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: lightGrey,
                    child: const Center(child: Icon(Icons.broken_image, size: 50, color: darkGrey)),
                  );
                },
              ),
            ),

            // --- CONTENT SECTION ---
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        package.name,
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
                        package.description,
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
                        'Price: RM ${package.pricePerPax.toStringAsFixed(0)}',
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

            // --- BUTTONS SECTION ---
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
              child: Row(
                children: [
                  // BACK / CLOSE button
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

                  // BOOK BUTTON
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
                      Navigator.pop(context); // Close the dialog

                      // Navigate to Booking Page
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BookingPage(package: package))
                      );
                    },
                    child: const Text(
                      'Book',
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