class TimeSlotModel {
  final String slotId;
  final String startTime;
  String endTime;
  final String type;
  final String status;
  final List<String> cancel;
  final bool isAvailable;
  final bool isClosed;
  final bool isHoliday;
  final String username;
  String kontak;
  final String courtId;
  final String date;
  int totalHari;
  String jadwal;
  double price;
  double pricePerHour;

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
    this.kontak = '',
    this.courtId = '',
    this.date = '',
    this.totalHari = 0,
    this.jadwal = '',
    this.price = 0.0,
    this.pricePerHour = 0.0,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json, {int? index, String? courtId, String? date, double? price}) {
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
      kontak: json['kontak'] ?? '',
      courtId: courtId ?? '',
      date: date ?? '',
      totalHari: json['totalHari'] ?? 0,
      jadwal: json['jadwal'] ?? '',
      price: price ?? 0.0,
      pricePerHour: price ?? 0.0,
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
      'kontak': kontak,
      'courtId': courtId,
      'jadwal': jadwal,
      'date': date,
      'totalHari': totalHari,
      'price': price,
      'pricePerHour': pricePerHour,
    };
  }
}