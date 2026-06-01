import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Configuration Error:\nSUPABASE_URL or SUPABASE_ANON_KEY is not defined.\n\n'
                'Please run your app using:\n'
                'flutter run --dart-define-from-file=.env.json',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16, height: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My News',
      theme: ThemeData(),
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
  final SupabaseClient supabase = Supabase.instance.client;

  final int fetchRange = 10;

  int currentOffset = 0;
  final List<NewsModel> news = [];

  bool hasMore = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    if (!hasMore) return;

    final data = await supabase
        .from('news')
        .select()
        .range(
          currentOffset,
          (currentOffset += fetchRange) - 1,
        ); // range is inclusive (include all in range) - set currentOffset value for next fetch while have a correct range of item this time

    setState(() {
      news.addAll(data.map((e) => NewsModel.fromJson(e)).toList());
    });

    if (data.length < fetchRange) {
      hasMore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GroupedListView<NewsModel, String>(
            shrinkWrap: true,
            elements: news,
            groupBy: (element) =>
                DateFormat('dd MM yyyy').format(element.createdAt),
            groupSeparatorBuilder: (String groupByValue) => Text(
              groupByValue,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey),
            ),
            itemBuilder: (context, NewsModel element) => Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      element.title,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(element.summary),
                    Text('source: ${element.source}'),
                  ],
                ),
              ),
            ),
            useStickyGroupSeparators: true, // optional
            floatingHeader: true, // optional
            order: GroupedListOrder.DESC, // optiona
          ),
          if (news.isNotEmpty && hasMore)
            ElevatedButton(
              onPressed: () {
                _fetchData();
              },
              child: Text('Load more'),
            ),
        ],
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
