class UserModel {
  final String username;
  final String name;
  final String password;
  final String role;
  final String startTimePoint;
  final String startTimeMember;
  final double point;
  final double totalHour;
  final int totalBooking;
  final int memberTotalBooking;
  final int memberCurrentTotalBooking;
  final int memberBookingLength;
  final int cancel;
  final List<String> cancelDate;
  final List<String> bookingDates;
  final String noTelp;
  final String club;

  UserModel({
    this.username  = '',
    this.name = '',
    this.password = '',
    this.role = '',
    this.startTimePoint = '',
    this.startTimeMember = '',
    this.point = 0,
    this.totalHour = 0,
    this.totalBooking = 0,
    this.memberTotalBooking = 0,
    this.memberCurrentTotalBooking = 0,
    this.memberBookingLength = 0,
    this.cancel = 0,
    this.cancelDate = const [],
    this.bookingDates = const [],
    this.noTelp = '',
    this.club = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? '',
      startTimePoint: json['startTimePoint'] ?? '',
      startTimeMember: json['startTimeMember'] ?? '',
      point: (json['point'] ?? 0).toDouble(),
      totalHour: (json['totalHour'] ?? 0).toDouble(),
      totalBooking: (json['totalBooking'] ?? 0).toInt(),
      memberTotalBooking: (json['memberTotalBooking'] ?? 0).toInt(),
      memberCurrentTotalBooking: (json['memberCurrentTotalBooking'] ?? 0).toInt(),
      memberBookingLength: (json['memberBookingLenght'] ?? 0).toInt(),
      cancel: (json['cancel'] ?? 0).toInt(),
      cancelDate: List<String>.from(json['cancelDate'] ?? []),
      bookingDates: List<String>.from(json['bookingDates'] ?? []),
      noTelp: json['phoneNumber'] ?? '',
      club: json['club'] ?? '',
    );
  }
}