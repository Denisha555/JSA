import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/onesignal/onesignal_get_rest_api.dart';
import 'package:flutter_application_1/services/user/firebase_get_user.dart';
import 'package:http/http.dart' as http;

class OneSignalSendNotificationAdmin {
  Future<void> sendBookingNotification(
    String username,
    String time,
    String date,
    String courtId,
  ) async {
    try {
      final appId = 'c8e16b1c-cee5-46f2-972e-4e4a190af032';
      final restApiKey = await OneSignalGetRestApi().getRestApi();

      var url = Uri.parse('https://api.onesignal.com/notifications');
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key $restApiKey',
      };

      var body = jsonEncode({
        "app_id": appId,
        "included_segments": ['JSA Admin Segment'],
        "headings": {"en": "Bookingan Baru"},
        "contents": {
          "en":
              "$username telah melakukan booking lapangan $courtId pada $date jam $time",
        },
      });

      final response = await http.post(url, headers: headers, body: body);
      print(response.statusCode);
      print(response.body);
    } catch (e) {
      throw Exception('Faild to send notification: $e');
    }
  }

  Future<void> sendNewMemberNotification(
    String username,
    String time,
    String day,
    String courtId,
  ) async {
    try {
      final appId = 'c8e16b1c-cee5-46f2-972e-4e4a190af032';
      final restApiKey = await OneSignalGetRestApi().getRestApi();

      var url = Uri.parse('https://api.onesignal.com/notifications');
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key $restApiKey',
      };

      var body = jsonEncode({
        "app_id": appId,
        "included_segments": ["JSA Admin Segment"],
        "headings": {"en": "Member Baru"},
        "contents": {
          "en":
              "$username telah menjadi member di lapangan $courtId jam $time setiap hari $day",
        },
      });

      final response = await http.post(url, headers: headers, body: body);
      print(response.statusCode);
      print(response.body);
    } catch (e) {
      throw Exception('Faild to send notification: $e');
    }
  }
}

class OnesignalSendNotificationCustomers {
  Future<void> sendNotification(
    String title,
    String content,
    String username,
  ) async {
    try {
      final appId = 'c8e16b1c-cee5-46f2-972e-4e4a190af032';
      final restApiKey = await OneSignalGetRestApi().getRestApi();

      var url = Uri.parse('https://api.onesignal.com/notifications');
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key $restApiKey',
      };

      String notificationId = await FirebaseGetUser().getUserData(
        username,
        "userId",
      );

      var body = jsonEncode({
        "app_id": appId,
        "include_external_user_ids": [notificationId],
        "headings": {"en": title},
        "contents": {"en": content},
      });

      final response = await http.post(url, headers: headers, body: body);
      print(response.statusCode);
      print(response.body);
    } catch (e) {
      throw Exception('Faild to send notification: $e');
    }
  }

  Future<void> sendNotificationToAll(String title, String content) async {
    try {
      final appId = 'c8e16b1c-cee5-46f2-972e-4e4a190af032';
      final restApiKey = await OneSignalGetRestApi().getRestApi();

      var url = Uri.parse('https://api.onesignal.com/notifications');
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key $restApiKey',
      };

      var body = jsonEncode({
        "app_id": appId,
        "included_segments": ["JSA All Segment"],
        "headings": {"en": title},
        "contents": {"en": content},
      });

      final response = await http.post(url, headers: headers, body: body);
      print(response.statusCode);
      print(response.body);
    } catch (e) {
      throw Exception('Faild to send notification: $e');
    }
  }
}
