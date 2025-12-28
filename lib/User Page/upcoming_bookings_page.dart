import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../colors.dart';
import 'cancel_reservation_dialog.dart';
import 'edit_reservation_sheet.dart';

class UpcomingBookingsPage extends StatefulWidget {
  const UpcomingBookingsPage({super.key});

  @override
  State<UpcomingBookingsPage> createState() => _UpcomingBookingsPageState();
}

class _UpcomingBookingsPageState extends State<UpcomingBookingsPage> {
  String _selectedStatus = 'All';
  bool _ascending = true;

  // Cancel section
  Future<void> _cancelReservation(String docId, Map<String, dynamic> data) async {
    bool? confirm = await showCancelReservationDialog(
      context,
      date: data['date'] ?? '-',
      time: data['time'] ?? '-',
      pax: (data['pax'] ?? 0).toString(),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(docId)
          .update({'status': 'Cancelled'});
    }
  }

  // Edit section
  void _editReservation(String docId, Map<String, dynamic> currentData) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditReservationSheet(
        bookingData: currentData,
        reservationId: docId,
      ),
    );
  }

  // Filter and sort
  List<QueryDocumentSnapshot> _processList(List<QueryDocumentSnapshot> docs) {
    // Keep only upcoming statuses
    var list = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString();
      return status == 'Pending' || status == 'Approved';
    }).toList();

    // Filter by selected status
    if (_selectedStatus != 'All') {
      list = list.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['status'] ?? '').toString() == _selectedStatus;
      }).toList();
    }

    // Sort by date and time
    list.sort((a, b) {
      final d1 = _parseEventDate(a.data() as Map<String, dynamic>);
      final d2 = _parseEventDate(b.data() as Map<String, dynamic>);

      return _ascending ? d1.compareTo(d2) : d2.compareTo(d1);
    });

    return list;
  }

  DateTime _parseEventDate(Map<String, dynamic> data) {
    try {
      final String dateStr = data['date'] ?? ''; // dd-MM-yyyy
      final String timeStr = data['time'] ?? ''; // hh:mm AM/PM

      final dateParts = dateStr.split('-');
      if (dateParts.length != 3) return DateTime(2100);

      final int day = int.parse(dateParts[0]);
      final int month = int.parse(dateParts[1]);
      final int year = int.parse(dateParts[2]);

      int hour = 0;
      int minute = 0;

      if (timeStr.isNotEmpty) {
        final parts = timeStr.split(' ');
        final hm = parts[0].split(':');

        hour = int.parse(hm[0]);
        minute = int.parse(hm[1]);

        if (parts.length > 1 && parts[1] == 'PM' && hour != 12) {
          hour += 12;
        }
        if (parts.length > 1 && parts[1] == 'AM' && hour == 12) {
          hour = 0;
        }
      }

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return DateTime(2100);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: black,
        elevation: 4.0,
        shadowColor: black,
        leading: const BackButton(color: white),
        title: const Text(
          'Upcoming Bookings',
          style: TextStyle(
            color: white,
            fontFamily: 'Rubik',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  'Filter by status',
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.bold,
                    color: black,
                  ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  children: ['All', 'Pending', 'Approved'].map((status) {
                    final selected = _selectedStatus == status;

                    return ChoiceChip(
                      label: Text(status),
                      selected: selected,
                      selectedColor: black,
                      backgroundColor: white,
                      side: const BorderSide(color: black, width: 1.2),
                      checkmarkColor: white,
                      labelStyle: TextStyle(
                        color: selected ? white : black,
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedStatus = status);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Order row
                Row(
                  children: [
                    const Text(
                      'Order by date:',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.bold,
                        color: black,
                      ),
                    ),
                    const SizedBox(width: 12),

                    GestureDetector(
                      onTap: () {
                        setState(() => _ascending = !_ascending);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: black, width: 1.5),
                        ),
                        child: Icon(
                          _ascending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: black,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Text(
                      _ascending ? 'Ascending' : 'Descending',
                      style: const TextStyle(
                        fontFamily: 'Rubik',
                        color: black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Upcoming bookings list
          Expanded(
            child: user == null
                ? const Center(child: Text("Please log in."))
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reservations')
                  .where('guestId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: black),
                  );
                }

                final list =
                _processList(snapshot.data?.docs ?? []);

                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      "No upcoming bookings.",
                      style: TextStyle(fontFamily: 'Rubik'),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final doc = list[index];
                    final data =
                    doc.data() as Map<String, dynamic>;

                    return _BookingCard(
                      data: data,
                      onCancel: () =>
                          _cancelReservation(doc.id, data),
                      onEdit: () =>
                          _editReservation(doc.id, data),
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


// Helper for widget cards
class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onCancel;
  final VoidCallback onEdit;

  const _BookingCard({
    required this.data,
    required this.onCancel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Pending';
    final canEdit = status == 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black54),
      ),
      child: Column(
        children: [

          _row('Date', data['date'] ?? '-', 'Time', data['time'] ?? '-'),
          const SizedBox(height: 8),
          _singleRow('Number of pax', data['pax'].toString()),

          const Divider(color: black, thickness: 1),

          const Text(
            "Menu Packages",
            style: TextStyle(
              fontFamily: 'Rubik',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: black,
            ),
          ),

          const SizedBox(height: 6),
          Text(
            "${data['packageName']}: ${data['pax']}",
            style: const TextStyle(
              fontFamily: 'Rubik',
              color: black,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [

              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: white,
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Spacer(),

              if (canEdit)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: black, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: black,
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: black,
                  foregroundColor: white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onPressed: onCancel,
                child: const Text(
                  'Cancel Booking',
                  style: TextStyle(
                    color: white,
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String l1, String v1, String l2, String v2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$l1: $v1',
          style: const TextStyle(
            fontFamily: 'Rubik',
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$l2: $v2',
          style: const TextStyle(
            fontFamily: 'Rubik',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _singleRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Rubik',
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontFamily: 'Rubik'),
        ),
      ],
    );
  }
}