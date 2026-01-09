class ReportModel {
  final String username;
  final String phoneNumber;
  final String? date;
  final String? startTime;
  final String? endTime;
  final int? totalDays;
  final int? totalHours;
  final String? courtId;
  final int? totalCourts;
  final int? price;
  final String? note;

  ReportModel({
    this.username = "",
    this.phoneNumber = "",
    this.date = "",
    this.startTime = "",
    this.endTime = "",
    this.totalDays = 0,
    this.totalHours = 0,
    this.courtId = "",
    this.totalCourts = 0,
    this.price = 0,
    this.note = ""
  });
}