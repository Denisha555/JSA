import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';
import 'package:flutter_application_1/services/booking/firebase_get_booking.dart';
import 'package:intl/intl.dart';

class HalamanPesanan extends StatefulWidget {
  const HalamanPesanan({super.key});

  @override
  State<HalamanPesanan> createState() => _HalamanPesananState();
}

class _HalamanPesananState extends State<HalamanPesanan> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _controller = TextEditingController();
  List<TimeSlotModel> detail = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    // Call getDetail after initState completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getDetail();
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });

      // Reload data for the new date
      await getDetail();
    }
  }

  Future<void> getDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<TimeSlotModel> newDetail = await FirebaseGetBooking()
          .getBookingByDate(_selectedDate);
      if (newDetail.isEmpty) {
        setState(() {
          detail = [];
          _isLoading = false;
        });
        return;
      } else {
        List<TimeSlotModel> mergedDetail = [];

        for (var booking in newDetail) {
          // kalau list kosong
          if (mergedDetail.isEmpty) {
            mergedDetail.add(booking);
            continue;
          }

          final lastBooking = mergedDetail.last;

          // username sama -> gabung
          if (booking.username == lastBooking.username &&
              booking.username.isNotEmpty) {
            lastBooking.endTime = booking.endTime;
          } else {
            mergedDetail.add(booking);
          }
        }
        setState(() {
          detail = mergedDetail;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error appropriately
      if (mounted) {
        print('Error fetching booking data: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              readOnly: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Display the booking data
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : detail.isEmpty
                      ? const Center(
                        child: Text(
                          'No bookings found for this date',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                      : ListView.builder(
                        itemCount: detail.length,
                        itemBuilder: (context, index) {
                          final booking = detail[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(booking.username),
                              subtitle: Text(
                                'Time: ${booking.startTime} - ${booking.endTime}',
                              ),
                              trailing:
                                  booking.type == 'nonMember'
                                      ? const Text('Non Member')
                                      : const Text('Member'),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
