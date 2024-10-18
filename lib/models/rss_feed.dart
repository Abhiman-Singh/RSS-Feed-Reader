// lib/models/rss_feed.dart
class RssFeed {
  final String title;
  final String link;
  final String description;
  final String pubDate;
  final String mediaUrl;
  final String
      contentType; // New field for content type: "audio", "video", "text"

  RssFeed({
    required this.title,
    required this.link,
    required this.description,
    required this.pubDate,
    required this.mediaUrl,
    required this.contentType, // Initialize the content type
  });
}
