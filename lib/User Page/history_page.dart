import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../colors.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedStatus = 'All';
  bool _ascending = false;

  // Filter and sort
  List<QueryDocumentSnapshot> _processList(List<QueryDocumentSnapshot> docs) {
    // Keep only history statuses
    var items = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString();

      return status == 'Approved' ||
          status == 'Rejected' ||
          status == 'Cancelled';
    }).toList();

    // Filter by selected status
    if (_selectedStatus != 'All') {
      items = items.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['status'] ?? '').toString() == _selectedStatus;
      }).toList();
    }

    // Sort by date and time
    items.sort((a, b) {
      final d1 = _parseEventDate(a.data() as Map<String, dynamic>);
      final d2 = _parseEventDate(b.data() as Map<String, dynamic>);

      return _ascending ? d1.compareTo(d2) : d2.compareTo(d1);
    });

    return items;
  }

  DateTime _parseEventDate(Map<String, dynamic> data) {
    try {
      final String dateStr = data['date'] ?? '';
      final String timeStr = data['time'] ?? '';

      final dateParts = dateStr.split('-');
      if (dateParts.length != 3) return DateTime(1900);

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
      return DateTime(1900);
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
          'History',
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
                  children: ['All', 'Approved', 'Rejected', 'Cancelled']
                      .map((status) {
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

          // History list
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
                      'No history found.',
                      style: TextStyle(fontFamily: 'Rubik'),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return _HistoryCard(
                      data: list[index].data()
                      as Map<String, dynamic>,
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

// Helper widget for cards
class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HistoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Date', data['date'] ?? '-'),
          _row('Time', data['time'] ?? '-'),
          _row('People', data['pax'].toString()),

          const Divider(color: black),

          Center(
            child: Text(
              data['packageName'] ?? '',
              style: const TextStyle(
                fontFamily: 'Rubik',
                fontWeight: FontWeight.bold,
                color: black,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data['status'] ?? '',
                style: const TextStyle(
                  color: white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Rubik',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Rubik',
              fontWeight: FontWeight.bold,
              color: black,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Rubik',
              color: black,
            ),
          ),
        ],
      ),
    );
  }
}