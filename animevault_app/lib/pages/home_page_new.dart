import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/widgets/anime_model.dart';
import 'anime_detail_page.dart';
import 'package:provider/provider.dart';
import '../provider/history_provider.dart';
import '../models/widgets/watch_history.dart';

// ─────────────────────────────────────────────
// THEME & COLORS
// ─────────────────────────────────────────────
class AVColors {
  static const background = Color(0xFF0D0D0F);
  static const surface    = Color(0xFF141417);
  static const surface2   = Color(0xFF1A1A1F);
  static const border     = Color(0xFF2A2A2E);
  static const primary    = Color(0xFF6C63FF);
  static const secondary  = Color(0xFFA855F7);
  static const amber      = Color(0xFFF59E0B);
  static const textPrimary   = Color(0xFFF0F0F0);
  static const textSecondary = Color(0xFF888888);
  static const textMuted     = Color(0xFF555555);
  static const gold          = Color(0xFFFFD700);
}

// ─────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────
class Anime {
  final String title;
  final String genre1;
  final String genre2;
  final String platform;
  final double rating;
  final int episodes;
  final Color tint;

  const Anime({
    required this.title,
    required this.genre1,
    required this.genre2,
    required this.platform,
    required this.rating,
    required this.episodes,
    required this.tint,
  });
}

class Episode {
  final String title;
  final int episodeNumber;
  final int durationMin;
  final bool isNew;
  final double progress;
  final Color tint;

  const Episode({
    required this.title,
    required this.episodeNumber,
    required this.durationMin,
    required this.isNew,
    required this.progress,
    required this.tint,
  });
}

class GenreAnime {
  final String title;
  final String link;
  final String thumb;
  final String ep;

  GenreAnime({
    required this.title,
    required this.link,
    required this.thumb,
    required this.ep,
  });

  factory GenreAnime.fromJson(Map<String, dynamic> json) {
    return GenreAnime(
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      thumb: json['thumb'] ?? '',
      ep: json['ep'] ?? '',
    );
  }
}

// ─────────────────────────────────────────────
// DUMMY DATA
// ─────────────────────────────────────────────
class DummyData {
  static const List<Anime> featured = [
    Anime(
      title: 'Demon Slayer: Kimetsu no Yaiba',
      genre1: 'Action',
      genre2: 'Fantasy',
      platform: 'Crunchyroll',
      rating: 9.2,
      episodes: 12,
      tint: Color(0xFF1A0A2E),
    ),
    Anime(
      title: 'Jujutsu Kaisen',
      genre1: 'Dark Fantasy',
      genre2: 'Supernatural',
      platform: 'Netflix',
      rating: 9.0,
      episodes: 24,
      tint: Color(0xFF0D1A3A),
    ),
    Anime(
      title: 'Frieren: Beyond Journey\'s End',
      genre1: 'Adventure',
      genre2: 'Drama',
      platform: 'Crunchyroll',
      rating: 9.4,
      episodes: 28,
      tint: Color(0xFF0A1A12),
    ),
  ];

  static const List<Anime> trending = [
    Anime(title: 'Attack on Titan', genre1: 'Action', genre2: 'Drama',
        platform: 'Crunchyroll', rating: 8.9, episodes: 87, tint: Color(0xFF1E1A2E)),
    Anime(title: 'Jujutsu Kaisen', genre1: 'Fantasy', genre2: 'Action',
        platform: 'Netflix', rating: 9.0, episodes: 24, tint: Color(0xFF1A1E28)),
    Anime(title: 'Spy × Family', genre1: 'Comedy', genre2: 'Action',
        platform: 'Prime Video', rating: 8.7, episodes: 13, tint: Color(0xFF1A2020)),
    Anime(title: 'Chainsaw Man', genre1: 'Action', genre2: 'Horror',
        platform: 'Crunchyroll', rating: 8.5, episodes: 12, tint: Color(0xFF2A1A1A)),
  ];

  static const List<Episode> latestEpisodes = [
    Episode(title: 'One Piece', episodeNumber: 1102, durationMin: 24,
        isNew: false, progress: 0.65, tint: Color(0xFF1E1A2E)),
    Episode(title: 'Bleach: Thousand-Year Blood War', episodeNumber: 26,
        durationMin: 23, isNew: true, progress: 0.0, tint: Color(0xFF1A1E28)),
    Episode(title: 'Naruto Shippuden', episodeNumber: 500, durationMin: 22,
        isNew: false, progress: 0.3, tint: Color(0xFF1A2020)),
  ];

  static const List<Anime> popular = [
    Anime(title: 'Fullmetal Alchemist: Brotherhood', genre1: 'Action',
        genre2: 'Adventure', platform: 'Crunchyroll', rating: 9.1,
        episodes: 64, tint: Color(0xFF1E1A2E)),
    Anime(title: 'Hunter × Hunter', genre1: 'Action', genre2: 'Adventure',
        platform: 'Netflix', rating: 9.0, episodes: 148, tint: Color(0xFF1A2020)),
    Anime(title: 'Steins;Gate', genre1: 'Sci-Fi', genre2: 'Thriller',
        platform: 'Crunchyroll', rating: 9.2, episodes: 24, tint: Color(0xFF1A1E28)),
    Anime(title: 'Vinland Saga', genre1: 'Historical', genre2: 'Action',
        platform: 'Netflix', rating: 8.8, episodes: 24, tint: Color(0xFF2A1A1A)),
  ];
}

// ─────────────────────────────────────────────
// HOME PAGE
// ─────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final api = ApiService();
  List<AnimeModel> terbaru = [];
  List<AnimeModel> latestEpisodes = [];
  bool loading = true;

  List<GenreAnime> action = [];
  List<GenreAnime> romance = [];
  List<GenreAnime> comedy = [];
  List<GenreAnime> fantasy = [];
  List<GenreAnime> school = [];
  List<GenreAnime> isekai = [];
  List<GenreAnime> adventure = [];
  List<GenreAnime> horror = [];
  List<GenreAnime> sciFi = [];
  List<GenreAnime> mystery = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final data = await api.getTerbaru();
      final home = await api.getHomeGenres();
      print("HOME DATA:");
      print(home.keys);

      setState(() {
        terbaru = data.map((e) => AnimeModel.fromJson(e)).toList();
        latestEpisodes = data.take(8).map((e) => AnimeModel.fromJson(e)).toList();

        action    = _parseGenre(home['action']);
        romance   = _parseGenre(home['romance']);
        comedy    = _parseGenre(home['comedy']);
        fantasy   = _parseGenre(home['fantasy']);
        school    = _parseGenre(home['school']);
        isekai    = _parseGenre(home['isekai']);
        adventure = _parseGenre(home['adventure']);
        horror    = _parseGenre(home['horror']);
        sciFi     = _parseGenre(home['sci-fi']);
        mystery   = _parseGenre(home['mystery']);

        loading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  List<GenreAnime> _parseGenre(dynamic data) {
    if (data is List) {
      return data.map((e) => GenreAnime.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AVColors.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _HeaderSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: _FeaturedBanner(
                animeList: terbaru,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: _TrendingSection(
                animeList: terbaru,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Consumer<HistoryProvider>(
                builder: (context, history, child) {
                  return _LatestEpisodesSection(
                    animeList: history.history,
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: _GenreSection(
                action: action,
                romance: romance,
                comedy: comedy,
                fantasy: fantasy,
                school: school,
                isekai: isekai,
                adventure: adventure,
                horror: horror,
                sciFi: sciFi,
                mystery: mystery,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION: HEADER
// ─────────────────────────────────────────────
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANIMEVAULT',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2.5,
                    color: AVColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Home',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: AVColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AVColors.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: AVColors.border),
            ),
            child: const Icon(Icons.notifications_outlined,
                size: 18, color: AVColors.textSecondary),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AVColors.primary, AVColors.secondary],
              ),
            ),
            child: const Center(
              child: Text('R',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION: FEATURED BANNER — FIXED
// ─────────────────────────────────────────────
class _FeaturedBanner extends StatefulWidget {
  final List<AnimeModel> animeList;

  const _FeaturedBanner({required this.animeList});

  @override
  State<_FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<_FeaturedBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Jika data sudah ada saat init (jarang), langsung start timer
    if (widget.animeList.isNotEmpty) {
      _startTimer();
    }
  }

  // FIX UTAMA: deteksi saat data API baru masuk ke widget
  @override
  void didUpdateWidget(_FeaturedBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animeList.isEmpty && widget.animeList.isNotEmpty) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!mounted) return;
        if (!_pageController.hasClients) return;

        final itemCount = widget.animeList.take(5).length;
        if (itemCount <= 1) return;

        final nextPage = (_currentPage + 1) % itemCount;

        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.animeList.take(5).toList();

    // Tampilkan placeholder saat data belum ada
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: AVColors.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AVColors.border),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AVColors.primary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _FeaturedCard(anime: items[index]);
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentPage ? 20 : 6,
                height: 3,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? AVColors.primary
                      : AVColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final AnimeModel anime;
  const _FeaturedCard({required this.anime});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnimeDetailPage(anime: anime),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AVColors.border),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                anime.thumb,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          AVColors.primary.withOpacity(0.3),
                          AVColors.background,
                        ],
                      ),
                    ),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PillBadge(
                          label: '✦  FEATURED',
                          bgColor: AVColors.primary,
                          textColor: Colors.white,
                        ),
                        _PillBadge(
                          label: 'NEW',
                          bgColor: AVColors.surface.withOpacity(0.7),
                          textColor: AVColors.gold,
                          borderColor: AVColors.border,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      anime.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AVColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      anime.ep,
                      style: const TextStyle(
                          fontSize: 11, color: AVColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _FilledButton(
                          label: 'Watch Now',
                          icon: Icons.play_arrow_rounded,
                          color: AVColors.primary,
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),
                        _OutlinedActionButton(
                          label: '+ List',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION: TRENDING
// ─────────────────────────────────────────────
class _TrendingSection extends StatelessWidget {
  final List<AnimeModel> animeList;

  const _TrendingSection({required this.animeList});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Trending Now',
          accentColor: AVColors.primary,
          onSeeAll: () {},
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 195,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: animeList.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                    right: index < animeList.length - 1 ? 10 : 0),
                child: _AnimePosterCard(anime: animeList[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnimePosterCard extends StatelessWidget {
  final AnimeModel anime;

  const _AnimePosterCard({
    super.key,
    required this.anime,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnimeDetailPage(anime: anime),
          ),
        );
      },
      child: SizedBox(
        width: 96,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 96,
              height: 128,
              decoration: BoxDecoration(
                color: AVColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AVColors.border),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      anime.thumb,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.image_outlined,
                              size: 32, color: Color(0xFF2A2A35)),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AVColors.surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                            fontSize: 9,
                            color: AVColors.gold,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              anime.title,
              style: const TextStyle(fontSize: 11, color: Color(0xFFCCCCCC)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              anime.ep,
              style: const TextStyle(fontSize: 9, color: AVColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION: TERAKHIR DITONTON
// ─────────────────────────────────────────────
class _LatestEpisodesSection extends StatelessWidget {
  final List<WatchHistory> animeList;

  const _LatestEpisodesSection({
    super.key,
    required this.animeList,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(
          title: 'Terakhir Ditonton',
          accentColor: AVColors.secondary,
          onSeeAll: () {},
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: animeList.length,
            itemBuilder: (context, index) {
              return _ContinueWatchingCard(
                anime: animeList[index],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  final WatchHistory anime;

  const _ContinueWatchingCard({required this.anime});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnimeDetailPage(
              anime: AnimeModel(
                title: anime.title,
                thumb: anime.thumb,
                link: anime.link,
                ep: 'Episode ${anime.currentEpisode}',
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.network(
                    anime.thumb,
                    width: 180,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AVColors.surface2,
                      height: 100,
                      width: 180,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Episode ${anime.currentEpisode}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: anime.totalEpisodes > 0
                    ? anime.currentEpisode / anime.totalEpisodes
                    : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              anime.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION: GENRE (10 kategori)
// ─────────────────────────────────────────────
class _GenreSection extends StatelessWidget {
  final List<GenreAnime> action;
  final List<GenreAnime> romance;
  final List<GenreAnime> comedy;
  final List<GenreAnime> fantasy;
  final List<GenreAnime> school;
  final List<GenreAnime> isekai;
  final List<GenreAnime> adventure;
  final List<GenreAnime> horror;
  final List<GenreAnime> sciFi;
  final List<GenreAnime> mystery;

  const _GenreSection({
    required this.action,
    required this.romance,
    required this.comedy,
    required this.fantasy,
    required this.school,
    required this.isekai,
    required this.adventure,
    required this.horror,
    required this.sciFi,
    required this.mystery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GenreRow(title: "Action",    animeList: action),
        const SizedBox(height: 20),
        GenreRow(title: "Romance",   animeList: romance),
        const SizedBox(height: 20),
        GenreRow(title: "Comedy",    animeList: comedy),
        const SizedBox(height: 20),
        GenreRow(title: "Fantasy",   animeList: fantasy),
        const SizedBox(height: 20),
        GenreRow(title: "School",    animeList: school),
        const SizedBox(height: 20),
        GenreRow(title: "Isekai",    animeList: isekai),
        const SizedBox(height: 20),
        GenreRow(title: "Adventure", animeList: adventure),
        const SizedBox(height: 20),
        GenreRow(title: "Horror",    animeList: horror),
        const SizedBox(height: 20),
        GenreRow(title: "Sci-Fi",    animeList: sciFi),
        const SizedBox(height: 20),
        GenreRow(title: "Mystery",   animeList: mystery),
      ],
    );
  }
}

class GenreRow extends StatelessWidget {
  final String title;
  final List<GenreAnime> animeList;

  const GenreRow({
    super.key,
    required this.title,
    required this.animeList,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(
          title: title,
          accentColor: AVColors.amber,
          onSeeAll: () {},
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: animeList.length,
            itemBuilder: (context, index) {
              final anime = animeList[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnimeDetailPage(
                        anime: AnimeModel(
                          title: anime.title,
                          thumb: anime.thumb,
                          link: anime.link,
                          ep: anime.ep,
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: AVColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            anime.thumb,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AVColors.surface2,
                                child: const Icon(Icons.image, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          anime.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// REUSABLE SMALL WIDGETS
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color accentColor;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.accentColor,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AVColors.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: TextStyle(fontSize: 12, color: accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenrePill extends StatelessWidget {
  final String label;
  const _GenrePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AVColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 9, color: Color(0xFFB3A9FF)),
      ),
    );
  }
}

class _FilledButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FilledButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlinedActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AVColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;

  const _PillBadge({
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: textColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
