import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nhk_easy/data/library_controller.dart';
import 'package:nhk_easy/main.dart';

void main() {
  testWidgets('demo opens, hides text, saves and restores to saved list', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final c = LibraryController(await SharedPreferences.getInstance());
    addTearDown(c.dispose);
    await tester.pumpWidget(
      ListeningApp(
        controller: c,
        playerBuilder: (_) => const SizedBox(height: 100, child: Text('测试播放器')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-demo-sakura')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save-demo-sakura')));
    await tester.pumpAndSettle();
    expect(c.savedCount, 1);
    await tester.tap(find.byKey(const ValueKey('open-demo-sakura')));
    await tester.pumpAndSettle();
    expect(find.text('阅读与听力'), findsOneWidget);
    await tester.tap(find.text('听力模式'));
    await tester.pumpAndSettle();
    expect(find.text('先听，再读'), findsOneWidget);
    await tester.tap(find.text('振假名'));
    await tester.pumpAndSettle();
    expect(c.ruby, isFalse);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('收藏 1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-demo-station')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('small phone layout has no overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final c = LibraryController(await SharedPreferences.getInstance());
    addTearDown(c.dispose);
    await tester.pumpWidget(
      ListeningApp(
        controller: c,
        playerBuilder: (_) => const SizedBox(height: 100),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('open-demo-sakura')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
