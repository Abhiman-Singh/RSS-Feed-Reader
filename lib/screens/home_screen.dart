// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/rss_feed.dart';
import '../services/rss_service.dart';
import '../widgets/feed_card.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme; // Function to toggle theme

  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RssFeed> _allFeeds = [];
  List<RssFeed> _textFeeds = [];
  List<RssFeed> _audioFeeds = [];
  List<RssFeed> _videoFeeds = [];
  final TextEditingController _rssLinkController = TextEditingController();
  List<String> _rssLinks = []; // List to hold existing RSS links

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchFeeds();
    _loadExistingRssLinks(); // Load existing links when initializing
  }

  Future<void> _fetchFeeds() async {
    final rssService = RssService();
    List<RssFeed> feeds = await rssService.fetchRssFeeds();
    setState(() {
      _allFeeds = feeds;
      _textFeeds = feeds.where((feed) => feed.contentType == 'text').toList();
      _audioFeeds = feeds.where((feed) => feed.contentType == 'audio').toList();
      _videoFeeds = feeds.where((feed) => feed.contentType == 'video').toList();
    });
  }

  Future<void> _loadExistingRssLinks() async {
    final file = File('rss_links.txt');

    // Check if the file exists
    if (await file.exists()) {
      // Read existing RSS links
      final links = await file.readAsLines();
      setState(() {
        _rssLinks = links; // Store the links in the list
      });
    }
  }

  void _showAddRssDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New RSS Link'),
          content: SizedBox(
            width: 700,
            height: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display existing RSS links with delete buttons
                Expanded(
                  child: ListView.builder(
                    itemCount: _rssLinks.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_rssLinks[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteRssLink(
                                _rssLinks[index]); // Close dialog after delete
                          },
                        ),
                      );
                    },
                  ),
                ),
                // Input field for new RSS link
                TextField(
                  controller: _rssLinkController,
                  decoration:
                      const InputDecoration(labelText: 'Enter RSS Feed Link'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        // Save the new RSS link
                        await _addRssLink(_rssLinkController.text.trim());
                        _rssLinkController.clear();
                        Navigator.pop(context);
                      },
                      child: const Text('Add'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addRssLink(String link) async {
    final file = File('rss_links.txt');

    // Read existing links to check for duplicates
    List<String> existingLinks = await file.readAsLines();

    // Check if the link already exists
    if (!existingLinks.contains(link) && link.isNotEmpty) {
      // Check if the file is empty
      String formattedLink;
      if (existingLinks.isEmpty) {
        // If empty, just use the link without a newline
        formattedLink = link;
      } else {
        // If not empty, prepend a newline character
        formattedLink = '\n$link';
      }

      // Append the new link to the file
      await file.writeAsString(formattedLink, mode: FileMode.append);

      // Refresh the existing links
      await _loadExistingRssLinks();

      // Fetch feeds again to include the new link
      _fetchFeeds();
    } else if (link.isEmpty) {
      // Show a message if the link is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid RSS link!')),
      );
    } else {
      // Show a message if the link already exists
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This RSS link is already present!')),
      );
    }
  }

  Future<void> _deleteRssLink(String link) async {
    final file = File('rss_links.txt');

    // Read all lines in the file
    List<String> lines = await file.readAsLines();

    // Remove the specified link
    lines.remove(link);

    // Write the updated list back to the file
    await file.writeAsString(lines.join('\n'));

    // Refresh the existing links and feeds
    await _loadExistingRssLinks();
    _fetchFeeds();

    // Remove the link from the displayed list immediately
    setState(() {
      _rssLinks.remove(link);
    });

    // Close the dialog after deletion
    Navigator.pop(context);
  }

  void _refreshFeeds() {
    // Refresh the feeds manually
    _fetchFeeds();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feeds refreshed!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshFeeds, // Refresh feeds when tapped
        ),
        title: const Center(
          child: Text(
            'RSS Feed Reader',
            style: TextStyle(
              fontSize: 30, // Adjust font size as needed
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.wb_sunny
                  : Icons.nights_stay,
            ),
            onPressed: widget.onToggleTheme, // Toggle theme
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Text'),
            Tab(text: 'Audio'),
            Tab(text: 'Video'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedList(_textFeeds),
          _buildFeedList(_audioFeeds),
          _buildFeedList(_videoFeeds),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRssDialog, // Show dialog to add new RSS link
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFeedList(List<RssFeed> feeds) {
    if (feeds.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: feeds.length,
      itemBuilder: (context, index) {
        return FeedCard(feed: feeds[index]);
      },
    );
  }
}
