import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../colors.dart';
import 'package_detail.dart';
import 'edit_menu_package.dart';
import 'add_menu_package.dart';

class ManageMenu extends StatefulWidget {
  const ManageMenu({super.key});

  @override
  State<ManageMenu> createState() => _ManageMenuState();
}

class _ManageMenuState extends State<ManageMenu> {
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = "";
  String _selectedFilter = 'Alphabetical';

  // Filter and sort logic
  List<QueryDocumentSnapshot> _filterAndSortItems(List<QueryDocumentSnapshot> items) {
    var filtered = items.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return data['title'].toString().toLowerCase().contains(_searchKeyword);
    }).toList();

    if (_selectedFilter == 'Price (Low - High)') {
      filtered.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
    } else if (_selectedFilter == 'Price (High - Low)') {
      filtered.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
    } else {
      filtered.sort((a, b) => a['title'].toString().compareTo(b['title'].toString()));
    }
    return filtered;
  }

  Future<bool> _reauthenticateUser(String password) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _deleteMenu(String id) async {
    await FirebaseFirestore.instance.collection('menu').doc(id).delete();
  }

  void _showPasswordAuthDialog({required String actionName, required Function onSuccess}) {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: white,
        title: const Text('Admin Security Check', style: TextStyle(color: black, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter password to $actionName this item.", style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: darkGrey))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: black),
              onPressed: () async {
                bool success = await _reauthenticateUser(passwordController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    onSuccess();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success! Database updated.")));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text("Wrong Password!")));
                  }
                }
              },
              child: const Text("Confirm", style: TextStyle(color: white))
          )
        ],
      ),
    );
  }

  // Filter dialog
  void _showFilterDialog() {
    String tempFilter = _selectedFilter;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Select filter', style: TextStyle(color: black, fontFamily: 'Rubik', fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(color: darkGrey, thickness: 1.0),
                  _buildRadioOption('Alphabetical', tempFilter, (val) => setDialogState(() => tempFilter = val!)),
                  _buildRadioOption('Price (Low - High)', tempFilter, (val) => setDialogState(() => tempFilter = val!)),
                  _buildRadioOption('Price (High - Low)', tempFilter, (val) => setDialogState(() => tempFilter = val!)),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => setDialogState(() => tempFilter = 'Alphabetical'),
                    child: const Text('Reset', style: TextStyle(color: black, fontFamily: 'Rubik', fontWeight: FontWeight.bold))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: black,
                    foregroundColor: white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    setState(() => _selectedFilter = tempFilter);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper for filter buttons
  Widget _buildRadioOption(String title, String currentGroupValue, ValueChanged<String?> onChanged) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(color: black, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 16)),
      value: title,
      groupValue: currentGroupValue,
      activeColor: black,
      fillColor: MaterialStateProperty.resolveWith((states) => black),
      contentPadding: EdgeInsets.zero,
      onChanged: onChanged,
    );
  }

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
        title: const Text('Manage Menu', style: TextStyle(color: white, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 20)),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: black,
        child: const Icon(Icons.add, color: white, size: 30),
        onPressed: () {
          showDialog(context: context, builder: (context) => const AddPackageDialog());
        },
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Material(
              elevation: 4.0,
              shadowColor: Colors.black,
              color: white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(color: black, width: 1.5),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchKeyword = val.toLowerCase()),
                style: const TextStyle(color: black, fontFamily: 'Rubik'),
                decoration: InputDecoration(
                  hintText: 'Search menu packages',
                  hintStyle: const TextStyle(color: darkGrey, fontFamily: 'Rubik'),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  prefixIcon: IconButton(
                      icon: const Icon(Icons.filter_list, color: black),
                      onPressed: _showFilterDialog
                  ),
                  suffixIcon: _searchKeyword.isNotEmpty
                      ? IconButton(
                      icon: const Icon(Icons.close, color: black),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchKeyword = '');
                      })
                      : const Icon(Icons.search, color: black),
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text('Menu Packages', style: TextStyle(color: black, fontFamily: 'Rubik', fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('menu').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: darkGrey));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No items in database.", style: TextStyle(color: black)));

                final packages = _filterAndSortItems(snapshot.data!.docs);

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10
                  ),
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final doc = packages[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _MenuPackageCard(
                      title: data['title'],
                      price: "RM${data['price']}",
                      imagePath: data['image'] ?? '',

                      onEdit: () {
                        showDialog(
                          context: context,
                          builder: (context) => EditPackageDialog(
                            docId: doc.id,
                            initialTitle: data['title'],
                            initialPrice: data['price'].toString(),
                            initialDescription: data['description'],
                            imagePath: data['image'] ?? '',
                          ),
                        );
                      },
                      onDelete: () => _showPasswordAuthDialog(
                        actionName: "Delete",
                        onSuccess: () => _deleteMenu(doc.id),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => PackageDetailDialog(
                            docId: doc.id,
                            title: data['title'],
                            price: "RM${data['price']}",
                            imagePath: data['image'] ?? '',
                            description: data['description'] ?? '',
                          ),
                        );
                      },
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

// Card widgets
class _MenuPackageCard extends StatelessWidget {
  final String title;
  final String price;
  final String imagePath;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MenuPackageCard({
    required this.title, required this.price, required this.imagePath, required this.onTap,
    required this.onEdit, required this.onDelete
  });

  @override
  Widget build(BuildContext context) {
    bool isNetworkImage = imagePath.startsWith('http');

    return Card(
      color: black,
      surfaceTintColor: Colors.transparent,
      shadowColor: black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 4.0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section
                Expanded(
                  flex: 3,
                  child: isNetworkImage
                      ? CachedNetworkImage(
                    imageUrl: imagePath,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, color: darkGrey)),
                  )
                      : Image.asset(imagePath, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,o,s) => Container(color: Colors.grey)),
                ),

                // Details section
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0), // Reduced Padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: white, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 16.0)
                        ),
                        const SizedBox(height: 2),
                        Text(
                            price,
                            style: const TextStyle(color: white, fontFamily: 'Rubik', fontSize: 12.0)
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}