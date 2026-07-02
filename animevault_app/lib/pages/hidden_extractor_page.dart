import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/widgets/custom_video_player.dart'; // pastikan path import sesuai

class HiddenExtractorPage extends StatefulWidget {
  final String iframeUrl;

  const HiddenExtractorPage({
    super.key,
    required this.iframeUrl,
  });

  @override
  State<HiddenExtractorPage> createState() => _HiddenExtractorPageState();
}

class _HiddenExtractorPageState extends State<HiddenExtractorPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(widget.iframeUrl),
        ),
        onLoadResource: (controller, resource) {
          final url = resource.url.toString();

          // Deteksi URL video Google atau video playback
          if (url.contains("googlevideo") ||
              url.contains("videoplayback")) {
            // Langsung navigasi ke pemutar video kustom
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CustomVideoPlayer(
                  url: url,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}