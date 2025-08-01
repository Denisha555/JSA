class CourtModel {
  final String courtId;
  final String? description;
  final String? imageUrl;

  CourtModel({
    this.courtId = '',
    this.description = '',
    this.imageUrl = '',
  });

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    return CourtModel(
      courtId: json['nomor'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}