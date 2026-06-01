import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My News',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const NewsPage(),
    );
  }
}

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final List<NewsModel> news = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Load static news.json from the app assets
      final String response = await rootBundle.loadString('assets/news.json');
      final List<dynamic> data = json.decode(response);
      
      setState(() {
        news.clear();
        news.addAll(data.map((e) => NewsModel.fromJson(e)).toList());
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load news feed. Please try again later.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My News'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : news.isEmpty
                  ? const Center(
                      child: Text('No news articles found.'),
                    )
                  : GroupedListView<NewsModel, String>(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elements: news,
                      groupBy: (element) =>
                          DateFormat('dd MMMM yyyy').format(element.createdAt),
                      groupSeparatorBuilder: (String groupByValue) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          groupByValue,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      itemBuilder: (context, NewsModel element) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                element.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                element.summary,
                                style: const TextStyle(fontSize: 14, height: 1.4),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Source: ${element.source}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('jm').format(element.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      useStickyGroupSeparators: true,
                      floatingHeader: false,
                      order: GroupedListOrder.DESC,
                    ),
    );
  }
}

class NewsModel {
  NewsModel({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.summary,
    required this.source,
  });

  final int id;
  final DateTime createdAt;
  final String title;
  final String summary;
  final String source;

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      title: json['title'],
      summary: json['summary'],
      source: json['source'],
    );
  }
}
