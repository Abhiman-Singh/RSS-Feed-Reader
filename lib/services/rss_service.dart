import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import '../models/rss_feed.dart';

class RssService {
  Future<List<RssFeed>> fetchRssFeeds() async {
    final List<RssFeed> feeds = [];
    final Set<String> uniqueTitles = {}; // Set to track unique titles
    final Set<String> uniqueLinks = {}; // Set to track unique links
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
            // Get the title and clean HTML tags
            String rawTitle = item.findElements('title').first.text;
            String cleanTitle = _removeHtmlTags(rawTitle).trim();

            // Get and clean the description, limit to 150 characters
            String rawDescription = item.findElements('description').isNotEmpty
                ? item.findElements('description').first.text
                : '';
            String cleanDescription =
                _truncateDescription(_removeHtmlTags(rawDescription));

            // Extract the image URL
            String imageUrl = _extractImageUrl(item);

            // Determine content type (audio, video, text)
            String contentType = _determineContentType(item);

            // Parse the pubDate to DateTime object
            String pubDateStr = item.findElements('pubDate').first.text;
            DateTime dateTime = _parsePubDate(pubDateStr);

            // Check for uniqueness based on title and link
            String feedLink = item.findElements('link').first.text;

            // Check for duplicates by title or link
            if (!uniqueTitles.contains(cleanTitle) &&
                !uniqueLinks.contains(feedLink)) {
              uniqueTitles
                  .add(cleanTitle); // Add title to the set of unique titles
              uniqueLinks.add(feedLink); // Add link to the set of unique links
              feeds.add(RssFeed(
                title: cleanTitle,
                link: feedLink,
                description: cleanDescription,
                pubDate: pubDateStr,
                mediaUrl: imageUrl,
                contentType: contentType,
                dateTime: dateTime, // Assign the parsed dateTime
              ));
            }
          }
        } else {
          print('Failed to fetch feed from $link: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching feed from $link: $e');
      }
    }

    // Sort the feeds by the parsed DateTime in descending order (newest first)
    feeds.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return feeds;
  }

  // Helper function to parse the pubDate string into DateTime
  DateTime _parsePubDate(String pubDateStr) {
    // Example date format: "Mon, 20 Oct 2024 14:00:00 GMT"
    final dateFormat = DateFormat('EEE, dd MMM yyyy HH:mm:ss Z');
    return dateFormat.parse(pubDateStr);
  }

  // Enhanced content type determination
  String _determineContentType(XmlElement item) {
    // Check for media:content tag, which is commonly used for audio/video
    if (item.findElements('media:content').isNotEmpty) {
      final enclosure = item.findElements('media:content').first;
      final type = enclosure.getAttribute('type') ?? '';
      if (type.contains('video')) {
        return 'video';
      } else if (type.contains('audio')) {
        return 'audio';
      }
    }

    // Check for enclosure tags as a secondary method
    if (item.findElements('enclosure').isNotEmpty) {
      final enclosure = item.findElements('enclosure').first;
      final type = enclosure.getAttribute('type') ?? '';
      if (type.contains('video')) {
        return 'video';
      } else if (type.contains('audio')) {
        return 'audio';
      }
    }

    // Check for audio or video URLs in the link
    String link = item.findElements('link').first.text;
    if (link.contains('youtube.com') || link.contains('vimeo.com')) {
      return 'video';
    } else if (link.contains('soundcloud.com') ||
        link.contains('spotify.com')) {
      return 'audio';
    }

    // If no specific media is found, treat as text
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
    // Attempt to extract the image URL from various possible sources
    final mediaContent = item.findElements('media:content').isNotEmpty
        ? item.findElements('media:content').first.getAttribute('url')
        : null;

    final imageTag = item.findElements('image').isNotEmpty
        ? item.findElements('image').first.text
        : null;

    final enclosure = item.findElements('enclosure').isNotEmpty
        ? item.findElements('enclosure').first.getAttribute('url')
        : null;

    // Check for images in the description (common in RSS feeds)
    final descriptionImages = _extractImagesFromDescription(item);

    // Return the first available image, prioritizing mediaContent, imageTag, enclosure, and then description images
    return mediaContent ??
        imageTag ??
        enclosure ??
        (descriptionImages.isNotEmpty ? descriptionImages.first : '');
  }

  // Helper function to extract image URLs from the description if present
  List<String> _extractImagesFromDescription(XmlElement item) {
    final description = item.findElements('description').isNotEmpty
        ? item.findElements('description').first.text
        : '';

    final RegExp imgRegExp =
        RegExp(r'<img[^>]+src="([^">]+)"', caseSensitive: false);
    final matches = imgRegExp.allMatches(description);

    return matches.map((match) => match.group(1)!).toList();
  }
}
