import 'dart:convert';
import 'package:http/http.dart' as http;


class OneSignalSendNotification {
  Future<void> sendBookingNotification(
    String username,
    String time,
    String date,
    String courtId,
  ) async {
    try {
      final appId = 'c8e16b1c-cee5-46f2-972e-4e4a190af032';
      final restApiKey = 'os_v2_app_zdqwwhgo4vdpffzojzfbscxqglydqlxrmxceza4zyzkzlom6wu6h5vxjrttfcuissukpjdlj6atlep6s7t2yqugaeba2bcky6dwscri';

      var url = Uri.parse('https://api.onesignal.com/notifications');
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $restApiKey',
      };

      var body = jsonEncode({
        "app_id": appId,
        "included_segments": 'JSA Admin Segment',
        "headings": {"en": "Bookingan Baru"},
        "contents": {
          "en":
              "$username telah melakukan booking lapangan $courtId pada $date jam $time",
        },
      });

      await http.post(url, headers: headers, body: body);
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
      final restApiKey = 'os_v2_app_zdqwwhgo4vdpffzojzfbscxqglydqlxrmxceza4zyzkzlom6wu6h5vxjrttfcuissukpjdlj6atlep6s7t2yqugaeba2bcky6dwscri';

      var url = Uri.parse('https://api.onesignal.com/notifications');
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $restApiKey',
      };

      var body = jsonEncode({
        "app_id": appId,
        "included_segments": 'JSA Admin Segment',
        "headings": {"en": "Member Baru"},
        "contents": {
          "en":
              "$username telah menjadi member di lapangan $courtId jam $time setiap hari $day",
        },
      });

    await http.post(url, headers: headers, body: body);
    } catch (e) {
        throw Exception('Faild to send notification: $e');
    }
  }
}
