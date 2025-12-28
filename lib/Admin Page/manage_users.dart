import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../colors.dart';
import 'user_detail.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {

  String _searchKeyword = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: black,
        surfaceTintColor: Colors.transparent,
        shadowColor: black,
        elevation: 4.0,
        leading: const BackButton(color: white),
        title: const Text(
          'Users Manager',
          style: TextStyle(
            color: white,
            fontFamily: 'Rubik',
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Material(
              elevation: 4.0,
              shadowColor: Colors.black,
              color: white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
                side: const BorderSide(color: black, width: 1.5),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchKeyword = value.toLowerCase();
                  });
                },
                style: const TextStyle(color: black, fontFamily: 'Rubik'),
                decoration: InputDecoration(
                  hintText: 'Search user',
                  hintStyle: const TextStyle(
                    color: darkGrey,
                    fontFamily: 'Rubik',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                  // Black Icon
                  suffixIcon: const Icon(Icons.search, color: black),
                ),
              ),
            ),
          ),

          // Title section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Text(
              'Users',
              style: TextStyle(
                color: black,
                fontFamily: 'Rubik',
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // User list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: black));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Something went wrong", style: TextStyle(color: black)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users found", style: TextStyle(color: black)));
                }

                final users = snapshot.data!.docs;

                // Filter logic
                final filteredUsers = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['fullName'].toString().toLowerCase();
                  final email = data['email'].toString().toLowerCase();
                  final role = data['role'] ?? 'user';

                  if (role != 'user') return false;

                  return name.contains(_searchKeyword) || email.contains(_searchKeyword);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text("No regular users found", style: TextStyle(color: black)));
                }

                // Build list
                return ListView.separated(
                  itemCount: filteredUsers.length,

                  separatorBuilder: (context, index) => const Divider(color: darkGrey, height: 1),

                  itemBuilder: (context, index) {
                    final userDoc = filteredUsers[index];
                    final userData = userDoc.data() as Map<String, dynamic>;

                    final String fullName = userData['fullName'] ?? 'Unknown';
                    final String email = userData['email'] ?? 'No Email';
                    final String phone = userData['phone'] ?? 'No Phone';
                    final int orders = userData['orders'] ?? 0;

                    return ListTile(
                        tileColor: white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: const Icon(Icons.account_circle, size: 50, color: black),
                        title: Text(
                          fullName,
                          style: const TextStyle(
                            color: black,
                            fontFamily: 'Rubik',
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          email,
                          style: const TextStyle(
                            color: black,
                            fontFamily: 'Rubik',
                            fontSize: 14.0,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert, color: black),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => UserDetailDialog(
                                fullName: fullName,
                                email: email,
                                phone: phone,
                                orderCount: orders,
                              ),
                            );
                          },
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => UserDetailDialog(
                              fullName: fullName,
                              email: email,
                              phone: phone,
                              orderCount: orders,
                            ),
                          );
                        }
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}