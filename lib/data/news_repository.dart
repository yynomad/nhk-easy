import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

import '../models/news.dart';

const nhkHome = 'https://news.web.nhk/news/easy/';

class SourceUnavailable implements Exception {
  const SourceUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

bool isNhkUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      (uri.hasPort && uri.port != 443)) {
    return false;
  }
  final host = uri.host.toLowerCase();
  return host.endsWith('.nhk') ||
      host == 'nhk.or.jp' ||
      host.endsWith('.nhk.or.jp');
}

String? resolveNhk(String? value, String base) {
  if (value == null || value.trim().isEmpty) return null;
  try {
    final url = Uri.parse(base).resolve(value).toString();
    return isNhkUrl(url) ? url : null;
  } on FormatException {
    return null;
  }
}

String cleanHtml(String source, {bool ruby = true}) {
  final fragment = html.parseFragment(source);
  const allowed = {'ruby', 'rt', 'rp', 'p', 'br', 'span', 'b', 'strong', 'em'};
  for (final node in fragment.querySelectorAll('*').reversed.toList()) {
    if ([
          'script',
          'style',
          'iframe',
          'object',
          'img',
        ].contains(node.localName) ||
        (!ruby && ['rt', 'rp'].contains(node.localName))) {
      node.remove();
    } else if (!allowed.contains(node.localName)) {
      final parent = node.parentNode;
      if (parent != null) {
        final index = parent.nodes.indexOf(node);
        final children = node.nodes.toList();
        node.remove();
        parent.nodes.insertAll(index, children);
      }
    } else {
      node.attributes.clear();
    }
  }
  return fragment.outerHtml;
}

String plainTitle(String source) =>
    html.parseFragment(cleanHtml(source, ruby: false)).text?.trim() ?? '';

List<NewsItem> parseNewsList(String source, {String base = nhkHome}) {
  final doc = html.parse(source);
  final result = <String, NewsItem>{};
  for (final link in doc.querySelectorAll('a[href]')) {
    final url = resolveNhk(link.attributes['href'], base);
    if (url == null ||
        !RegExp(r'^/news/easy/[^/]+/[^/]+\.html$')
            .hasMatch(Uri.parse(url).path)) {
      continue;
    }
    Element container = link;
    for (
      Element? parent = link.parent;
      parent != null;
      parent = parent.parent
    ) {
      if (['li', 'article'].contains(parent.localName) ||
          parent.classes.contains('news-list__item')) {
        container = parent;
        break;
      }
    }
    final heading =
        container.querySelector(
          'h1, h2, h3, .news-list__title, .news-list__item-title',
        ) ??
        link;
    if (plainTitle(heading.innerHtml).isEmpty) continue;
    final image = container.querySelector('img');
    result.putIfAbsent(
      url,
      () => NewsItem(
        id: url,
        url: url,
        titleHtml: cleanHtml(heading.innerHtml),
        imageUrl:
            resolveNhk(image?.attributes['data-src'], base) ??
            resolveNhk(image?.attributes['src'], base),
        date:
            container
                .querySelector('time, .news-list__time, .news-list__item-date')
                ?.text
                .trim() ??
            '',
      ),
    );
  }
  if (result.isEmpty && doc.body?.text.contains('ご利用にあたって') == true) {
    throw const SourceUnavailable(
      'NHK 返回了使用确认页面，暂时无法读取新闻。请在 NHK 官网查看；你仍可切回演示模式测试功能。',
    );
  }
  if (result.isEmpty) {
    throw const SourceUnavailable('未识别到新闻列表，来源页面可能已更改。请在 NHK 官网查看。');
  }
  return result.values.toList();
}

NewsItem parseArticle(String source, NewsItem news) {
  final doc = html.parse(source);
  final body = doc.querySelector(
    '#js-article-body, .article-main__body, .article-body',
  );
  if (body == null) throw const SourceUnavailable('未识别到正文。请点击原文，在 NHK 官网查看。');
  String? audio;
  for (final node in doc.querySelectorAll(
    'audio[src], audio source[src], a[href]',
  )) {
    final url = resolveNhk(
      node.attributes[node.localName == 'a' ? 'href' : 'src'],
      news.url ?? nhkHome,
    );
    if (url != null &&
        RegExp(
          r'\.(mp3|m3u8|m4a)$',
          caseSensitive: false,
        ).hasMatch(Uri.parse(url).path)) {
      audio = url;
      break;
    }
  }
  return news.withArticle(cleanHtml(body.innerHtml), audio);
}

class NewsRepository {
  NewsRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  List<NewsItem>? _cache;
  DateTime? _fetched;

  Future<List<NewsItem>> list({bool force = false}) async {
    if (!force &&
        _cache != null &&
        _fetched != null &&
        DateTime.now().difference(_fetched!) < const Duration(minutes: 5)) {
      return List.unmodifiable(_cache!);
    }
    final news = parseNewsList(await _fetch(nhkHome));
    _cache = news;
    _fetched = DateTime.now();
    return news;
  }

  Future<NewsItem> article(NewsItem item) async {
    if (item.isDemo) return item;
    return parseArticle(await _fetch(item.url ?? nhkHome), item);
  }

  Future<String> _fetch(String url) async {
    var current = url;
    for (var i = 0; i < 5; i++) {
      if (!isNhkUrl(current)) throw const SourceUnavailable('不支持的来源地址');
      final request = http.Request('GET', Uri.parse(current))
        ..followRedirects = false;
      request.headers['User-Agent'] = 'EasyListening/0.3';
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode >= 300 && response.statusCode < 400) {
        final next = resolveNhk(response.headers['location'], current);
        await response.stream.drain<void>().timeout(
          const Duration(seconds: 20),
        );
        if (next == null) throw const SourceUnavailable('来源跳转到不支持的网站');
        current = next;
        continue;
      }
      if (response.statusCode != 200) {
        await response.stream.drain<void>().timeout(
          const Duration(seconds: 20),
        );
        throw SourceUnavailable('NHK 返回 HTTP ${response.statusCode}，请稍后重试。');
      }
      final bytes = <int>[];
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 20),
      )) {
        bytes.addAll(chunk);
        if (bytes.length > 2 * 1024 * 1024) {
          throw const SourceUnavailable('来源页面过大');
        }
      }
      return utf8.decode(bytes);
    }
    throw const SourceUnavailable('来源跳转次数过多');
  }

  void close() => _client.close();
}
