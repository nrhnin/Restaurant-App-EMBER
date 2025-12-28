import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../colors.dart';

class UserDetailDialog extends StatelessWidget {
  final String fullName;
  final String email;
  final String phone;
  final int orderCount;

  const UserDetailDialog({
    super.key,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.orderCount,
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Row(
                  children: [
                    const Icon(Icons.account_circle, size: 60, color: black),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        fullName,
                        style: const TextStyle(
                          color: black,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.bold,
                          fontSize: 22.0,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(color: lightGrey, thickness: 1.0),
                const SizedBox(height: 10),

                // Contact details section
                _buildDetailRow("Email:", email),
                const SizedBox(height: 10),
                const Divider(color: lightGrey, thickness: 1.0),
                const SizedBox(height: 10),
                _buildDetailRow("Phone:", phone),
                const SizedBox(height: 10),
                const Divider(color: lightGrey, thickness: 1.0),
                const SizedBox(height: 15),

                // Order history section
                const Text(
                  "Order History:",
                  style: TextStyle(
                    color: black,
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 10),

                // Database connection
                StreamBuilder<QuerySnapshot>(
                  // Query: Find reservations where email matches this user
                  stream: FirebaseFirestore.instance
                      .collection('reservations')
                      .where('email', isEqualTo: email)
                      .snapshots(),
                  builder: (context, snapshot) {
                    // Loading state
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: black));
                    }

                    // Error state
                    if (snapshot.hasError) {
                      return const Text("Error loading history", style: TextStyle(color: Colors.red));
                    }

                    // No data state
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text("No order history found.", style: TextStyle(color: darkGrey, fontStyle: FontStyle.italic)),
                      );
                    }

                    // Data loaded state
                    final orders = snapshot.data!.docs;

                    return Column(
                      children: orders.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final String orderId = data['orderId'] ?? 'Unknown ID';
                        final String date = data['date'] ?? 'Unknown Date';
                        final String pkgName = data['packageName'] ?? '';
                        final double total = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ID and date
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    orderId,
                                    style: const TextStyle(color: black, fontWeight: FontWeight.bold, fontFamily: 'Rubik', fontSize: 13),
                                  ),
                                  Text(
                                    date,
                                    style: const TextStyle(color: black, fontFamily: 'Rubik', fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),

                              // Package name and price
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    pkgName,
                                    style: const TextStyle(color: black, fontFamily: 'Rubik', fontSize: 14),
                                  ),
                                  Text(
                                    "RM ${total.toStringAsFixed(2)}",
                                    style: const TextStyle(color: black, fontWeight: FontWeight.bold, fontFamily: 'Rubik', fontSize: 14),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 25),

                // Close button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: black,
                      foregroundColor: white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      elevation: 4,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Close',
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
      ),
    );
  }

  // Helper widget for email and phone rows
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label ",
          style: const TextStyle(
            color: black,
            fontFamily: 'Rubik',
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: black,
              fontFamily: 'Rubik',
              fontSize: 14.0,
            ),
          ),
        ),
      ],
    );
  }
}