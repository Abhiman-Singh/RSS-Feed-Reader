// lib/services/rss_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/rss_feed.dart';

class RssService {
  Future<List<RssFeed>> fetchRssFeeds() async {
    final List<RssFeed> feeds = [];
    final file = File('rss_links.txt');

    // Read the RSS feed links from the file
    final links = await file.readAsLines();

    for (String link in links) {
      try {
        final response = await http.get(Uri.parse(link));
        if (response.statusCode == 200) {
          final document = XmlDocument.parse(response.body);
          final items = document.findAllElements('item');

          for (var item in items) {
            // Get the title and remove HTML tags
            String rawTitle = item.findElements('title').first.text;
            String cleanTitle = _removeHtmlTags(rawTitle);

            // Get and clean the description, limit it to 150 characters
            String rawDescription = item.findElements('description').isNotEmpty
                ? item.findElements('description').first.text
                : '';
            String cleanDescription =
                _truncateDescription(_removeHtmlTags(rawDescription));

            // Extract the image URL
            String imageUrl = _extractImageUrl(item);

            // Determine the content type based on available elements (audio, video, text)
            String contentType = _determineContentType(item);

            feeds.add(RssFeed(
              title: cleanTitle,
              link: item.findElements('link').first.text,
              description: cleanDescription,
              pubDate: item.findElements('pubDate').first.text,
              mediaUrl: imageUrl,
              contentType: contentType, // Assign the content type
            ));
          }
        } else {
          print('Failed to fetch feed from $link: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching feed from $link: $e');
      }
    }

    return feeds;
  }

  // Helper function to determine the content type (audio, video, text)
  String _determineContentType(XmlElement item) {
    if (item.findElements('enclosure').isNotEmpty) {
      final enclosure = item.findElements('enclosure').first;
      final type = enclosure.getAttribute('type') ?? '';
      if (type.contains('audio')) {
        return 'audio';
      } else if (type.contains('video')) {
        return 'video';
      }
    }
    // If no media content, treat as text
    return 'text';
  }

  String _removeHtmlTags(String html) {
    final RegExp exp =
        RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return html.replaceAll(exp, '').trim();
  }

  String _truncateDescription(String description) {
    return description.length > 150
        ? '${description.substring(0, 150)}...'
        : description;
  }

  String _extractImageUrl(XmlElement item) {
    final mediaContent = item.findElements('media:content').isNotEmpty
        ? item.findElements('media:content').first.getAttribute('url')
        : null;
    final imageTag = item.findElements('image').isNotEmpty
        ? item.findElements('image').first.text
        : null;
    return mediaContent ?? imageTag ?? '';
  }
}
