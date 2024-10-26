import 'package:flutter/material.dart';
import '../models/rss_feed.dart';
import '../services/rss_service.dart';
import '../widgets/feed_card.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

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
  final TextEditingController _customNameController = TextEditingController();
  List<String> _rssLinks = [];
  List<String> _customNames = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchFeeds();
    _loadExistingRssLinks();
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
    final rssFile = File('rss_links.txt');
    final nameFile = File('link_name.txt');

    if (await rssFile.exists() && await nameFile.exists()) {
      final links = await rssFile.readAsLines();
      final names = await nameFile.readAsLines();
      setState(() {
        _rssLinks = links;
        _customNames = names;
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
                Expanded(
                  child: ListView.builder(
                    itemCount: _rssLinks.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                            '${_customNames[index]} (${_rssLinks[index]})'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteRssLink(
                                _rssLinks[index], _customNames[index]);
                          },
                        ),
                      );
                    },
                  ),
                ),
                TextField(
                  controller: _customNameController,
                  decoration:
                      const InputDecoration(labelText: 'Enter Custom Name'),
                ),
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
                        await _addRssLink(_rssLinkController.text.trim(),
                            _customNameController.text.trim());
                        _rssLinkController.clear();
                        _customNameController.clear();
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

  Future<void> _addRssLink(String link, String customName) async {
    final rssFile = File('rss_links.txt');
    final nameFile = File('link_name.txt');

    List<String> existingLinks =
        await rssFile.exists() ? await rssFile.readAsLines() : [];
    List<String> existingNames =
        await nameFile.exists() ? await nameFile.readAsLines() : [];

    if (link.isNotEmpty &&
        customName.isNotEmpty &&
        !existingLinks.contains(link)) {
      await rssFile.writeAsString(existingLinks.isEmpty ? link : '\n$link',
          mode: FileMode.append);
      await nameFile.writeAsString(
          existingNames.isEmpty ? customName : '\n$customName',
          mode: FileMode.append);

      await _loadExistingRssLinks();
      _fetchFeeds();
    } else if (link.isEmpty || customName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid RSS link and custom name!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This RSS link is already present!')),
      );
    }
  }

  Future<void> _deleteRssLink(String link, String customName) async {
    final rssFile = File('rss_links.txt');
    final nameFile = File('link_name.txt');

    List<String> links = await rssFile.readAsLines();
    List<String> names = await nameFile.readAsLines();

    links.remove(link);
    names.remove(customName);

    await rssFile.writeAsString(links.join('\n'));
    await nameFile.writeAsString(names.join('\n'));

    await _loadExistingRssLinks();
    _fetchFeeds();
    setState(() {
      _rssLinks.remove(link);
      _customNames.remove(customName);
    });

    Navigator.pop(context);
  }

  void _refreshFeeds() {
    setState(() {
      _allFeeds = [];
      _textFeeds = [];
      _audioFeeds = [];
      _videoFeeds = [];
    });
    _fetchFeeds(); // Re-fetch the feeds
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
          onPressed: _refreshFeeds,
        ),
        title: const Center(
          child: Text(
            'RSS Feed Reader',
            style: TextStyle(fontSize: 30),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.wb_sunny
                  : Icons.nights_stay,
            ),
            onPressed: widget.onToggleTheme,
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
        onPressed: _showAddRssDialog,
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
