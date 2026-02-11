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
      final newDetail = await FirebaseGetBooking().getBookingByDate(_selectedDate);
      setState(() {
        detail = newDetail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error appropriately
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
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
      appBar: AppBar(
        title: const Text('Pesanan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              readOnly: true, // biar ga bisa ketik manual
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
            // Display the booking data
            Expanded(
              child: _isLoading
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
                                title: Text(booking.date),
                                subtitle: Text('Time: ${booking.startTime} - ${booking.endTime}'),
                                trailing: Text('Status: ${booking.status}'),
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