class EventPromoModel {
  final String image;

  const EventPromoModel({required this.image});

  factory EventPromoModel.fromJson(Map<String, dynamic> json) {
    return EventPromoModel(image: json['gambar']);
  }
}