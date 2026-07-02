class AnimeDetailModel {
  final String title;
  final String synopsis;
  final String thumb;
  final String score;
  final String status;
  final List<String> genres;
  final List<dynamic> episodes;

  AnimeDetailModel({
    required this.title,
    required this.synopsis,
    required this.thumb,
    required this.score,
    required this.status,
    required this.genres,
    required this.episodes,
  });

  factory AnimeDetailModel.fromJson(Map<String, dynamic> json) {
    return AnimeDetailModel(
      title: json['title'] ?? '',
      synopsis: json['synopsis'] ?? '',
      thumb: json['thumb'] ?? '',
      score: json['score'] ?? '',
      status: json['status'] ?? '',
      genres: List<String>.from(json['genres'] ?? []),
      episodes: List<dynamic>.from(json['episodes'] ?? []),
    );
  }
}