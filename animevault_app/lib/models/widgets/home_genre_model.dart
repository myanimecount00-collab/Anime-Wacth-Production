class GenreAnime {
  final String title;
  final String thumb;
  final String link;
  final String ep;

  GenreAnime({
    required this.title,
    required this.thumb,
    required this.link,
    required this.ep,
  });

  factory GenreAnime.fromJson(Map<String,dynamic> json){
    return GenreAnime(
      title: json['title'] ?? '',
      thumb: json['thumb'] ?? '',
      link: json['link'] ?? '',
      ep: json['ep'] ?? '',
    );
  }
}