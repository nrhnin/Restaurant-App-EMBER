import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../colors.dart';
import 'user_dashboard_page.dart'; // <--- IMPORT DASHBOARD FOR NAVIGATION

class EditReservationSheet extends StatefulWidget {
  final Map<String, dynamic>? bookingData;
  final String reservationId;

  const EditReservationSheet({
    super.key,
    this.bookingData,
    required this.reservationId,
  });

  @override
  State<EditReservationSheet> createState() => _EditReservationSheetState();
}

class _EditReservationSheetState extends State<EditReservationSheet> {
  // State Variables
  late int people;
  late int qty;

  // Date & Time
  late DateTime selectedDateObj;
  late TimeOfDay selectedTimeObj;

  String? selectedPackageName;
  double packagePrice = 0.0;

  bool isSaving = false;
  bool isLoadingMenu = true;

  // List to store menu packages from database
  List<Map<String, dynamic>> menuItems = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchMenuPackages();
  }

  // Initialize data from existing booking
  void _initializeData() {
    if (widget.bookingData != null) {
      people = widget.bookingData!['pax'] ?? 1;
      qty = widget.bookingData!['pax'] ?? 1;

      try {
        String dStr = widget.bookingData!['date'];
        List<String> parts = dStr.split('-');
        selectedDateObj = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } catch (e) {
        selectedDateObj = DateTime.now();
      }

      try {
        String tStr = widget.bookingData!['time'];
        selectedTimeObj = _parseTime(tStr);
      } catch (e) {
        selectedTimeObj = TimeOfDay.now();
      }

      selectedPackageName = widget.bookingData!['packageName'];
      packagePrice = (widget.bookingData!['packagePrice'] as num?)?.toDouble() ?? 0.0;
    } else {
      people = 1;
      qty = 1;
      selectedDateObj = DateTime.now();
      selectedTimeObj = TimeOfDay.now();
      selectedPackageName = null;
      packagePrice = 0.0;
    }
  }

  // Helper to parse string back to time-of-day
  TimeOfDay _parseTime(String s) {
    try {
      final format = RegExp(r"(\d+):(\d+)\s(\w+)");
      final match = format.firstMatch(s);
      if (match != null) {
        int h = int.parse(match.group(1)!);
        int m = int.parse(match.group(2)!);
        String amPm = match.group(3)!;
        if (amPm.toLowerCase() == "pm" && h != 12) h += 12;
        if (amPm.toLowerCase() == "am" && h == 12) h = 0;
        return TimeOfDay(hour: h, minute: m);
      }
    } catch (e) {
      return TimeOfDay.now();
    }
    return TimeOfDay.now();
  }

  // Fetch menu packages from database
  Future<void> _fetchMenuPackages() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('menu').get();

      List<Map<String, dynamic>> loadedItems = [];
      for (var doc in snapshot.docs) {
        loadedItems.add({
          'title': doc['title'],
          'price': (doc['price'] as num).toDouble(),
        });
      }

      setState(() {
        menuItems = loadedItems;
        isLoadingMenu = false;

        if (selectedPackageName == null || !menuItems.any((item) => item['title'] == selectedPackageName)) {
          if (menuItems.isNotEmpty) {
            selectedPackageName = menuItems[0]['title'];
            packagePrice = menuItems[0]['price'];
          }
        } else {
          var currentItem = menuItems.firstWhere((item) => item['title'] == selectedPackageName);
          packagePrice = currentItem['price'];
        }
      });
    } catch (e) {
      print("Error loading menu: $e");
      setState(() => isLoadingMenu = false);
    }
  }

  // --- NEW SUCCESS DIALOG ---
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent clicking outside to close
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon (Black Circle)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    color: black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: white, size: 40),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  "Update Successful!",
                  style: TextStyle(color: black, fontFamily: 'Rubik', fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Message
                const Text(
                  "Your reservation details have been updated.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: darkGrey, fontFamily: 'Rubik', fontSize: 14),
                ),
                const SizedBox(height: 25),

                // Back to Home Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: black,
                      foregroundColor: white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      // Navigate to user dashboard and clear history
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const UserDashboardPage()),
                            (route) => false,
                      );
                    },
                    child: const Text("Back to Home", style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Save changes to database
  Future<void> _saveChanges() async {
    setState(() => isSaving = true);

    double subtotal = packagePrice * qty;
    double tax = subtotal * 0.06;
    double total = subtotal + tax;

    String dateStr = "${selectedDateObj.day.toString().padLeft(2,'0')}-${selectedDateObj.month.toString().padLeft(2,'0')}-${selectedDateObj.year}";
    String timeStr = selectedTimeObj.format(context);

    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.reservationId)
          .update({
        'pax': people,
        'date': dateStr,
        'time': timeStr,
        'packageName': selectedPackageName,
        'packagePrice': packagePrice,
        'totalPrice': total,
        'tax': tax,
      });

      // Show the Success Dialog instead of popping immediately
      if (mounted) {
        _showSuccessDialog();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  // Date picker function
  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDateObj,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: black, onPrimary: white, onSurface: black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedDateObj = picked);
  }

  // Time picker function
  void _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTimeObj,
      confirmText: 'Apply',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: black, onPrimary: white, onSurface: black),
            timePickerTheme: TimePickerThemeData(
              dayPeriodColor: MaterialStateColor.resolveWith((states) =>
              states.contains(MaterialState.selected) ? black : Colors.transparent),
              dayPeriodTextColor: MaterialStateColor.resolveWith((states) =>
              states.contains(MaterialState.selected) ? white : black),
              dayPeriodBorderSide: const BorderSide(color: black),
              dialBackgroundColor: lightGrey,
              cancelButtonStyle: TextButton.styleFrom(foregroundColor: black),
              confirmButtonStyle: ElevatedButton.styleFrom(
                  backgroundColor: black, foregroundColor: white, elevation: 0),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedTimeObj = picked);
  }

  @override
  Widget build(BuildContext context) {

    String dateDisplay = "${selectedDateObj.day}-${selectedDateObj.month}-${selectedDateObj.year}";
    String timeDisplay = selectedTimeObj.format(context);

    return Theme(
      data: Theme.of(context).copyWith(useMaterial3: false),
      child: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: isLoadingMenu
              ? const Center(child: CircularProgressIndicator(color: black))
              : Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),

              // Title section
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('Edit Reservation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Rubik')),
              ),

              const Divider(),

              // Edit content section
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Select number of pax
                      const Text("Number of pax", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Rubik')),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            final value = index + 1;
                            final selected = value == people;
                            return GestureDetector(
                              onTap: () => setState(() {
                                people = value;
                                qty = value;
                              }),
                              child: Container(
                                width: 45,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: white,
                                  border: Border.all(color: selected ? black : Colors.grey, width: selected ? 2 : 1),
                                ),
                                child: Center(
                                  child: Text(
                                    '$value',
                                    style: TextStyle(
                                        color: black,
                                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 16,
                                        fontFamily: 'Rubik'
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Date and time buttons section
                      const Text("Date & Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Rubik')),
                      const SizedBox(height: 5),

                      // Display the current choice
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dateDisplay, style: const TextStyle(fontSize: 14, color: darkGrey)),
                          Text(timeDisplay, style: const TextStyle(fontSize: 14, color: darkGrey)),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Buttons section
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_today, size: 16, color: black),
                              label: const Text("Choose Date", style: TextStyle(color: black)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: black),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickTime,
                              icon: const Icon(Icons.access_time, size: 16, color: black),
                              label: const Text("Choose Time", style: TextStyle(color: black)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: black),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Menu package dropdown section
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Menu Package', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Rubik')),
                          Text('Pax.', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Rubik')),
                          Text('Price', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Rubik')),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          // Dropdown function
                          Expanded(
                              flex: 3,
                              child: Container(
                                height: 45,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: black)
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedPackageName,
                                    isExpanded: true,
                                    hint: const Text("Select Package"),
                                    items: menuItems.map((item) {
                                      return DropdownMenuItem<String>(
                                        value: item['title'],
                                        child: Text(item['title'], overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          selectedPackageName = newValue;
                                          packagePrice = menuItems.firstWhere((item) => item['title'] == newValue)['price'];
                                        });
                                      }
                                    },
                                  ),
                                ),
                              )
                          ),

                          const SizedBox(width: 10),

                          // Number of pax display
                          Expanded(
                              flex: 1,
                              child: Container(
                                height: 45,
                                decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(10)),
                                child: Center(child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold))),
                              )
                          ),

                          const SizedBox(width: 10),

                          // Price section
                          Expanded(
                              flex: 1,
                              child: Text(
                                'RM ${packagePrice.toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontFamily: 'Rubik'),
                              )
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Total price summary
                      _priceSummary(),
                    ],
                  ),
                ),
              ),

              // Action buttons section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Rubik', fontSize: 16)),
                      ),
                    ),

                    const SizedBox(width: 15),

                    // Save button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: black,
                          foregroundColor: white,
                          elevation: 2.0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: isSaving ? null : _saveChanges,
                        child: isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: white, strokeWidth: 2))
                            : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Rubik', fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for recalculating price
  Widget _priceSummary() {
    double subtotal = packagePrice * qty;
    double tax = subtotal * 0.06;
    double total = subtotal + tax;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tax (6%)', style: TextStyle(fontFamily: 'Rubik')),
            Text('RM ${tax.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Rubik')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Rubik')),
            Text('RM ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Rubik')),
          ],
        ),
      ],
    );
  }
}