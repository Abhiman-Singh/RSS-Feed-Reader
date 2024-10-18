// lib/widgets/feed_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Import the InAppWebView
import '../models/rss_feed.dart';

class FeedCard extends StatelessWidget {
  final RssFeed feed;

  const FeedCard({super.key, required this.feed});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: feed.mediaUrl.isNotEmpty
            ? Image.network(feed.mediaUrl, width: 50, fit: BoxFit.cover)
            : null, // Show the image if available
        title: Text(feed.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(feed.description,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis), // Show description in two lines
            const SizedBox(height: 4.0),
            Text(feed.pubDate,
                style: const TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey)), // Show publication date
          ],
        ),
        onTap: () {
          _showArticleDialog(context, feed.link);
        },
      ),
    );
  }

  // Function to show the dialog with InAppWebView
  void _showArticleDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            children: [
              // Close button on the top right
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              // InAppWebView that displays the article
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(url)),
                  initialOptions: InAppWebViewGroupOptions(
                    crossPlatform: InAppWebViewOptions(
                      useOnDownloadStart: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
