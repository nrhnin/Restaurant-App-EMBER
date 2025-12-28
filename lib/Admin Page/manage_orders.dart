import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../colors.dart';
import 'order_detail.dart';

class ManageOrders extends StatefulWidget {
  const ManageOrders({super.key});

  @override
  State<ManageOrders> createState() => _ManageOrdersState();
}

class _ManageOrdersState extends State<ManageOrders> {
  // Toggle state
  bool _isBookedSelected = true;

  // Search and filter state
  String _searchKeyword = "";
  DateTime? _selectedDate;

  // Filter data on client-side
  List<QueryDocumentSnapshot> _filterOrders(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // Status filter
      String status = data['status'] ?? 'Pending';
      if (_isBookedSelected && status != 'Approved') return false;
      if (!_isBookedSelected && status != 'Pending') return false;

      // Search filter by order ID
      String orderId = data['orderId'] ?? doc.id;
      if (!orderId.toLowerCase().contains(_searchKeyword.toLowerCase())) {
        return false;
      }

      // Date filter
      if (_selectedDate != null) {
        String orderDate = data['date'] ?? '';
        String filterDateStr = "${_selectedDate!.day.toString().padLeft(2,'0')}-${_selectedDate!.month.toString().padLeft(2,'0')}-${_selectedDate!.year}";

        if (orderDate != filterDateStr) return false;
      }

      return true;
    }).toList();
  }

  // Date picker logic
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: black,
              onPrimary: white,
              onSurface: black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: black),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Order detail dialog
  void _openOrderDetail(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) => OrderDetailDialog(
        docId: doc.id,
        orderId: data['orderId'] ?? doc.id,
        date: data['date'] ?? 'Unknown Date',
        isPendingMode: !_isBookedSelected,

        // Pass new data
        guestName: data['guestName'] ?? 'Unknown Guest',
        email: data['email'] ?? 'No Email',
        phone: data['phone'] ?? 'No Phone',
        packageName: data['packageName'] ?? 'Standard',
        pax: data['pax'] ?? 0,
        currentPrice: (data['totalPrice'] ?? 0).toDouble(),
      ),
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
        title: const Text(
          'Order Manager',
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
              color: white, // White Background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
                side: const BorderSide(color: black, width: 1.5),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchKeyword = value;
                  });
                },
                style: const TextStyle(color: black, fontFamily: 'Rubik'),
                decoration: InputDecoration(
                  hintText: _selectedDate == null
                      ? 'Search order ID'
                      : 'Date: ${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}',
                  hintStyle: const TextStyle(
                    color: darkGrey,
                    fontFamily: 'Rubik',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0),

                  // Calendar button
                  prefixIcon: IconButton(
                    icon: Icon(
                      Icons.calendar_today,
                      color: _selectedDate != null ? black : black,
                    ),
                    onPressed: _pickDate,
                  ),

                  // Clear filter button
                  suffixIcon: _selectedDate != null
                      ? IconButton(
                    icon: const Icon(Icons.close, color: black),
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                      });
                    },
                  )
                      : const Icon(Icons.search, color: black), // Black Search Icon
                ),
              ),
            ),
          ),

          // Title page
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Orders',
              style: TextStyle(
                color: black,
                fontFamily: 'Rubik',
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // Toggle buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                // Booked button
                Expanded(
                  child: _buildToggleButton(
                    text: 'Booked',
                    isSelected: _isBookedSelected,
                    hasCheckmark: true,
                    onTap: () {
                      setState(() {
                        _isBookedSelected = true;
                      });
                    },
                  ),
                ),

                // Pending button
                Expanded(
                  child: _buildToggleButton(
                    text: 'Pending',
                    isSelected: !_isBookedSelected,
                    hasCheckmark: false,
                    onTap: () {
                      setState(() {
                        _isBookedSelected = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // Live list of orders
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reservations')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: black));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong', style: TextStyle(color: black)));
                }

                final allDocs = snapshot.data?.docs ?? [];
                final filteredList = _filterOrders(allDocs);

                if (filteredList.isEmpty) {
                  return const Center(
                    child: Text(
                      'No orders found',
                      style: TextStyle(color: black, fontSize: 16),
                    ),
                  );
                }

                // 2. UPDATED LIST VIEW
                return ListView.separated(
                  itemCount: filteredList.length,

                  // Solid Dark Grey Divider
                  separatorBuilder: (context, index) => const Divider(color: darkGrey, height: 1),

                  itemBuilder: (context, index) {
                    final doc = filteredList[index];
                    final data = doc.data() as Map<String, dynamic>;

                    String displayId = data['orderId'] ?? doc.id;

                    return ListTile(
                      tileColor: white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      title: Text(
                        displayId,
                        style: const TextStyle(
                          color: black,
                          fontFamily: 'Rubik',
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert, color: black),
                        onPressed: () => _openOrderDetail(doc),
                      ),
                      onTap: () => _openOrderDetail(doc),
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

  // Helper widgets for toggle buttons
  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required bool hasCheckmark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? black : white,
          border: Border.all(color: black, width: 1.5),
          borderRadius: text == 'Booked'
              ? const BorderRadius.horizontal(left: Radius.circular(20))
              : const BorderRadius.horizontal(right: Radius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasCheckmark && isSelected) ...[
              const Icon(Icons.check, size: 18, color: white),
              const SizedBox(width: 5),
            ],

            Text(
              text,
              style: TextStyle(
                color: isSelected ? white : black,
                fontFamily: 'Rubik',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}