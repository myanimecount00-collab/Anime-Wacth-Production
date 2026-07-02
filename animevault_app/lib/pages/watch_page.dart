import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import '../services/comment_service.dart';
import 'player_page.dart';
import '../models/widgets/custom_video_player.dart';
import '../models/widgets/stream_result.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as custom_tabs; // ✅ Tambahan

// ============================================================
// DESIGN TOKENS
// ============================================================
class _AppColors {
  static const background = Color(0xFF0D0D12);
  static const surface = Color(0xFF1A1A20);
  static const surfaceLight = Color(0xFF24242B);
  static const accent = Color(0xFF8B5CF6);
  static const gold = Color(0xFFFBBF24);
  static const pink = Color(0xFFEC4899);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFA0A0AA);
  static const divider = Color(0xFF2A2A30);
}

// ============================================================
// LIGHTWEIGHT DATA ADAPTERS
// ============================================================
class WatchEpisode {
  final int number;
  final String episodeUrl;
  final String? thumbnailUrl;

  const WatchEpisode({
    required this.number,
    required this.episodeUrl,
    this.thumbnailUrl,
  });
}

class RecommendedAnime {
  final String title;
  final double score;
  final String genre;
  final String? coverImageUrl;

  const RecommendedAnime({
    required this.title,
    required this.score,
    required this.genre,
    this.coverImageUrl,
  });
}

class _CommentData {
  final String username;
  final String timeAgo;
  final String text;
  int likes;
  bool liked;

  _CommentData({
    required this.username,
    required this.timeAgo,
    required this.text,
    this.likes = 0,
    this.liked = false,
  });
}

// ============================================================
// WATCH PAGE
// ============================================================
class WatchPage extends StatefulWidget {
  final String title;
  final double score;
  final int ratingCount;
  final List<String> genres;
  final String synopsis;
  final List<WatchEpisode> episodes;
  final int initialEpisodeIndex;
  final List<RecommendedAnime> recommended;
  final String? initialStreamUrl;
  final bool initialIsIframe;

  const WatchPage({
    super.key,
    required this.title,
    required this.score,
    required this.ratingCount,
    required this.genres,
    required this.synopsis,
    required this.episodes,
    required this.recommended,
    this.initialEpisodeIndex = 0,
    this.initialStreamUrl,
    this.initialIsIframe = false,
  });

  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  final ApiService _api = ApiService();
  final CommentService _commentService = CommentService();

  late int _selectedEpisodeIndex;
  bool _synopsisExpanded = false;
  String? _currentStreamUrl;
  bool _isResolvingStream = false;
  bool _isIframe = false;

  final TextEditingController _commentController = TextEditingController();

  static const String _currentUserInitial = 'Y';

  @override
  void initState() {
    super.initState();

    debugPrint("========== INIT WATCH ==========");
    debugPrint("initialStreamUrl = ${widget.initialStreamUrl}");
    debugPrint("initialIsIframe  = ${widget.initialIsIframe}");

    _selectedEpisodeIndex = widget.initialEpisodeIndex;

    final initial = widget.initialStreamUrl;

    if (initial != null && initial.isNotEmpty) {
      _currentStreamUrl = initial;
      _isIframe = widget.initialIsIframe;
    } else {
      _currentStreamUrl = null;
      _isIframe = false;
    }

    debugPrint("_currentStreamUrl = $_currentStreamUrl");
    debugPrint("_isIframe         = $_isIframe");
    debugPrint("===============================");

    if (_currentStreamUrl == null) {
      _resolveStream(_currentEpisode.episodeUrl);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  WatchEpisode get _currentEpisode => widget.episodes[_selectedEpisodeIndex];

  Future<void> _resolveStream(String episodeUrl) async {
    setState(() => _isResolvingStream = true);

    try {
      debugPrint("\n\n========== 📡 RESOLVE STREAM ==========");
      debugPrint("📍 Episode: $episodeUrl");

      final StreamResult result = await _api.getStream(episodeUrl);

      debugPrint("========== RESOLVE ==========");
      debugPrint("streamType = ${result.streamType}");
      debugPrint("streamUrl  = ${result.streamUrl}");
      debugPrint("useWebView = ${result.useWebView}");
      debugPrint("=============================");

      if (!mounted) return;

      if (result.useWebView) {
        debugPrint("MASUK WEBVIEW");
        setState(() {
          debugPrint("SETSTATE");
          debugPrint("_isIframe => ${result.useWebView}");
          _currentStreamUrl = result.streamUrl;
          _isIframe = true;
          _isResolvingStream = false;
        });
      } else if (result.useVideoPlayer) {
        debugPrint("MASUK VIDEO PLAYER");
        setState(() {
          debugPrint("SETSTATE");
          debugPrint("_isIframe => ${result.useWebView}");
          _currentStreamUrl = result.streamUrl;
          _isIframe = false;
          _isResolvingStream = false;
        });
      } else {
        debugPrint("MASUK FALLBACK (tidak ada stream valid)");
        setState(() {
          debugPrint("SETSTATE (fallback)");
          _currentStreamUrl = null;
          _isIframe = false;
          _isResolvingStream = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada stream yang tersedia')),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      setState(() => _isResolvingStream = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _selectEpisode(int index) {
    if (index < 0 || index >= widget.episodes.length) return;
    if (index == _selectedEpisodeIndex) return;
    setState(() => _selectedEpisodeIndex = index);
    _resolveStream(_currentEpisode.episodeUrl);
  }

  void _openFullscreenPlayer() {
    final url = _currentStreamUrl;
    if (url == null || url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerPage(url: url),
      ),
    );
  }

  void _toggleLike(_CommentData comment) {
    setState(() {
      comment.liked = !comment.liked;
      comment.likes += comment.liked ? 1 : -1;
    });
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login terlebih dahulu')),
      );
      return;
    }

    try {
      await _commentService.addComment(
        animeId: widget.title,
        episode: _currentEpisode.number,
        userId: user.uid,
        userName: user.displayName ?? 'User',
        userPhoto: user.photoURL ?? '',
        message: text,
      );
      _commentController.clear();
    } catch (e) {
      debugPrint('Gagal menambahkan komentar: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim komentar')),
      );
    }
  }

  // ✅ Fungsi tambahan untuk membuka Chrome Custom Tab
  Future<void> _openChromeTab(String url) async {
    try {
      await custom_tabs.launch(
        url,
      );
    } catch (e) {
      debugPrint("Chrome Tab Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("========== BUILD ==========");
    debugPrint("_isIframe         = $_isIframe");
    debugPrint("_currentStreamUrl = $_currentStreamUrl");
    debugPrint("_isResolving      = $_isResolvingStream");
    debugPrint("PLAYER = ${_isIframe ? "WEBVIEW" : "CUSTOM"}");
    debugPrint("===========================");

    final commentsStream = _commentService.getComments(
      widget.title,
      _currentEpisode.number,
    );

    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- PLAYER ----
              _currentStreamUrl == null
                  ? const _PlayerPlaceholder()
                  : Stack(
                      children: [
                        _isIframe
                            ? _PlayerSection(
                                url: _currentStreamUrl!,
                                onBack: () => Navigator.maybePop(context),
                                onExpand: _openFullscreenPlayer,
                              )
                            : CustomVideoPlayer(url: _currentStreamUrl!),
                      ],
                    ),

              // ---- HEADER: TITLE, SCORE, GENRE, SYNOPSIS ----
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TitleAndScore(
                      title: widget.title,
                      score: widget.score,
                      episodeNumber: _currentEpisode.number,
                    ),
                    const SizedBox(height: 12),
                    _GenreRow(genres: widget.genres),
                    const SizedBox(height: 16),
                    _SynopsisSection(
                      synopsis: widget.synopsis,
                      expanded: _synopsisExpanded,
                      onToggle: () =>
                          setState(() => _synopsisExpanded = !_synopsisExpanded),
                    ),
                    const SizedBox(height: 16),
                    const _SectionHeader(title: 'Episodes'),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // ---- EPISODE SELECTOR ----
              _EpisodeSelector(
                episodes: widget.episodes,
                selectedIndex: _selectedEpisodeIndex,
                onSelect: _selectEpisode,
              ),

              // ---- COMMENTS ----
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: _CommentsSection(
                  commentsStream: commentsStream,
                  controller: _commentController,
                  currentUserInitial: _currentUserInitial,
                  onSubmit: _submitComment,
                  onToggleLike: _toggleLike,
                ),
              ),

              // ---- RECOMMENDED ----
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 0, 0),
                child: const _SectionHeader(title: 'Recommended Anime'),
              ),
              const SizedBox(height: 12),
              _RecommendedList(items: widget.recommended),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PLAYER SECTION (WebView) - DIPERBARUI DENGAN SETTING BARU
// ============================================================
class _PlayerSection extends StatefulWidget {
  final String url;
  final VoidCallback onBack;
  final VoidCallback onExpand;

  const _PlayerSection({
    required this.url,
    required this.onBack,
    required this.onExpand,
  });

  @override
  State<_PlayerSection> createState() => _PlayerSectionState();
}

class _PlayerSectionState extends State<_PlayerSection> {
  InAppWebViewController? _controller;
  bool _isLoading = true;

  static const String _responsiveFixJs = '''
    (function() {
      try {
        var meta = document.querySelector('meta[name="viewport"]');
        if (!meta) {
          meta = document.createElement('meta');
          meta.name = 'viewport';
          document.head.appendChild(meta);
        }
        meta.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no';
        var style = document.createElement('style');
        style.appendChild(document.createTextNode(
          'html, body { margin:0 !important; padding:0 !important; background:#000 !important; overflow:hidden !important; }' +
          'video, iframe, .jwplayer, .plyr, .video-js, #player, .player-container { width:100% !important; height:100% !important; object-fit:contain !important; }'
        ));
        document.head.appendChild(style);
      } catch (e) {}
    })();
  ''';

  @override
  void didUpdateWidget(covariant _PlayerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() => _isLoading = true);
      _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(widget.url)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const SizedBox.shrink(),

          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              useHybridComposition: false,
              loadWithOverviewMode: true,
              useWideViewPort: true,
              supportZoom: false,
              builtInZoomControls: false,
              displayZoomControls: false,
              mixedContentMode:
                  MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
            ),
            onWebViewCreated: (controller) => _controller = controller,

            onConsoleMessage: (controller, message) {
              print("WEB CONSOLE : ${message.message}");
            },

            onUpdateVisitedHistory: (controller, url, isReload) {
              print("🔄 VISITED HISTORY: $url (reload: $isReload)");
            },

            shouldOverrideUrlLoading: (controller, navigationAction) async {
              print("➡️ NAVIGATE: ${navigationAction.request.url}");
              final url = navigationAction.request.url?.toString() ?? "";
              if (url.contains("popads") ||
                  url.contains("doubleclick") ||
                  url.contains("adsterra") ||
                  url.contains("shrink")) {
                print("🚫 BLOCKED: $url");
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },

            onCreateWindow: (controller, request) async {
              print("🪟 CREATE WINDOW: ${request.request.url}");
              return true;
            },

            onPermissionRequest: (controller, request) async {
              print("🔐 PERMISSION REQUEST: ${request.resources}");
              return PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT,
              );
            },

            onReceivedServerTrustAuthRequest:
                (controller, challenge) async {
              print("🔒 SSL HOST = ${challenge.protectionSpace.host}");
              return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.PROCEED,
              );
            },

            onReceivedHttpAuthRequest: (controller, challenge) async {
              print("🔑 HTTP AUTH REQUEST: host=${challenge.protectionSpace.host}, realm=${challenge.protectionSpace.realm}");
              return HttpAuthResponse(
                action: HttpAuthResponseAction.CANCEL,
              );
            },

            onLoadStart: (controller, url) {
              print("🌐 START : $url");
            },

            onReceivedError: (controller, request, error) {
              print("❌ ERROR : ${error.description}");
            },

            onReceivedHttpError: (controller, request, response) {
              print("❌ HTTP : ${response.statusCode}");
            },

            onProgressChanged: (controller, progress) {
              print("📊 PROGRESS: $progress%");
            },

            onTitleChanged: (controller, title) {
              print("📝 TITLE CHANGED: $title");
            },

            onLoadResource: (controller, resource) {
              final url = resource.url.toString();
              if (url.contains("videoplayback")) {
                print("🎬 VIDEO RESOURCE: $url");
              }
            },

            onLoadStop: (controller, url) async {
              print("✅ STOP : $url");

              final html = await controller.getHtml();
              print("HTML LENGTH = ${html?.length}");
              if (html != null && html.length > 0) {
                print(html.substring(0, 500 > html.length ? html.length : 500));
              }

              final url2 = await controller.getUrl();
              print("WEBVIEW URL = $url2");

              await controller.evaluateJavascript(source: _responsiveFixJs);

              final result = await controller.evaluateJavascript(
                source: '''
                  (() => {
                    const video = document.querySelector("video");
                    if (video) {
                      return {
                        src: video.src,
                        currentSrc: video.currentSrc
                      };
                    }
                    return "NO_VIDEO";
                  })();
                ''',
              );
              debugPrint(result.toString());

              final ua = await controller.evaluateJavascript(
                source: "navigator.userAgent",
              );
              debugPrint("🌍 WEBVIEW UA = $ua");

              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          Positioned(
            top: 8,
            left: 4,
            child: _OverlayIconButton(
              icon: Icons.arrow_back,
              onTap: widget.onBack,
            ),
          ),
          Positioned(
            top: 8,
            right: 4,
            child: _OverlayIconButton(
              icon: Icons.fullscreen,
              onTap: widget.onExpand,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OverlayIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.35),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }
}

// ============================================================
// TITLE & SCORE
// ============================================================
class _TitleAndScore extends StatelessWidget {
  final String title;
  final double score;
  final int episodeNumber;

  const _TitleAndScore({
    required this.title,
    required this.score,
    required this.episodeNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              score.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Episode $episodeNumber',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// GENRE CHIPS
// ============================================================
class _GenreRow extends StatelessWidget {
  final List<String> genres;
  const _GenreRow({required this.genres});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genres.map((g) => _GenreChip(label: g)).toList(),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;
  const _GenreChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.divider),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ============================================================
// SECTION HEADER
// ============================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ============================================================
// EPISODE SELECTOR
// ============================================================
class _EpisodeSelector extends StatelessWidget {
  final List<WatchEpisode> episodes;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _EpisodeSelector({
    required this.episodes,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: episodes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final ep = episodes[index];
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: Container(
              width: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? _AppColors.accent : _AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "EP ${ep.number}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// SYNOPSIS
// ============================================================
class _SynopsisSection extends StatelessWidget {
  final String synopsis;
  final bool expanded;
  final VoidCallback onToggle;

  const _SynopsisSection({
    required this.synopsis,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Synopsis'),
        const SizedBox(height: 10),
        Text(
          synopsis,
          maxLines: expanded ? null : 3,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            color: _AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              expanded ? 'Show less' : 'Read more',
              style: const TextStyle(
                color: _AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// COMMENTS
// ============================================================
class _CommentsSection extends StatelessWidget {
  final Stream<QuerySnapshot>? commentsStream;
  final TextEditingController controller;
  final String currentUserInitial;
  final VoidCallback onSubmit;
  final ValueChanged<_CommentData> onToggleLike;

  const _CommentsSection({
    required this.commentsStream,
    required this.controller,
    required this.currentUserInitial,
    required this.onSubmit,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Comments'),
        const SizedBox(height: 12),
        Row(
          children: [
            _InitialAvatar(initial: currentUserInitial),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: _AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: TextStyle(color: _AppColors.textSecondary),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => onSubmit(),
                ),
              ),
            ),
            IconButton(
              onPressed: onSubmit,
              icon: const Icon(Icons.send_rounded, color: _AppColors.accent),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: commentsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Text(
                'Gagal memuat komentar',
                style: TextStyle(color: Colors.red),
              );
            }
            final comments = snapshot.data?.docs ?? [];
            return Column(
              children: [
                Text(
                  'Komentar (${comments.length})',
                  style: const TextStyle(
                    color: _AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final data = comments[index].data() as Map<String, dynamic>;
                    return _CommentTile(
                      comment: _CommentData(
                        username: data['userName'] ?? 'User',
                        timeAgo: 'baru saja',
                        text: data['message'] ?? '',
                        likes: 0,
                        liked: false,
                      ),
                      onLike: () {},
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final _CommentData comment;
  final VoidCallback onLike;

  const _CommentTile({required this.comment, required this.onLike});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InitialAvatar(initial: comment.username[0].toUpperCase()),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.username,
                    style: const TextStyle(
                      color: _AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    comment.timeAgo,
                    style: const TextStyle(
                      color: _AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment.text,
                style: const TextStyle(
                  color: _AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            GestureDetector(
              onTap: onLike,
              child: Icon(
                comment.liked ? Icons.favorite : Icons.favorite_border,
                color: comment.liked ? _AppColors.pink : _AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${comment.likes}',
              style: const TextStyle(
                color: _AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initial;
  const _InitialAvatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: _AppColors.surfaceLight,
      child: Text(
        initial,
        style: const TextStyle(
          color: _AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ============================================================
// RECOMMENDED ANIME
// ============================================================
class _RecommendedList extends StatelessWidget {
  final List<RecommendedAnime> items;
  const _RecommendedList({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            _RecommendedCard(anime: items[index]),
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final RecommendedAnime anime;
  const _RecommendedCard({required this.anime});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: _NetworkOrFallback(
                url: anime.coverImageUrl,
                fallbackIcon: Icons.image_not_supported_outlined,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            anime.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: _AppColors.gold, size: 13),
              const SizedBox(width: 3),
              Text(
                '${anime.score} | ${anime.genre}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NETWORK IMAGE WITH FALLBACK
// ============================================================
class _NetworkOrFallback extends StatelessWidget {
  final String? url;
  final IconData fallbackIcon;

  const _NetworkOrFallback({required this.url, required this.fallbackIcon});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _fallback();
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: _AppColors.surface,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }

  Widget _fallback() {
    return Container(
      color: _AppColors.surface,
      child: Icon(fallbackIcon, color: _AppColors.textSecondary, size: 28),
    );
  }
}

// ============================================================
// PLAYER PLACEHOLDER
// ============================================================
class _PlayerPlaceholder extends StatelessWidget {
  const _PlayerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}