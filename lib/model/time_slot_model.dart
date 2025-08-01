class TimeSlotModel {
  final String slotId;
  final String startTime;
  final String endTime;
  final String type;
  final String status;
  final List<String> cancel;
  final bool isAvailable;
  final bool isClosed;
  final bool isHoliday;
  final String username;
  final String courtId;
  final String date;

  TimeSlotModel({
    this.slotId = '',
    this.startTime = '',
    this.endTime = '',
    this.type = '',
    this.status = '',
    this.cancel = const [],
    this.isAvailable = true,
    this.isClosed = false,
    this.isHoliday = false,
    this.username = '',
    this.courtId = '',
    this.date = '',
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json, {int? index, String? courtId, String? date}) {
    return TimeSlotModel(
      slotId: json['slotId'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      cancel: List<String>.from(json['cancel'] ?? []),
      isAvailable: json['isAvailable'] ?? true,
      isClosed: json['isClosed'] ?? false,
      isHoliday: json['isHoliday'] ?? false,
      username: json['username'] ?? '',
      courtId: courtId ?? '',
      date: date ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slotId': slotId,
      'startTime': startTime,
      'endTime': endTime,
      'type': type,
      'status': status,
      'cancel': cancel,
      'isAvailable': isAvailable,
      'isClosed': isClosed,
      'isHoliday': isHoliday,
      'username': username,
      'courtId': courtId,
      'date': date,
    };
  }
}