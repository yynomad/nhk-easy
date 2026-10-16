class NewsItem {
  const NewsItem({
    required this.id,
    required this.titleHtml,
    this.url,
    this.date = '',
    this.imageUrl,
    this.bodyHtml,
    this.audioUrl,
    this.assetAudio,
    this.illustration,
    this.isDemo = false,
  });

  final String id;
  final String titleHtml;
  final String? url;
  final String date;
  final String? imageUrl;
  final String? bodyHtml;
  final String? audioUrl;
  final String? assetAudio;
  final String? illustration;
  final bool isDemo;

  NewsItem withArticle(String body, String? audio) => NewsItem(
    id: id,
    titleHtml: titleHtml,
    url: url,
    date: date,
    imageUrl: imageUrl,
    bodyHtml: body,
    audioUrl: audio,
    isDemo: isDemo,
    assetAudio: assetAudio,
    illustration: illustration,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'titleHtml': titleHtml,
    'url': url,
    'date': date,
    'imageUrl': imageUrl,
    'bodyHtml': bodyHtml,
    'audioUrl': audioUrl,
    'assetAudio': assetAudio,
    'illustration': illustration,
    'isDemo': isDemo,
  };
  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
    id: json['id'] as String,
    titleHtml: json['titleHtml'] as String,
    url: json['url'] as String?,
    date: json['date'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
    bodyHtml: json['bodyHtml'] as String?,
    audioUrl: json['audioUrl'] as String?,
    assetAudio: json['assetAudio'] as String?,
    illustration: json['illustration'] as String?,
    isDemo: json['isDemo'] == true,
  );
}
