class PriceModel {
  final int harga;
  final String hariMulai;
  final String hariSelesai;
  final int jamMulai;
  final int jamSelesai;
  final String type;

  PriceModel({
    required this.harga,
    required this.hariMulai,
    required this.hariSelesai,
    required this.jamMulai,
    required this.jamSelesai,
    required this.type,
  });

  factory PriceModel.fromJson(Map<String, dynamic> json) {
    return PriceModel(
      harga: json['harga'],
      hariMulai: json['hari_mulai'],
      hariSelesai: json['hari_selesai'],
      jamMulai: json['jam_mulai'],
      jamSelesai: json['jam_selesai'],
      type: json['type'],
    );
  }
}