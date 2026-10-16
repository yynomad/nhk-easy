import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/news.dart';
import 'demo_news.dart';
import 'news_repository.dart';

class LibraryController extends ChangeNotifier {
  LibraryController(this.preferences, {NewsRepository? repository})
    : repository = repository ?? NewsRepository() {
    ruby = preferences.getBool('ruby') ?? true;
    for (final value in preferences.getStringList('saved_news') ?? <String>[]) {
      try {
        final news = NewsItem.fromJson(
          jsonDecode(value) as Map<String, dynamic>,
        );
        if (news.id.isNotEmpty) _saved[news.id] = news;
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
  }
  final SharedPreferences preferences;
  final NewsRepository repository;
  bool ruby = true;
  bool demo = true;
  bool onlySaved = false;
  bool loading = false;
  bool saving = false;
  String? error;
  List<NewsItem> latest = List.of(demoNews);
  final Map<String, NewsItem> _saved = {};
  int _request = 0;
  bool _disposed = false;

  List<NewsItem> get visible =>
      List.unmodifiable(onlySaved ? _saved.values : latest);
  int get savedCount => _saved.length;
  bool isSaved(NewsItem news) => _saved.containsKey(news.id);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void setSavedFilter(bool value) {
    onlySaved = value;
    _notify();
  }

  Future<void> selectSource(bool useDemo) async {
    if (useDemo == demo) return;
    demo = useDemo;
    onlySaved = false;
    latest = [];
    error = null;
    _request++;
    loading = false;
    await refresh();
  }

  Future<void> refresh() async {
    if (loading) return;
    final request = ++_request;
    loading = true;
    error = null;
    _notify();
    try {
      final result = demo
          ? List<NewsItem>.of(demoNews)
          : await repository.list(force: true);
      if (_disposed || request != _request) return;
      latest = result;
    } catch (e) {
      if (_disposed || request != _request) return;
      error = e is SourceUnavailable ? e.message : '无法获取新闻，请检查网络或打开 NHK 官网。';
    } finally {
      if (!_disposed && request == _request) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> toggleRuby() async {
    if (saving) return;
    saving = true;
    _notify();
    try {
      final next = !ruby;
      if (!await preferences.setBool('ruby', next)) throw Exception('无法保存假名设置');
      ruby = next;
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<void> toggleSaved(NewsItem item) async {
    if (saving) return;
    saving = true;
    _notify();
    final next = Map<String, NewsItem>.of(_saved);
    if (next.containsKey(item.id)) {
      next.remove(item.id);
    } else {
      next[item.id] = item;
    }
    try {
      final stored = next.values.map((n) => jsonEncode(n.toJson())).toList();
      if (!await preferences.setStringList('saved_news', stored)) {
        throw Exception('无法保存收藏');
      }
      _saved
        ..clear()
        ..addAll(next);
    } finally {
      saving = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    repository.close();
    super.dispose();
  }
}
