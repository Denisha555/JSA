import 'package:flutter/material.dart';
import 'price.dart';
import 'kalender.dart';
import 'promo_event.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:intl/intl.dart';

class HalamanUtamaAdmin extends StatefulWidget {
  const HalamanUtamaAdmin({super.key});

  @override
  State<HalamanUtamaAdmin> createState() => _HalamanUtamaAdminState();
}

class _HalamanUtamaAdminState extends State<HalamanUtamaAdmin> {
  DateTime selectedDate = DateTime.now();

  // Updated booking data to include customer name
  Map<String, Map<String, Map<String, String>>> bookingData = {
    '01:00 - 01:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'John Doe'},
      'Lapangan 2': {'status': 'booked', 'username': 'Jane Smith'},
      'Lapangan 3': {'status': 'booked', 'username': 'Mike Johnson'},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Sarah Williams'},
      'Lapangan 6': {'status': 'booked', 'username': 'David Brown'},
    },
    '01:30 - 02:00': {
      'Lapangan 1': {'status': 'booked', 'username': 'Alex Davis'},
      'Lapangan 2': {'status': 'booked', 'username': 'Emma Wilson'},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'booked', 'username': 'Ryan Taylor'},
      'Lapangan 5': {'status': 'booked', 'username': 'Olivia Jones'},
      'Lapangan 6': {'status': 'booked', 'username': 'Daniel White'},
    },
    '02:00 - 02:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Lisa Martinez'},
      'Lapangan 2': {'status': 'booked', 'username': 'Kevin Garcia'},
      'Lapangan 3': {'status': 'booked', 'username': 'Sophia Rodriguez'},
      'Lapangan 4': {'status': 'booked', 'username': 'James Lee'},
      'Lapangan 5': {'status': 'booked', 'username': 'Emily Clark'},
      'Lapangan 6': {'status': 'booked', 'username': 'Michael Lewis'},
    },
    '02:30 - 03:00': {
      'Lapangan 1': {'status': 'booked', 'username': 'Jessica Walker'},
      'Lapangan 2': {'status': 'available', 'username': ''},
      'Lapangan 3': {'status': 'booked', 'username': 'Andrew Hall'},
      'Lapangan 4': {'status': 'booked', 'username': 'Chloe Young'},
      'Lapangan 5': {'status': 'booked', 'username': 'Thomas Allen'},
      'Lapangan 6': {'status': 'booked', 'username': 'Abigail King'},
    },
    '03:00 - 03:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Robert Wright'},
      'Lapangan 2': {'status': 'booked', 'username': 'Natalie Scott'},
      'Lapangan 3': {'status': 'booked', 'username': 'Christopher Green'},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Hannah Baker'},
      'Lapangan 6': {'status': 'booked', 'username': 'Joseph Hill'},
    },
    '03:30 - 04:00': {
      'Lapangan 1': {'status': 'available', 'username': ''},
      'Lapangan 2': {'status': 'booked', 'username': 'Michelle Adams'},
      'Lapangan 3': {'status': 'booked', 'username': 'Jonathan Campbell'},
      'Lapangan 4': {'status': 'booked', 'username': 'Grace Mitchell'},
      'Lapangan 5': {'status': 'available', 'username': ''},
      'Lapangan 6': {'status': 'booked', 'username': 'Brandon Carter'},
    },
    '04:00 - 04:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Rachel Roberts'},
      'Lapangan 2': {'status': 'booked', 'username': 'Justin Parker'},
      'Lapangan 3': {'status': 'booked', 'username': 'Lauren Evans'},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Nicholas Torres'},
      'Lapangan 6': {'status': 'booked', 'username': 'Samantha Diaz'},
    },
    '04:30 - 05:00': {
      'Lapangan 1': {'status': 'booked', 'username': 'Eric Collins'},
      'Lapangan 2': {'status': 'booked', 'username': 'Victoria Reed'},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'booked', 'username': 'Tyler Murphy'},
      'Lapangan 5': {'status': 'available', 'username': ''},
      'Lapangan 6': {'status': 'booked', 'username': 'Elizabeth Cook'},
    },
    '05:00 - 05:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Brian Richardson'},
      'Lapangan 2': {'status': 'booked', 'username': 'Amanda Cox'},
      'Lapangan 3': {'status': 'booked', 'username': 'Kyle Howard'},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Melissa Ward'},
      'Lapangan 6': {'status': 'available', 'username': ''},
    },
    '05:30 - 06:00': {
      'Lapangan 1': {'status': 'booked', 'username': 'Jacob Morgan'},
      'Lapangan 2': {'status': 'available', 'username': ''},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'booked', 'username': 'Megan Phillips'},
      'Lapangan 5': {'status': 'booked', 'username': 'Jordan Bell'},
      'Lapangan 6': {'status': 'available', 'username': ''},
    },

    // Add more time slots with appropriate data
    '06:00 - 06:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Dylan Foster'},
      'Lapangan 2': {'status': 'booked', 'username': 'Stephanie Butler'},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'booked', 'username': 'Austin Simmons'},
      'Lapangan 5': {'status': 'available', 'username': ''},
      'Lapangan 6': {'status': 'booked', 'username': 'Nicole Price'},
    },
    '06:30 - 07:00': {
      'Lapangan 1': {'status': 'booked', 'username': 'Timothy Barnes'},
      'Lapangan 2': {'status': 'available', 'username': ''},
      'Lapangan 3': {'status': 'booked', 'username': 'Rebecca Ross'},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'available', 'username': ''},
      'Lapangan 6': {'status': 'booked', 'username': 'Stephen Henderson'},
    },
    '07:00 - 07:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Laura Coleman'},
      'Lapangan 2': {'status': 'booked', 'username': 'Lucas Jenkins'},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'booked', 'username': 'Danielle Perry'},
      'Lapangan 5': {'status': 'available', 'username': ''},
      'Lapangan 6': {'status': 'available', 'username': ''},
    },
    '07:30 - 08:00': {
      'Lapangan 1': {'status': 'available', 'username': ''},
      'Lapangan 2': {'status': 'booked', 'username': 'Patrick Powell'},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'booked', 'username': 'Amber Long'},
      'Lapangan 5': {'status': 'available', 'username': ''},
      'Lapangan 6': {'status': 'available', 'username': ''},
    },
    '08:00 - 08:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Nathan Hughes'},
      'Lapangan 2': {'status': 'booked', 'username': 'Sara Peterson'},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Adrian Bennett'},
      'Lapangan 6': {'status': 'available', 'username': ''},
    },
    '08:30 - 09:00': {
      'Lapangan 1': {'status': 'available', 'username': ''},
      'Lapangan 2': {'status': 'booked', 'username': 'Sofia Patterson'},
      'Lapangan 3': {'status': 'booked', 'username': 'William Kelly'},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'available', 'username': ''},
      'Lapangan 6': {'status': 'booked', 'username': 'Chloe Cox'},
    },
    '09:00 - 09:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'James Rivera'},
      'Lapangan 2': {'status': 'available', 'username': ''},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'booked', 'username': 'Abigail Torres'},
      'Lapangan 5': {'status': 'booked', 'username': 'Matthew Jenkins'},
      'Lapangan 6': {'status': 'booked', 'username': 'Lily Hayes'},
    },
    '09:30 - 10:00': {
      'Lapangan 1': {'status': 'available', 'username': ''},
      'Lapangan 2': {'status': 'booked', 'username': 'Sebastian Bryant'},
      'Lapangan 3': {'status': 'booked', 'username': 'Grace Cooper'},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Aiden Richardson'},
      'Lapangan 6': {'status': 'available', 'username': ''},
    },
    '10:00 - 10:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Zoe Stone'},
      'Lapangan 2': {'status': 'available', 'username': ''},
      'Lapangan 3': {'status': 'booked', 'username': 'Owen Barnes'},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Nora Freeman'},
      'Lapangan 6': {'status': 'booked', 'username': 'Levi Chapman'},
    },
    '10:30 - 11:00': {
      'Lapangan 1': {'status': 'available', 'username': ''},
      'Lapangan 2': {'status': 'booked', 'username': 'Avery Harvey'},
      'Lapangan 3': {'status': 'booked', 'username': 'Luna Hart'},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Nathan Ray'},
      'Lapangan 6': {'status': 'booked', 'username': 'Zara Griffith'},
    },
    '11:00 - 11:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Caroline Austin'},
      'Lapangan 2': {'status': 'available', 'username': ''},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'booked', 'username': 'Elijah West'},
      'Lapangan 5': {'status': 'booked', 'username': 'Scarlett Ford'},
      'Lapangan 6': {'status': 'available', 'username': ''},
    },
    '11:30 - 12:00': {
      'Lapangan 1': {'status': 'available', 'username': ''},
      'Lapangan 2': {'status': 'booked', 'username': 'Gabriel Wallace'},
      'Lapangan 3': {'status': 'booked', 'username': 'Aria Cole'},
      'Lapangan 4': {'status': 'booked', 'username': 'Hudson Powell'},
      'Lapangan 5': {'status': 'available', 'username': ''},
      'Lapangan 6': {'status': 'booked', 'username': 'Violet Perry'},
    },
    '12:00 - 12:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Wyatt Simmons'},
      'Lapangan 2': {'status': 'booked', 'username': 'Eleanor Barker'},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'booked', 'username': 'Aaron Gibson'},
      'Lapangan 5': {'status': 'booked', 'username': 'Penelope Lane'},
      'Lapangan 6': {'status': 'available', 'username': ''},
    },
    '12:30 - 13:00': {
      'Lapangan 1': {'status': 'available', 'username': ''},
      'Lapangan 2': {'status': 'booked', 'username': 'Stella Hudson'},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'booked', 'username': 'Dylan Franklin'},
      'Lapangan 5': {'status': 'booked', 'username': 'Hazel Dean'},
      'Lapangan 6': {'status': 'booked', 'username': 'Lincoln Hale'},
    },
    '13:00 - 13:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Savannah Lloyd'},
      'Lapangan 2': {'status': 'available', 'username': ''},
      'Lapangan 3': {'status': 'booked', 'username': 'Julian Maxwell'},
      'Lapangan 4': {'status': 'booked', 'username': 'Lillian Stevens'},
      'Lapangan 5': {'status': 'available', 'username': ''},
      'Lapangan 6': {'status': 'booked', 'username': 'Anthony Cross'},
    },
    '13:30 - 14:00': {
      'Lapangan 1': {'status': 'booked', 'username': 'Aurora Gibbs'},
      'Lapangan 2': {'status': 'booked', 'username': 'Grayson Parsons'},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Ivy Burke'},
      'Lapangan 6': {'status': 'booked', 'username': 'Jaxon Hammond'},
    },
    '14:00 - 14:30': {
      'Lapangan 1': {'status': 'available', 'username': ''},
      'Lapangan 2': {'status': 'booked', 'username': 'Paisley Banks'},
      'Lapangan 3': {'status': 'booked', 'username': 'Ezra Dawson'},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Naomi Curtis'},
      'Lapangan 6': {'status': 'available', 'username': ''},
    },
    '14:30 - 15:00': {
      'Lapangan 1': {'status': 'booked', 'username': 'Alice Fleming'},
      'Lapangan 2': {'status': 'booked', 'username': 'Cooper Malone'},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Madeline Wolfe'},
      'Lapangan 6': {'status': 'booked', 'username': 'Maxwell Craig'},
    },
    '15:00 - 15:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Ellie Doyle'},
      'Lapangan 2': {'status': 'available', 'username': ''},
      'Lapangan 3': {'status': 'booked', 'username': 'Brody Holt'},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Clara Kemp'},
      'Lapangan 6': {'status': 'booked', 'username': 'George Swanson'},
    },
    '15:30 - 16:00': {
      'Lapangan 1': {'status': 'available', 'username': ''},
      'Lapangan 2': {'status': 'booked', 'username': 'Piper Massey'},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'booked', 'username': 'Finn Thornton'},
      'Lapangan 5': {'status': 'booked', 'username': 'Mila Sherman'},
      'Lapangan 6': {'status': 'booked', 'username': 'Eli Benson'},
    },
    '16:00 - 16:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Aaliyah Barron'},
      'Lapangan 2': {'status': 'booked', 'username': 'Asher Sharp'},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Isla Pratt'},
      'Lapangan 6': {'status': 'available', 'username': ''},
    },
    '16:30 - 17:00': {
      'Lapangan 1': {'status': 'available', 'username': ''},
      'Lapangan 2': {'status': 'booked', 'username': 'Caleb Wolfe'},
      'Lapangan 3': {'status': 'booked', 'username': 'Lucy Brady'},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Easton Marsh'},
      'Lapangan 6': {'status': 'booked', 'username': 'Bella Cummings'},
    },
    '17:00 - 17:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Lydia Ramsey'},
      'Lapangan 2': {'status': 'available', 'username': ''},
      'Lapangan 3': {'status': 'booked', 'username': 'Nolan Zimmerman'},
      'Lapangan 4': {'status': 'booked', 'username': 'Riley Wilkins'},
      'Lapangan 5': {'status': 'available', 'username': ''},
      'Lapangan 6': {'status': 'booked', 'username': 'Willow Page'},
    },
    '17:30 - 18:00': {
      'Lapangan 1': {'status': 'booked', 'username': 'Andrew Boyd'},
      'Lapangan 2': {'status': 'booked', 'username': 'Faith Warner'},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'booked', 'username': 'Ian Chandler'},
      'Lapangan 5': {'status': 'booked', 'username': 'Delilah Osborne'},
      'Lapangan 6': {'status': 'available', 'username': ''},
    },
    '18:00 - 18:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Arianna Keller'},
      'Lapangan 2': {'status': 'available', 'username': ''},
      'Lapangan 3': {'status': 'booked', 'username': 'Xavier Lyons'},
      'Lapangan 4': {'status': 'booked', 'username': 'Annabelle Greer'},
      'Lapangan 5': {'status': 'available', 'username': ''},
      'Lapangan 6': {'status': 'booked', 'username': 'Beau Salazar'},
    },
    '18:30 - 19:00': {
      'Lapangan 1': {'status': 'booked', 'username': 'Jayden Ball'},
      'Lapangan 2': {'status': 'booked', 'username': 'Summer Rowe'},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'booked', 'username': 'Valentina McBride'},
      'Lapangan 5': {'status': 'booked', 'username': 'Axel Bowen'},
      'Lapangan 6': {'status': 'available', 'username': ''},
    },
    '19:00 - 19:30': {
      'Lapangan 1': {'status': 'available', 'username': ''},
      'Lapangan 2': {'status': 'booked', 'username': 'Harmony Dorsey'},
      'Lapangan 3': {'status': 'booked', 'username': 'Theo Humphrey'},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Alina Hodge'},
      'Lapangan 6': {'status': 'booked', 'username': 'Caden Salinas'},
    },
    '19:30 - 20:00': {
      'Lapangan 1': {'status': 'booked', 'username': 'Juliette Bentley'},
      'Lapangan 2': {'status': 'booked', 'username': 'Remy Finley'},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'booked', 'username': 'Emmanuel Mercer'},
      'Lapangan 5': {'status': 'booked', 'username': 'Daphne Knox'},
      'Lapangan 6': {'status': 'available', 'username': ''},
    },
    '20:00 - 20:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Kayla Vance'},
      'Lapangan 2': {'status': 'available', 'username': ''},
      'Lapangan 3': {'status': 'booked', 'username': 'Tristan Keith'},
      'Lapangan 4': {'status': 'booked', 'username': 'Rebecca Pugh'},
      'Lapangan 5': {'status': 'available', 'username': ''},
      'Lapangan 6': {'status': 'booked', 'username': 'Phoenix Shepherd'},
    },
    '20:30 - 21:00': {
      'Lapangan 1': {'status': 'booked', 'username': 'Maddox McCoy'},
      'Lapangan 2': {'status': 'booked', 'username': 'Daniela Salas'},
      'Lapangan 3': {'status': 'booked', 'username': 'Kendall Carson'},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Giselle Pitts'},
      'Lapangan 6': {'status': 'available', 'username': ''},
    },
    '21:30 - 22:00': {
      'Lapangan 1': {'status': 'booked', 'username': 'Gabriel Watson'},
      'Lapangan 2': {'status': 'available', 'username': ''},
      'Lapangan 3': {'status': 'booked', 'username': 'Vanessa Cooper'},
      'Lapangan 4': {'status': 'available', 'username': ''},
      'Lapangan 5': {'status': 'booked', 'username': 'Ian Gray'},
      'Lapangan 6': {'status': 'available', 'username': ''},
    },
    '22:00 - 22:30': {
      'Lapangan 1': {'status': 'booked', 'username': 'Monica Kelly'},
      'Lapangan 2': {'status': 'booked', 'username': 'Oscar Sanders'},
      'Lapangan 3': {'status': 'available', 'username': ''},
      'Lapangan 4': {'status': 'booked', 'username': 'Valerie Price'},
      'Lapangan 5': {'status': 'booked', 'username': 'Wesley Brooks'},
      'Lapangan 6': {'status': 'available', 'username': ''},
    },
  };

   String _formatDate(DateTime date) {
    List<String> months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    List<String> days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _toggleBookingStatus(String time, String court) {
    setState(() {
      if (bookingData[time]![court]!['status'] == 'booked') {
        bookingData[time]![court]!['status'] = 'available';
        bookingData[time]![court]!['username'] = '';
      } else {
        _showAddBookingDialog(time, court);
      }
    });
  }

  // Show dialog to add a new booking
  void _showAddBookingDialog(String time, String court) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add New Booking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Time: $time'),
                Text('Court: $court'),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Customer Name'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter customer name')),
                    );
                    return;
                  }

                  setState(() {
                    bookingData[time]![court]!['status'] = 'booked';
                    bookingData[time]![court]!['username'] =
                        nameController.text;
                  });

                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  // Show booking details
  void _showBookingDetails(String time, String court, String username) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Booking Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Time: $time'),
                Text('Court: $court'),
                Text('Customer: $username'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _editBooking(time, court, username);
                },
                child: Text('Edit'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    bookingData[time]![court]!['status'] = 'available';
                    bookingData[time]![court]!['username'] = '';
                  });
                  Navigator.pop(context);
                },
                child: Text('Cancel Booking'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );
  }

  // Edit booking
  void _editBooking(String time, String court, String currentUsername) {
    final TextEditingController nameController = TextEditingController(
      text: currentUsername,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Booking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Time: $time'),
                Text('Court: $court'),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Customer Name'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter customer name')),
                    );
                    return;
                  }

                  setState(() {
                    bookingData[time]![court]!['username'] =
                        nameController.text;
                  });

                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  Widget _buildCalendar(DateTime time) {
    return Expanded(
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Header row
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildHeaderCell('Jam', width: 100),
                      _buildHeaderCell('Lapangan 1'),
                      _buildHeaderCell('Lapangan 2'),
                      _buildHeaderCell('Lapangan 3'),
                      _buildHeaderCell('Lapangan 4'),
                      _buildHeaderCell('Lapangan 5'),
                      _buildHeaderCell('Lapangan 6'),
                    ],
                  ),
                ),

                // Data rows
                ...bookingData.entries.map((entry) {
                  final time = entry.key;
                  final courts = entry.value;

                  return Row(
                    children: [
                      _buildTimeCell(time),
                      _buildCourtCell(
                        time,
                        'Lapangan 1',
                        courts['Lapangan 1']!['status'] == 'booked',
                        courts['Lapangan 1']!['username']!,
                      ),
                      _buildCourtCell(
                        time,
                        'Lapangan 2',
                        courts['Lapangan 2']!['status'] == 'booked',
                        courts['Lapangan 2']!['username']!,
                      ),
                      _buildCourtCell(
                        time,
                        'Lapangan 3',
                        courts['Lapangan 3']!['status'] == 'booked',
                        courts['Lapangan 3']!['username']!,
                      ),
                      _buildCourtCell(
                        time,
                        'Lapangan 4',
                        courts['Lapangan 4']!['status'] == 'booked',
                        courts['Lapangan 4']!['username']!,
                      ),
                      _buildCourtCell(
                        time,
                        'Lapangan 5',
                        courts['Lapangan 5']!['status'] == 'booked',
                        courts['Lapangan 5']!['username']!,
                      ),
                      _buildCourtCell(
                        time,
                        'Lapangan 6',
                        courts['Lapangan 6']!['status'] == 'booked',
                        courts['Lapangan 6']!['username']!,
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget for header cell
  Widget _buildHeaderCell(String text, {double width = 120}) {
    return Container(
      width: width,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primaryColor,
        border: Border.all(color: Colors.white, width: 0.5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Widget for time cell
  Widget _buildTimeCell(String time) {
    return Container(
      width: 100,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(time, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  // Widget for court cell
  Widget _buildCourtCell(
    String time,
    String court,
    bool isBooked,
    String username,
  ) {
    return InkWell(
      onTap: () {
        if (isBooked) {
          _showBookingDetails(time, court, username);
        } else {
          _showAddBookingDialog(time, court);
        }
      },
      child: Container(
        width: 120,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isBooked ? bookedColor : availableColor,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isBooked ? 'Booked' : 'Available',
              style: TextStyle(
                color: isBooked ? Colors.red.shade700 : Colors.green.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            if (isBooked)
              Text(
                username,
                style: TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  // Quick access menu buttons
  Widget _buildQuickAccessMenu(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickAccessButton(
              icon: 'price',
              label: "Price",
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HalamanPrice()),
                  ),
            ),
            _buildQuickAccessButton(
              icon: 'calender',
              label: "Kalender",
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HalamanKalender()),
                  ),
            ),
            _buildQuickAccessButton(
              icon: 'promo_event',
              label: "Promo & Event",
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HalamanPromoEvent(),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Individual quick access button
  Widget _buildQuickAccessButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final iconMap = {
      'price': Icons.attach_money_outlined,
      'calender': Icons.calendar_month_outlined,
      'promo_event': Icons.discount_outlined,
    };

    final IconData iconData = iconMap[icon] ?? Icons.help_outline;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 32, color: Colors.black),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildQuickAccessMenu(context),
          const SizedBox(height: 15),
          Text(_formatDate(selectedDate), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: availableColor,
                  margin: const EdgeInsets.only(right: 4),
                ),
                const Text('Tersedia'),
                const SizedBox(width: 16),
                Container(
                  width: 16,
                  height: 16,
                  color: bookedColor,
                  margin: const EdgeInsets.only(right: 4),
                ),
                const Text('Sudah Dibooking'),
              ],
            ),
          ),
          _buildCalendar(selectedDate),
        ],
      ),
    );
  }
}
