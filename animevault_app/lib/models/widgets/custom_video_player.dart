import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// =============================================================================
/// CustomVideoPlayer — AniVa
/// =============================================================================
/// Video player MP4 custom (tanpa Chewie, tanpa WebView/iframe) untuk AniVa.
/// Semua UI kontrol dibangun manual dengan Flutter widget biasa — widget bawaan
/// `VideoPlayer` HANYA dipakai untuk merender frame video, bukan sebagai UI akhir.
///
/// Struktur file ini sengaja dibuat dalam SATU file agar mudah dipindah antar
/// proyek, tapi tetap dipecah rapi per "section" lewat komentar supaya mudah
/// dikembangkan ke depannya (playback speed, gesture brightness/volume,
/// subtitle, lock screen, dsb — lihat bagian "TITIK EKSTENSI" di bawah).
/// =============================================================================

class CustomVideoPlayer extends StatefulWidget {
  /// URL video MP4 yang akan diputar.
  final String url;

  /// Header HTTP opsional (misalnya Referer/User-Agent untuk sumber tertentu).
  final Map<String, String>? httpHeaders;

  /// Apakah video langsung diputar begitu siap.
  final bool autoPlay;

  /// Apakah video diulang otomatis saat selesai.
  final bool looping;

  /// Callback yang dipanggil ketika player gagal memuat video.
  /// Dapat digunakan untuk fallback ke player lain (misalnya WebView).
  final VoidCallback? onError;

  const CustomVideoPlayer({
    super.key,
    required this.url,
    this.httpHeaders,
    this.autoPlay = true,
    this.looping = false,
    this.onError,
  });

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  // ───────────────────────────────────────────────────────────────────────────
  // KONSTANTA TEMA
  // ───────────────────────────────────────────────────────────────────────────
  static const Color _kAccentColor = Color(0xFF7C4DFF); // ungu aksen
  static const Color _kBackgroundColor = Colors.black;
  static const Duration _kHideControlsDelay = Duration(seconds: 3);
  static const Duration _kFadeDuration = Duration(milliseconds: 250);
  static const Duration _kSeekStep = Duration(seconds: 10);

  // ───────────────────────────────────────────────────────────────────────────
  // CONTROLLER & STATE UTAMA
  // ───────────────────────────────────────────────────────────────────────────
  late VideoPlayerController _controller;

  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isMuted = false;
  bool _isFullscreen = false;

  bool _showControls = true;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Timer? _hideControlsTimer;

  _SeekDirection? _seekFeedback;
  Timer? _seekFeedbackTimer;

  // ───────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ───────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: widget.httpHeaders ??
          {
            "User-Agent":
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/137.0.0.0 Safari/537.36",
            "Referer":
                "https://desustream.info/",
          },
    );

    _controller.addListener(_onControllerUpdate);

    try {
      await _controller.initialize();
      await _controller.setLooping(widget.looping);

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _duration = _controller.value.duration;
      });

      if (widget.autoPlay) {
        await _controller.play();
      }

      _resetHideControlsTimer();
    } catch (e, stack) {
      debugPrint("========== VIDEO ERROR ==========");
      debugPrint(e.toString());
      debugPrint(stack.toString());

      if (!mounted) return;

      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
      // Panggil onError jika ada, agar halaman induk bisa fallback
      widget.onError?.call();
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final value = _controller.value;

    if (value.hasError && !_hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = value.errorDescription ?? 'Terjadi kesalahan pemutaran';
      });
      widget.onError?.call();
      return;
    }

    setState(() {
      _isPlaying = value.isPlaying;
      _isBuffering = value.isBuffering;
      _position = value.position;
      _duration = value.duration;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _hideControlsTimer?.cancel();
    _seekFeedbackTimer?.cancel();

    if (_isFullscreen) {
      _restorePortraitMode();
    }
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // KONTROL DASAR: PLAY / PAUSE / SEEK / MUTE
  // ───────────────────────────────────────────────────────────────────────────
  void _togglePlayPause() {
    if (!_isInitialized) return;
    if (_isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    _resetHideControlsTimer();
  }

  void _seekTo(Duration target) {
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > _duration ? _duration : target);
    _controller.seekTo(clamped);
    _resetHideControlsTimer();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
    _resetHideControlsTimer();
  }

  void _handleDoubleTap(_SeekDirection direction) {
    if (!_isInitialized) return;

    final delta = direction == _SeekDirection.backward ? -_kSeekStep : _kSeekStep;
    _seekTo(_position + delta);

    _seekFeedbackTimer?.cancel();
    setState(() => _seekFeedback = direction);
    _seekFeedbackTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _seekFeedback = null);
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // KONTROL TAMPILAN: SHOW/HIDE OVERLAY
  // ───────────────────────────────────────────────────────────────────────────
  void _toggleControlsVisibility() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _resetHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (!_isPlaying) return;
    _hideControlsTimer = Timer(_kHideControlsDelay, () {
      if (!mounted) return;
      setState(() => _showControls = false);
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FULLSCREEN
  // ───────────────────────────────────────────────────────────────────────────
  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      _enterFullscreenMode();
    } else {
      _restorePortraitMode();
    }
    _resetHideControlsTimer();
  }

  void _enterFullscreenMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _restorePortraitMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HELPER FORMAT WAKTU
  // ───────────────────────────────────────────────────────────────────────────
  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BUILD
  // ───────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorScreen();
    }

    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    return AspectRatio(
      aspectRatio: _isFullscreen ? MediaQuery.of(context).size.aspectRatio : _controller.value.aspectRatio,
      child: Container(
        color: _kBackgroundColor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControlsVisibility,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),

              _buildDoubleTapZones(),

              _buildGradientOverlay(),

              if (_isBuffering) _buildBufferingIndicator(),

              if (_seekFeedback != null) _buildSeekFeedback(),

              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: _kFadeDuration,
                curve: Curves.easeInOut,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: _buildControlsOverlay(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // WIDGET: LOADING SCREEN
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLoadingScreen() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: _kBackgroundColor,
        child: const Center(
          child: SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_kAccentColor),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // WIDGET: ERROR SCREEN (DENGAN FALLBACK BUTTON)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildErrorScreen() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: _kBackgroundColor,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: _kAccentColor, size: 30),
                  const SizedBox(height: 12),
                  const Text(
                    'Video gagal dimuat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (widget.onError != null) {
                        print("❌ CustomVideoPlayer gagal → Fallback ke WebView");
                        widget.onError!();  // Panggil callback fallback
                      } else {
                        setState(() {
                          _hasError = false;
                          _isInitialized = false;
                        });
                        _initializePlayer();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccentColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(widget.onError != null ? 'Gunakan Player Lain' : 'Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // WIDGET: ZONA DOUBLE TAP (KIRI = MUNDUR, KANAN = MAJU)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDoubleTapZones() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: () => _handleDoubleTap(_SeekDirection.backward),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: () => _handleDoubleTap(_SeekDirection.forward),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // WIDGET: FEEDBACK ANIMASI SEEK (+10 / -10)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSeekFeedback() {
    final isBackward = _seekFeedback == _SeekDirection.backward;
    return Align(
      alignment: isBackward ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isBackward ? Icons.replay_10_rounded : Icons.forward_10_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // WIDGET: GRADIENT OVERLAY ATAS & BAWAH
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildGradientOverlay() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: _kFadeDuration,
      child: const IgnorePointer(
        child: Column(
          children: [
            _GradientStrip(alignmentTop: true),
            Spacer(),
            _GradientStrip(alignmentTop: false),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // WIDGET: INDIKATOR BUFFERING
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBufferingIndicator() {
    return const Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(_kAccentColor),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // WIDGET: SELURUH OVERLAY KONTROL (TOP BAR, CENTER PLAY, BOTTOM BAR)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildControlsOverlay() {
    return Column(
      children: [
        _buildTopBar(),
        const Spacer(),
        _buildCenterPlayButton(),
        const Spacer(),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _ControlIconButton(
            icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            onTap: _toggleMute,
          ),
        ],
      ),
    );
  }

  Widget _buildCenterPlayButton() {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: AnimatedScale(
        scale: _isPlaying ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.4),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Icon(
            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final maxSeconds = _duration.inSeconds.toDouble();
    final currentSeconds = _position.inSeconds.toDouble().clamp(0, maxSeconds == 0 ? 1 : maxSeconds);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: _kAccentColor,
              inactiveTrackColor: Colors.white.withOpacity(0.25),
              thumbColor: _kAccentColor,
              overlayColor: _kAccentColor.withOpacity(0.2),
            ),
            child: Slider(
              value: currentSeconds.toDouble(),
              max: maxSeconds == 0 ? 1 : maxSeconds,
              onChangeStart: (_) => _hideControlsTimer?.cancel(),
              onChanged: (value) {
                setState(() => _position = Duration(seconds: value.toInt()));
              },
              onChangeEnd: (value) {
                _seekTo(Duration(seconds: value.toInt()));
              },
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),

              _ControlIconButton(
                icon: _isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                onTap: _toggleFullscreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TITIK EKSTENSI
  // ═══════════════════════════════════════════════════════════════════════════
  // ...
}

/// Arah seek untuk feedback double-tap.
enum _SeekDirection { backward, forward }

/// Strip gradient tipis untuk overlay atas/bawah, dipakai di [_buildGradientOverlay].
class _GradientStrip extends StatelessWidget {
  final bool alignmentTop;

  const _GradientStrip({required this.alignmentTop});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignmentTop ? Alignment.topCenter : Alignment.bottomCenter,
          end: alignmentTop ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.55),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

/// Tombol ikon kontrol standar (mute, fullscreen, dll).
class _ControlIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}