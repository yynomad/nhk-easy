import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nhk_easy/data/news_repository.dart';
import 'package:nhk_easy/models/news.dart';

const fixture =
    '<ul><li><a href="/news/easy/ne123/ne123.html"><img src="/news/easy/ne123/photo.jpg"><h2><ruby>日本<rt>にほん</rt></ruby>のニュース</h2><time>10月16日</time></a></li></ul>';
void main() {
  test('accepts only HTTPS NHK origins', () {
    expect(isNhkUrl(nhkHome), isTrue);
    for (final url in [
      'http://news.web.nhk/',
      'https://news.web.nhk.evil.test/',
      'https://user@news.web.nhk/',
      'https://news.web.nhk:444/',
      'javascript:alert(1)',
    ]) {
      expect(isNhkUrl(url), isFalse, reason: url);
    }
  });
  test('extracts ruby, image and date without duplicating news', () {
    final news = parseNewsList(fixture + fixture).single;
    expect(plainTitle(news.titleHtml), '日本のニュース');
    expect(news.titleHtml, contains('<rt>にほん</rt>'));
    expect(news.imageUrl, 'https://news.web.nhk/news/easy/ne123/photo.jpg');
    expect(news.date, '10月16日');
  });
  test('reports NHK usage confirmation instead of fabricated news', () {
    expect(
      () => parseNewsList('<main><h2>ご利用にあたって</h2><p>内容について確認しました</p></main>'),
      throwsA(
        isA<SourceUnavailable>().having(
          (e) => e.message,
          'message',
          contains('使用确认'),
        ),
      ),
    );
  });
  test('strips active markup and can hide readings', () {
    const source =
        '<p onclick="bad()"><ruby>日本<rt>にほん</rt></ruby><script>bad()</script><img src="bad"></p>';
    expect(cleanHtml(source), contains('<rt>にほん</rt>'));
    expect(cleanHtml(source), isNot(contains('onclick')));
    expect(cleanHtml(source), isNot(contains('script')));
    expect(cleanHtml(source), isNot(contains('<img')));
    expect(cleanHtml(source, ruby: false), isNot(contains('にほん')));
  });
  test('only uses explicit audio URLs', () {
    const news = NewsItem(
      id: 'x',
      url: 'https://news.web.nhk/news/easy/ne123/ne123.html',
      titleHtml: '例文',
    );
    expect(
      parseArticle(
        '<div id="js-article-body">本文</div><audio src="sound.m3u8"></audio>',
        news,
      ).audioUrl,
      'https://news.web.nhk/news/easy/ne123/sound.m3u8',
    );
    expect(
      parseArticle('<div id="js-article-body">本文</div>', news).audioUrl,
      isNull,
    );
    expect(
      () => parseArticle('<main>Unknown</main>', news),
      throwsA(isA<SourceUnavailable>()),
    );
  });
  test('caches news and refresh bypasses cache', () async {
    var calls = 0;
    final r = NewsRepository(
      client: MockClient((_) async {
        calls++;
        return http.Response(
          fixture,
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      }),
    );
    addTearDown(r.close);
    await r.list();
    await r.list();
    expect(calls, 1);
    await r.list(force: true);
    expect(calls, 2);
  });
  test('rejects external redirects before making a second request', () async {
    var calls = 0;
    final r = NewsRepository(
      client: MockClient((_) async {
        calls++;
        return http.Response(
          '',
          302,
          headers: {'location': 'https://evil.test/'},
        );
      }),
    );
    addTearDown(r.close);
    await expectLater(r.list(), throwsA(isA<SourceUnavailable>()));
    expect(calls, 1);
  });
}
