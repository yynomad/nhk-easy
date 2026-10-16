import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nhk_easy/data/library_controller.dart';
import 'package:nhk_easy/data/news_repository.dart';
import 'package:nhk_easy/data/demo_news.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'saved article metadata and ruby survive controller recreation',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final c = LibraryController(prefs);
      addTearDown(c.dispose);
      await c.toggleSaved(demoNews.first);
      await c.toggleRuby();
      final restored = LibraryController(prefs);
      addTearDown(restored.dispose);
      expect(restored.ruby, isFalse);
      restored.setSavedFilter(true);
      expect(restored.visible.single.id, demoNews.first.id);
      await restored.toggleSaved(demoNews.first);
      expect(restored.visible, isEmpty);
    },
  );
  test('ignores malformed saved records', () async {
    SharedPreferences.setMockInitialValues({
      'saved_news': ['not json', '{}'],
    });
    final c = LibraryController(await SharedPreferences.getInstance());
    addTearDown(c.dispose);
    expect(c.savedCount, 0);
  });
  test('switching back to demo ignores a late NHK response', () async {
    final response = Completer<http.Response>();
    final repo = NewsRepository(client: MockClient((_) => response.future));
    final c = LibraryController(
      await SharedPreferences.getInstance(),
      repository: repo,
    );
    addTearDown(c.dispose);
    final pending = c.selectSource(false);
    await c.selectSource(true);
    response.complete(
      http.Response(
        '<main>ご利用にあたって</main>',
        200,
        headers: {'content-type': 'text/html; charset=utf-8'},
      ),
    );
    await pending;
    expect(c.demo, isTrue);
    expect(c.error, isNull);
    expect(c.visible.length, 3);
  });
}
