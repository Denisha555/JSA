import 'package:flutter_application_1/services/firestore_service.dart';


class CacheService {
  static final _memoryCache = <String, List<AvailableForMember>>{};
  static final _timeRegex = RegExp(r'^(\d{2}):(\d{2})$');

  static List<AvailableForMember>? getCachedSlots(String dateStr) {
    return _memoryCache[dateStr];
  }

  static void updateCache(String dateStr, List<AvailableForMember> slots) {
    _memoryCache[dateStr] = slots;
  }

  static int timeToMinutes(String time) {
    final match = _timeRegex.firstMatch(time)!;
    return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }

  static void cleanCache({int days = 7}) {
    final threshold = DateTime.now().subtract(Duration(days: days));
    _memoryCache.removeWhere((key, _) => 
      DateTime.parse(key).isBefore(threshold));
  }
}