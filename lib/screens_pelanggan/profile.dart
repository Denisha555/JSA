import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HalamanProfil extends StatefulWidget {
  const HalamanProfil({super.key});

  @override
  State<HalamanProfil> createState() => _HalamanProfilState();
}

class _HalamanProfilState extends State<HalamanProfil> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profil"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            InkWell(
              onTap: () async {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainApp()));
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.remove("username");
              }, 
              child: Row(
                children: [
                  Icon(Icons.logout),
                  Text("Logout")
                ],
              ),
            )
            ],
        ),
      ),
    );
  }
}