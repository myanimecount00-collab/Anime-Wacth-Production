class WatchHistory {
  final String title;
  final String thumb;
  final String link;
  final int currentEpisode;
  final int totalEpisodes;
  final DateTime? updatedAt;

  WatchHistory({
    required this.title,
    required this.thumb,
    required this.link,
    required this.currentEpisode,
    required this.totalEpisodes,
    this.updatedAt,
  });

  factory WatchHistory.fromJson(Map<String, dynamic> json) {
    return WatchHistory(
      title: json['title'] ?? '',
      thumb: json['thumb'] ?? '',
      link: json['link'] ?? '',
      currentEpisode: json['currentEpisode'] ?? 0,
      totalEpisodes: json['totalEpisodes'] ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'thumb': thumb,
      'link': link,
      'currentEpisode': currentEpisode,
      'totalEpisodes': totalEpisodes,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}