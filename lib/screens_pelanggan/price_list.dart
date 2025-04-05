import 'package:flutter/material.dart';

// Halaman Price List
class HalamanPriceList extends StatefulWidget {
  const HalamanPriceList({super.key});

  @override
  State<HalamanPriceList> createState() => _HalamanPriceListState();
}

class _HalamanPriceListState extends State<HalamanPriceList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Price List")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 10),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: const Color.fromRGBO(182, 209, 238, 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MEMBER",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  // Senin - Jumat
                  Text(
                    "Senin - Jumat",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          "07.00 - 14.00",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Text("30k/Jam"),
                      ),
                    ],
                  ),
                  Divider(color: Colors.black, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          "14.00 - 23.00",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Text("45k/Jam"),
                      ),
                    ],
                  ),
                  Divider(color: Colors.black, thickness: 1),
                  Text(
                    "Sabtu - Minggu",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          "07.00 - 23.00",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Text("45k/Jam"),
                      ),
                    ],
                  ),
                  Divider(color: Colors.black, thickness: 1),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 20, left: 20, right: 20),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: const Color.fromRGBO(182, 209, 238, 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MEMBER",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  // Senin - Jumat
                  Text(
                    "Senin - Jumat",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          "07.00 - 14.00",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Text("35k/Jam"),
                      ),
                    ],
                  ),
                  Divider(color: Colors.black, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          "14.00 - 23.00",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Text("50k/Jam"),
                      ),
                    ],
                  ),
                  Divider(color: Colors.black, thickness: 1),
                  Text(
                    "Sabtu - Minggu",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: Text(
                          "07.00 - 23.00",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Text("50k/Jam"),
                      ),
                    ],
                  ),
                  Divider(color: Colors.black, thickness: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
