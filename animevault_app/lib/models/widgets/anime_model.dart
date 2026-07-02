class AnimeModel {
  final String title;
  final String thumb;
  final String link;
  final String ep;

  AnimeModel({
    required this.title,
    required this.thumb,
    required this.link,
    required this.ep,
  });

  factory AnimeModel.fromJson(Map<String, dynamic> json) {
    return AnimeModel(
      title: json['title'] ?? '',
      thumb: json['thumb'] ?? '',
      link: json['link'] ?? '',
      ep: json['ep'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'thumb': thumb,
      'link': link,
      'ep': ep,
    };
  }
}