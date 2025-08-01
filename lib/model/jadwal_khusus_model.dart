class JadwalKhususModel {
  final String date;
  final String type;
  final String startTime;
  final String endTime;
  final String description;

  JadwalKhususModel({
    this.date = '',
    this.type = '',
    this.startTime = '',
    this.endTime = '',
    this.description = '',
  });

  factory JadwalKhususModel.fromJson(Map<String, dynamic> json) {
    return JadwalKhususModel(
      date: json['date'].toString(),
      type: json['type'].toString(),
      startTime: json['startTime'].toString(),
      endTime: json['endTime'].toString(),
      description: json['description'].toString(),
    );
  }
}
