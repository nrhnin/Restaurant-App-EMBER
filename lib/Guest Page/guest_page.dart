import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../colors.dart';
import 'guest_package_detail.dart';
import 'login_page.dart';
import 'register_page.dart';

class GuestPage extends StatefulWidget {
  const GuestPage({super.key});

  @override
  State<GuestPage> createState() => _GuestPageState();
}

class _GuestPageState extends State<GuestPage> {

  // Search and filter controllers
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = "";
  String _selectedFilter = 'Alphabetical';

  // Filter and sort items from database
  List<QueryDocumentSnapshot> _filterAndSortItems(List<QueryDocumentSnapshot> items) {
    // Filter by search keyword
    var filtered = items.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return data['title'].toString().toLowerCase().contains(_searchKeyword);
    }).toList();

    // Filter by selection
    if (_selectedFilter == 'Price (Low - High)') {
      filtered.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
    } else if (_selectedFilter == 'Price (High - Low)') {
      filtered.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
    } else {
      filtered.sort((a, b) => a['title'].toString().compareTo(b['title'].toString()));
    }

    return filtered;
  }

  // Filter dialog
  void _showFilterDialog() {
    // Temporary variable to hold selection before applying
    String tempFilter = _selectedFilter;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Allows the dialog to update internally without closing
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

                  // Options using the temporary variable
                  _buildRadioOption('Alphabetical', tempFilter, (val) {
                    setDialogState(() => tempFilter = val!);
                  }),
                  _buildRadioOption('Price (Low - High)', tempFilter, (val) {
                    setDialogState(() => tempFilter = val!);
                  }),
                  _buildRadioOption('Price (High - Low)', tempFilter, (val) {
                    setDialogState(() => tempFilter = val!);
                  }),
                ],
              ),

              actions: [
                // Reset button
                TextButton(
                    onPressed: () {
                      setDialogState(() => tempFilter = 'Alphabetical');
                    },
                    child: const Text('Reset', style: TextStyle(color: black, fontFamily: 'Rubik', fontWeight: FontWeight.bold))
                ),

                // Apply button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: black,
                    foregroundColor: white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () {
                    // Commit changes to the real variable
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

  // Helper widget for filter buttons
  Widget _buildRadioOption(String title, String currentGroupValue, ValueChanged<String?> onChanged) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(color: black, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 16)),
      value: title,
      groupValue: currentGroupValue,

      // Selected color
      activeColor: black,

      // Unselected color
      fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        // Return black for all states (disabled, selected, unselected)
        return black;
      }),

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
        elevation: 4.0,
        shadowColor: black,
        leading: const BackButton(color: white),
        title: const Text('Our Menu', style: TextStyle(color: white, fontFamily: 'Rubik', fontSize: 20.0, fontWeight: FontWeight.bold)),
          actions: [

            // Login button
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage())
                );
              },
              child: const Text(
                "LOG IN",
                style: TextStyle(color: white, fontFamily: 'Rubik', fontWeight: FontWeight.bold),
              ),
            ),

            const Text(
              "|",
              style: TextStyle(color: white, fontSize: 16),
            ),

            // Sign up button
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage())
                );
              },
              child: const Text(
                "SIGN UP",
                style: TextStyle(color: white, fontFamily: 'Rubik', fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(width: 10),
          ],
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
                controller: _searchController,
                onChanged: (value) => setState(() => _searchKeyword = value.toLowerCase()),
                style: const TextStyle(color: black),
                decoration: InputDecoration(
                  hintText: 'Search menu packages',
                  hintStyle: const TextStyle(color: darkGrey, fontFamily: 'Rubik'),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
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
            child: Text('Menu Packages', style: TextStyle(color: black, fontFamily: 'Rubik', fontSize: 22.0, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),

          // Live grid display from database
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('menu').snapshots(),
              builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: darkGrey));
                }

                // No data state
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No menu items available.', style: TextStyle(color: black, fontSize: 16)));
                }

                // Filter and sort data state
                final packages = _filterAndSortItems(snapshot.data!.docs);

                if (packages.isEmpty) {
                  return const Center(child: Text('No results found.', style: TextStyle(color: black, fontSize: 16)));
                }

                // Build grid
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemCount: packages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final doc = packages[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _MenuPackageCard(
                      title: data['title'] ?? 'Untitled',
                      price: "RM${data['price']}",
                      imagePath: data['image'] ?? '',
                      onTap: () {
                        // Navigate to Detail Page
                        showDialog(
                          context: context,
                          builder: (context) => GuestPackageDetail(
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

// Widget helper for cards
class _MenuPackageCard extends StatelessWidget {
  final String title;
  final String price;
  final String imagePath;
  final VoidCallback onTap;

  const _MenuPackageCard({
    required this.title,
    required this.price,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isNetworkImage = imagePath.startsWith('http');

    return Card(
      color: black,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 4.0,
      shadowColor: Colors.black,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Image area
            Expanded(
              flex: 3,
              child: isNetworkImage
                  ? CachedNetworkImage(
                imageUrl: imagePath,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator(color: lightGrey))),
                errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, color: black)),
              )
                  : Image.asset(imagePath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => Container(
                      color: Colors.grey,
                      child: const Icon(Icons.broken_image, color: darkGrey))),
            ),

            // Text area
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: white,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      price,
                      style: const TextStyle(
                          color: white,
                          fontFamily: 'Rubik',
                          fontSize: 12.0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}