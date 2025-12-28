import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../colors.dart';
import 'user_package_detail.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // Search and filter state
  String _searchKeyword = "";
  String _selectedFilter = 'Alphabetical';
  final TextEditingController _searchController = TextEditingController();

  // Filter and sort logic
  List<QueryDocumentSnapshot> _filterAndSortItems(List<QueryDocumentSnapshot> items) {
    // Filter by keyword
    var filtered = items.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      String title = (data['title'] ?? '').toString().toLowerCase();
      return title.contains(_searchKeyword);
    }).toList();

    // Filter by selection
    if (_selectedFilter == 'Price (Low - High)') {
      filtered.sort((a, b) {
        num p1 = a['price'] ?? 0;
        num p2 = b['price'] ?? 0;
        return p1.compareTo(p2);
      });
    } else if (_selectedFilter == 'Price (High - Low)') {
      filtered.sort((a, b) {
        num p1 = a['price'] ?? 0;
        num p2 = b['price'] ?? 0;
        return p2.compareTo(p1);
      });
    } else {
      // Alphabetical
      filtered.sort((a, b) {
        String t1 = (a['title'] ?? '').toString();
        String t2 = (b['title'] ?? '').toString();
        return t1.compareTo(t2);
      });
    }

    return filtered;
  }

  // Filter dialog
  void _showFilterDialog() {
    String tempFilter = _selectedFilter;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Select filter', style: TextStyle(color: black, fontFamily: 'Rubik', fontSize: 18, fontWeight: FontWeight.bold)),
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
                  child: const Text('Reset', style: TextStyle(color: black, fontFamily: 'Rubik', fontWeight: FontWeight.bold)),
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

  // Helper for filter dialog buttons
  Widget _buildRadioOption(String title, String current, ValueChanged<String?> onChanged) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(color: black, fontFamily: 'Rubik', fontSize: 16)),
      value: title,
      groupValue: current,
      activeColor: black,
      fillColor: MaterialStateProperty.resolveWith((states) => black),
      contentPadding: EdgeInsets.zero,
      onChanged: onChanged,
    );
  }

  // Package detail popup dialog
  void _showPackageDetail(Map<String, dynamic> data) {
    final pkgObject = MenuPackage(
      name: data['title'] ?? 'Unknown',
      description: data['description'] ?? 'No description',
      pricePerPax: (data['price'] ?? 0).toDouble(),
      imagePath: data['image'] ?? '',
    );

    // Show the detail package dialog
    showDialog(
      context: context,
      builder: (context) => UserPackageDetail(package: pkgObject),
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
        iconTheme: const IconThemeData(color: white),
        title: const Text('Menu Packages', style: TextStyle(color: white, fontFamily: 'Rubik', fontSize: 20.0, fontWeight: FontWeight.bold)),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Search bar section
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

          // Live grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('menu').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: black));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No menu packages available.', style: TextStyle(fontFamily: 'Rubik')));
                }

                final packages = _filterAndSortItems(snapshot.data!.docs);

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
                    final data = packages[index].data() as Map<String, dynamic>;

                    // Image logic
                    String imagePath = data['image'] ?? '';
                    bool isNetworkImage = imagePath.startsWith('http');

                    return Card(
                      color: black,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                      elevation: 4.0,
                      shadowColor: Colors.black,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _showPackageDetail(data),
                        child: Column(
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
                                placeholder: (c, u) => Container(color: Colors.grey[200]),
                                errorWidget: (c, u, e) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, color: darkGrey)),
                              )
                                  : Image.asset(
                                imagePath,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (c, o, s) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, color: darkGrey)),
                              ),
                            ),

                            // Text section
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      data['title'] ?? 'Untitled',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: white, fontFamily: 'Rubik', fontWeight: FontWeight.bold, fontSize: 16.0),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "RM ${data['price']}",
                                      style: const TextStyle(color: white, fontFamily: 'Rubik', fontSize: 12.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

class MenuPackage {
  final String name;
  final String description;
  final double pricePerPax;
  final String imagePath;

  MenuPackage({
    required this.name,
    required this.description,
    required this.pricePerPax,
    required this.imagePath,
  });
}