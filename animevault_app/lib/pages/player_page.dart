import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// PlayerPage - versi flutter_inappwebview
///
/// Dependency (pubspec.yaml):
///   flutter_inappwebview: ^6.1.5
///
/// Catatan AndroidManifest.xml:
/// - Jika ada sumber video http (bukan https), tambahkan di tag <application>:
///     android:usesCleartextTraffic="true"
/// - minSdkVersion minimal 19, compileSdk minimal 34 (syarat plugin versi 6.x)
class PlayerPage extends StatefulWidget {
  final String url;

  const PlayerPage({
    super.key,
    required this.url,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  InAppWebViewController? _webViewController;

  bool _isLoading = true;
  bool _isFullscreen = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Script untuk memaksa video/iframe player selalu mengikuti ukuran layar,
  // mengatasi player yang masih pakai CSS fixed-size (sumber utama "gepeng").
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
        style.type = 'text/css';
        style.appendChild(document.createTextNode(
          'html, body { margin:0 !important; padding:0 !important; background:#000 !important; overflow:hidden !important; }' +
          'video, iframe, .jwplayer, .plyr, .video-js, #player, .player-container, .play-video {' +
          ' width:100vw !important; height:100vh !important; max-width:100% !important;' +
          ' object-fit:contain !important; }'
        ));
        document.head.appendChild(style);
      } catch (e) {}
    })();
  ''';

  @override
  void initState() {
    super.initState();
    // Default tetap portrait. Rotate ke landscape hanya dipicu
    // saat user menekan tombol fullscreen di video (onEnterFullscreen).
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _restorePortrait();
    super.dispose();
  }

  void _restorePortrait() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _enterImmersiveLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _reload() async {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    await _webViewController?.reload();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("PLAYER URL = ${widget.url}");
    return PopScope(
      // Kalau lagi fullscreen, tombol back keluar dari fullscreen dulu,
      // bukan langsung keluar dari halaman.
      canPop: !_isFullscreen,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _isFullscreen) {
          await _webViewController?.evaluateJavascript(
            source: "if (document.exitFullscreen) { document.exitFullscreen(); }",
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        // Tidak ada AppBar -> benar-benar fullscreen
        body: SafeArea(
          top: !_isFullscreen,
          bottom: !_isFullscreen,
          child: Stack(
            children: [ 
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  javaScriptCanOpenWindowsAutomatically: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  allowsPictureInPictureMediaPlayback: true,
                  loadWithOverviewMode: true,
                  supportZoom: false,
                  builtInZoomControls: false,
                  displayZoomControls: false,
                  useHybridComposition: true, // render lebih stabil untuk video di Android
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                  transparentBackground: false,
                  cacheEnabled: true,
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                },
                onLoadStop: (controller, url) async {
                  await controller.evaluateJavascript(source: _responsiveFixJs);
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                onReceivedError: (controller, request, error) {
                  if (request.isForMainFrame ?? true) {
                    setState(() {
                      _isLoading = false;
                      _hasError = true;
                      _errorMessage = error.description;
                    });
                  }
                },
                onReceivedHttpError: (controller, request, errorResponse) {
                  final code = errorResponse.statusCode ?? 0;
                  if ((request.isForMainFrame ?? true) && code >= 400) {
                    setState(() {
                      _isLoading = false;
                      _hasError = true;
                      _errorMessage = 'HTTP error $code';
                    });
                  }
                },
                onEnterFullscreen: (controller) {
                  setState(() => _isFullscreen = true);
                  _enterImmersiveLandscape();
                },
                onExitFullscreen: (controller) {
                  setState(() => _isFullscreen = false);
                  _restorePortrait();
                },

                // ========================================================
                // TAMBAHAN: shouldOverrideUrlLoading, onLoadResource, onConsoleMessage
                // ========================================================
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url?.toString() ?? '';
                  print('🔄 NAVIGATING TO: $url');

                  // Blokir URL iklan / pop-up yang tidak diinginkan
                  final blockedPatterns = [
                    'popads',
                    'doubleclick',
                    'adsterra',
                    'shrink',
                    'exoclick',
                    'googlesyndication',
                    'facebook.com/tr',
                    'google-analytics',
                  ];
                  if (blockedPatterns.any((pattern) => url.contains(pattern))) {
                    print('🚫 BLOCKED: $url');
                    return NavigationActionPolicy.CANCEL;
                  }

                  // Izinkan navigasi biasa
                  return NavigationActionPolicy.ALLOW;
                },

                onLoadResource: (controller, resource) {
                  // Memantau resource yang dimuat (termasuk video)
                  final url = resource.url.toString();
                  if (url.contains('.mp4') || 
                      url.contains('videoplayback') || 
                      url.contains('m3u8') ||
                      url.contains('manifest')) {
                    print('🎬 VIDEO RESOURCE: $url');
                  } else {
                    // Log hanya untuk debugging (bisa dikurangi)
                    print('📦 RESOURCE: $url');
                  }
                },

                onConsoleMessage: (controller, consoleMessage) {
                  // Menangkap semua console.log/warn/error dari JavaScript
                  print('📝 CONSOLE [${consoleMessage.messageLevel}]: ${consoleMessage.message}');
                  // Jika ada error yang spesifik, bisa ditangani
                  if (consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
                    // Misal tampilkan snackbar atau fallback
                  }
                },
              ),

              if (_isLoading && !_hasError)
                Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),

              if (_hasError) _buildErrorView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat video.\n$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}