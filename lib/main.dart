import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/library_controller.dart';
import 'data/news_repository.dart';
import 'models/news.dart';
import 'widgets/audio_controls.dart';
import 'widgets/news_picture.dart';
import 'widgets/ruby_text.dart';

const appBlue = Color(0xff143e91);
typedef PlayerBuilder = Widget Function(NewsItem news);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final preferences = await SharedPreferences.getInstance();
    runApp(ListeningApp(controller: LibraryController(preferences)));
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('无法读取本地设置'),
                TextButton(onPressed: main, child: const Text('重试')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ListeningApp extends StatelessWidget {
  const ListeningApp({super.key, required this.controller, this.playerBuilder});
  final LibraryController controller;
  final PlayerBuilder? playerBuilder;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '日语听力',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: appBlue),
      scaffoldBackgroundColor: const Color(0xfff5f7fb),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBlue,
        foregroundColor: Colors.white,
      ),
    ),
    home: NewsHome(controller: controller, playerBuilder: playerBuilder),
  );
}

Future<void> openSource(BuildContext context, String url) async {
  try {
    if (!isNhkUrl(url) ||
        !await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        )) {
      throw StateError('Cannot open source');
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('无法打开浏览器，请检查设备设置。')));
    }
  }
}

Future<void> saveAction(
  BuildContext context,
  Future<void> Function() task,
) async {
  try {
    await task();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('本地设置保存失败，请重试。')));
    }
  }
}

class NewsHome extends StatelessWidget {
  const NewsHome({super.key, required this.controller, this.playerBuilder});
  final LibraryController controller;
  final PlayerBuilder? playerBuilder;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final list = controller.visible;
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('日语听力', style: TextStyle(fontSize: 21)),
              Text(
                controller.demo ? '离线演示 · 非 NHK 新闻' : 'NHK NEWS WEB EASY',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: controller.ruby ? '隐藏振假名' : '显示振假名',
              onPressed: controller.saving
                  ? null
                  : () => saveAction(context, controller.toggleRuby),
              icon: Icon(
                controller.ruby ? Icons.text_fields : Icons.text_format,
              ),
            ),
            IconButton(
              tooltip: '刷新新闻',
              onPressed: controller.loading ? null : controller.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (controller.loading) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('演示例文')),
                    ButtonSegment(value: false, label: Text('NHK 新闻')),
                  ],
                  selected: {controller.demo},
                  onSelectionChanged: (value) =>
                      controller.selectSource(value.single),
                ),
              ),
              if (controller.demo)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  child: Text(
                    '内置例文、示意插画和合成语音，仅用于测试。',
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('最新新闻'),
                      selected: !controller.onlySaved,
                      onSelected: (_) => controller.setSavedFilter(false),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: Text('收藏 ${controller.savedCount}'),
                      selected: controller.onlySaved,
                      onSelected: (_) => controller.setSavedFilter(true),
                    ),
                  ],
                ),
              ),
              if (controller.error != null && !controller.onlySaved)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        controller.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      Wrap(
                        children: [
                          TextButton(
                            onPressed: controller.refresh,
                            child: const Text('重试'),
                          ),
                          TextButton(
                            onPressed: () => openSource(context, nhkHome),
                            child: const Text('打开 NHK 官网'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: list.isEmpty ? 1 : list.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (list.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(28),
                          child: Text(
                            controller.onlySaved
                                ? '还没有收藏，点击文章旁的星标保存。'
                                : controller.loading
                                ? '正在读取新闻…'
                                : '暂无新闻。可以重试，或切换到演示例文。',
                          ),
                        );
                      }
                      final news = list[index];
                      void open() => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ArticleScreen(
                            news: news,
                            controller: controller,
                            playerBuilder: playerBuilder,
                          ),
                        ),
                      );
                      return Material(
                        color: Theme.of(context).colorScheme.surface,
                        child: InkWell(
                          key: ValueKey('open-${news.id}'),
                          onTap: open,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 96, child: NewsPicture(news)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RubyText(
                                        news.titleHtml,
                                        showRuby: controller.ruby,
                                        fontSize: 17,
                                        bold: true,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              news.date,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.blueGrey,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            key: ValueKey('save-${news.id}'),
                                            tooltip: controller.isSaved(news)
                                                ? '取消收藏'
                                                : '收藏文章',
                                            onPressed: controller.saving
                                                ? null
                                                : () => saveAction(
                                                    context,
                                                    () => controller
                                                        .toggleSaved(news),
                                                  ),
                                            icon: Icon(
                                              controller.isSaved(news)
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: appBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              TextButton(
                onPressed: () => openSource(context, nhkHome),
                child: const Text('NHK 来源网站 ↗', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({
    super.key,
    required this.news,
    required this.controller,
    this.playerBuilder,
  });
  final NewsItem news;
  final LibraryController controller;
  final PlayerBuilder? playerBuilder;
  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late final Future<NewsItem> _article = widget.controller.repository.article(
    widget.news,
  );
  bool _listening = false;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      return Scaffold(
        appBar: AppBar(
          title: const Text('阅读与听力'),
          actions: [
            IconButton(
              tooltip: c.isSaved(widget.news) ? '取消收藏' : '收藏文章',
              onPressed: c.saving
                  ? null
                  : () => saveAction(context, () => c.toggleSaved(widget.news)),
              icon: Icon(
                c.isSaved(widget.news) ? Icons.star : Icons.star_border,
              ),
            ),
            if (!widget.news.isDemo)
              IconButton(
                tooltip: 'NHK 原文',
                onPressed: () =>
                    openSource(context, widget.news.url ?? nhkHome),
                icon: const Icon(Icons.open_in_new),
              ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: FutureBuilder<NewsItem>(
            future: _article,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('文章读取失败。请检查网络，或打开 NHK 原文。'),
                        TextButton(
                          onPressed: () =>
                              openSource(context, widget.news.url ?? nhkHome),
                          child: const Text('打开原文'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final article = snapshot.data;
              if (article == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Wrap(
                      spacing: 10,
                      children: [
                        FilterChip(
                          selected: _listening,
                          label: Text(_listening ? '显示正文' : '听力模式'),
                          onSelected: (v) => setState(() => _listening = v),
                        ),
                        FilterChip(
                          selected: c.ruby,
                          label: const Text('振假名'),
                          onSelected: c.saving
                              ? null
                              : (_) => saveAction(context, c.toggleRuby),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _listening
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.headphones,
                                    size: 60,
                                    color: appBlue,
                                  ),
                                  SizedBox(height: 20),
                                  Text('先听，再读', style: TextStyle(fontSize: 27)),
                                  SizedBox(height: 12),
                                  Text(
                                    '正文已隐藏，听完后展开原文核对。',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RubyText(
                                  article.titleHtml,
                                  showRuby: c.ruby,
                                  fontSize: 24,
                                  bold: true,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    article.isDemo
                                        ? '练习例文 · 示意图 · 非 NHK 内容'
                                        : article.date,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ),
                                NewsPicture(article, height: 140),
                                const SizedBox(height: 20),
                                RubyText(
                                  article.bodyHtml ?? '',
                                  showRuby: c.ruby,
                                  fontSize: 21,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                  ),
                  if (article.assetAudio != null || article.audioUrl != null)
                    widget.playerBuilder?.call(article) ??
                        AudioControls(
                          article,
                          key: ValueKey('audio-${article.id}'),
                        )
                  else
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('未识别到 NHK 原始音频。'),
                            TextButton(
                              onPressed: () =>
                                  openSource(context, article.url ?? nhkHome),
                              child: const Text('打开原文播放器'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
