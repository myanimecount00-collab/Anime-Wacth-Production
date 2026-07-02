class StreamResult {
  final String streamType;
  final String? streamUrl;
  final String? videoUrl;
  final String? iframeSrc;
  final List<dynamic> sources;

  const StreamResult({
    required this.streamType,
    this.streamUrl,
    this.videoUrl,
    this.iframeSrc,
    required this.sources,
  });

  factory StreamResult.fromJson(Map<String, dynamic> json) {
    return StreamResult(
      streamType: json["streamType"]?.toString() ?? "",
      streamUrl: json["streamUrl"]?.toString(),
      videoUrl: json["videoUrl"]?.toString(),
      iframeSrc: json["iframeSrc"]?.toString(),
      sources: json["sources"] as List? ?? const [],
    );
  }

bool get isBrowser => streamType == "browser";

bool get isIframe => streamType == "iframe";

bool get isMp4 => streamType == "mp4";

bool get useWebView => isBrowser || isIframe;

bool get useVideoPlayer => isMp4;
}