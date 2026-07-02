import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/widgets/anime_model.dart';
import '../models/widgets/anime_detail_model.dart';
import '../models/widgets/stream_result.dart';
import '../services/api_service.dart';
import '../provider/history_provider.dart';
import 'episode_loading_dialog.dart';
import 'watch_page.dart';
import '../models/widgets/shimmer_loading.dart';

class AnimeDetailPage extends StatefulWidget {
  final AnimeModel anime;

  const AnimeDetailPage({
    super.key,
    required this.anime,
  });

  @override
  State<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  final ApiService api = ApiService();
  AnimeDetailModel? detail;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    try {
      final result = await api.getDetail(widget.anime.link);
      debugPrint(result.toString());
      debugPrint("SINOPSIS = ${result.synopsis}");
      if (mounted) {
        setState(() {
          detail = result;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
      debugPrint('Error loading detail: $e');
    }
  }

  Future<void> _openEpisode(int index, String cleanTitle) async {
    if (detail == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(),
    );

    final stopwatch = Stopwatch()..start();
    const minDisplayMs = 2200;

    try {
      final episodeUrl = detail!.episodes[index]['link'];
      final StreamResult stream = await api.getStream(episodeUrl);

      debugPrint("========== STREAM ==========");
      debugPrint(stream.toString());
      debugPrint("Stream Type: ${stream.streamType}");
      debugPrint("Stream URL: ${stream.streamUrl}");
      debugPrint("useWebView: ${stream.useWebView}");
      debugPrint("============================");

      // ✅ Ambil langsung dari objek
      final chosenStreamUrl = stream.streamUrl;
      final bool useWebView = stream.useWebView;

      final remaining = minDisplayMs - stopwatch.elapsedMilliseconds;
      if (remaining > 0) {
        await Future.delayed(Duration(milliseconds: remaining));
      }

      if (!mounted) return;
      Navigator.pop(context);
if (chosenStreamUrl == null || chosenStreamUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stream tidak ditemukan untuk episode ini')),
        );
        return;
      }

      final watchEpisodes = <WatchEpisode>[
        for (int i = 0; i < detail!.episodes.length; i++)
          WatchEpisode(
            number: detail!.episodes.length - i,
            episodeUrl: detail!.episodes[i]['link'],
            thumbnailUrl: widget.anime.thumb,
          ),
      ];

      // Catat anime ke riwayat sebelum membuka WatchPage
      final currentEpisode = detail!.episodes.length - index;
      context.read<HistoryProvider>().saveWatchHistory(
        title: widget.anime.title,
        thumb: widget.anime.thumb,
        link: widget.anime.link,
        currentEpisode: currentEpisode,
        totalEpisodes: detail!.episodes.length,
      );

      // ── DEBUG LOG SEBELUM NAVIGASI ──
      debugPrint("========== PUSH WATCH ==========");
      debugPrint("streamType      = ${stream.streamType}");
      debugPrint("streamUrl       = ${stream.streamUrl}");
      debugPrint("iframeSrc       = ${stream.iframeSrc}");
      debugPrint("useWebView      = ${stream.useWebView}");
      debugPrint("initialIsIframe = $useWebView");
      debugPrint("===============================");

      // ✅ Kirim useWebView yang benar (bukan useIframe)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WatchPage(
            title: cleanTitle,
            score: double.tryParse(
                  detail?.score?.replaceAll(',', '.') ?? '0',
                ) ??
                0,
            ratingCount: 0,
            genres: detail?.genres ?? [],
            synopsis: detail?.synopsis ?? '',
            initialEpisodeIndex: index,
            initialStreamUrl: chosenStreamUrl,
            initialIsIframe: useWebView,
            episodes: watchEpisodes,
            recommended: const [],
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error loading stream: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat episode, coba lagi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanTitle = widget.anime.title
        .replaceAll(' Subtitle Indonesia', '')
        .replaceAll(' Sub Indo', '');

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          cleanTitle,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: loading
          ? const AnimeDetailSkeleton()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.anime.thumb,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[900]),
                        ),
                        Container(
                          color: Colors.black.withOpacity(0.5),
                        ),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.anime.thumb,
                              width: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 140,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cleanTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.anime.ep,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              detail?.score ?? 'N/A',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (detail != null && detail!.genres.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: detail!.genres.map((genre) {
                              return Chip(
                                label: Text(
                                  genre,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.deepPurple.withOpacity(0.3),
                                labelStyle: const TextStyle(color: Colors.white),
                                side: BorderSide.none,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                        const SizedBox(height: 30),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _buildSynopsisSection(),
                        ),
                        const SizedBox(height: 30),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _buildEpisodesSection(),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSynopsisSection() {
    final synopsis = detail?.synopsis ?? '';
    return Column(
      key: ValueKey(synopsis.hashCode),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Synopsis",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          synopsis.isNotEmpty
              ? synopsis
              : "Synopsis belum ada.",
          style: const TextStyle(
            color: Colors.grey,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodesSection() {
    if (detail == null) {
      return const SizedBox();
    }
    return Column(
      key: ValueKey(detail!.episodes.length),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Episodes",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: detail!.episodes.length,
          itemBuilder: (context, index) {
            final epNumber = detail!.episodes.length - index;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.9 + (0.1 * value),
                    child: child,
                  ),
                );
              },
              child: Card(
                color: const Color(0xFF17171C),
                child: ListTile(
                  onTap: () => _openEpisode(index, cleanTitle()),
                  leading: const Icon(
                    Icons.play_circle_fill,
                    color: Colors.deepPurple,
                  ),
                  title: Text(
                    'Episode $epNumber',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: detail!.episodes[index]['date'] != null
                      ? Text(
                          detail!.episodes[index]['date'],
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        )
                      : null,
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white54,
                    size: 16,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String cleanTitle() => widget.anime.title
      .replaceAll(' Subtitle Indonesia', '')
      .replaceAll(' Sub Indo', '');
}