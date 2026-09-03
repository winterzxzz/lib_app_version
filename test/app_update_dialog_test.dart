import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_update_check/app_update_check.dart';

import 'helpers.dart';

void main() {
  // Note: `defaultTargetPlatform` is Android under `flutter test`, so the
  // checker builds Play Store links. The dialog itself follows the theme.

  /// Pumps a page with a button that triggers [checker.showUpdateDialogIfNeeded]
  /// and taps it. The returned list receives the status once the call
  /// completes, i.e. after the dialog has been dismissed (or right away when
  /// no dialog was needed).
  Future<List<AppUpdateStatus>> pumpAndTrigger(
    WidgetTester tester,
    AppUpdateChecker checker, {
    bool force = false,
    AppUpdateDialogTexts texts = const AppUpdateDialogTexts(),
    AppUpdateDialogBuilder? builder,
    bool showReleaseNotes = false,
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    final List<AppUpdateStatus> results = <AppUpdateStatus>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: platform),
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => ElevatedButton(
              onPressed: () async {
                results.add(
                  await checker.showUpdateDialogIfNeeded(
                    context,
                    force: force,
                    texts: texts,
                    builder: builder,
                    showReleaseNotes: showReleaseNotes,
                  ),
                );
              },
              child: const Text('trigger'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('shows an optional dialog and Later dismisses it', (
    WidgetTester tester,
  ) async {
    final FakePlatform platform = FakePlatform();
    final AppUpdateChecker checker = AppUpdateChecker(
      platform: platform,
      source: const StaticVersionSource(
        version: '1.3.0',
        releaseNotes: 'Shiny',
      ),
    );
    final List<AppUpdateStatus> results = await pumpAndTrigger(
      tester,
      checker,
      showReleaseNotes: true,
    );

    expect(find.text('Update available'), findsOneWidget);
    expect(
      find.text('Version 1.3.0 is available. You are using 1.2.0.'),
      findsOneWidget,
    );
    expect(find.text('Shiny'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(results, isEmpty, reason: 'call completes only once dismissed');

    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.text('Update available'), findsNothing);
    expect(platform.openedUrls, isEmpty);
    expect(results.single.isUpdateAvailable, isTrue);
  });

  testWidgets('Update opens the store and closes an optional dialog', (
    WidgetTester tester,
  ) async {
    final FakePlatform platform = FakePlatform();
    final AppUpdateChecker checker = AppUpdateChecker(
      platform: platform,
      source: const StaticVersionSource(version: '1.3.0'),
    );
    final List<AppUpdateStatus> results = await pumpAndTrigger(tester, checker);

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(platform.openedUrls.first, 'market://details?id=com.example.app');
    expect(find.text('Update available'), findsNothing);
    expect(results.single.updateType, AppUpdateType.optional);
  });

  testWidgets('force makes the dialog mandatory', (WidgetTester tester) async {
    final FakePlatform platform = FakePlatform();
    final AppUpdateChecker checker = AppUpdateChecker(
      platform: platform,
      source: const StaticVersionSource(version: '1.3.0'),
    );
    await pumpAndTrigger(tester, checker, force: true);

    expect(find.text('Later'), findsNothing);
    expect(find.text('Update'), findsOneWidget);

    // Back navigation is swallowed by the PopScope.
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Update available'), findsOneWidget);

    // Tapping the barrier does nothing either.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Update available'), findsOneWidget);

    // Update opens the store but keeps the dialog.
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(platform.openedUrls, isNotEmpty);
    expect(find.text('Update available'), findsOneWidget);
  });

  testWidgets('minimumVersion makes the dialog mandatory', (
    WidgetTester tester,
  ) async {
    final AppUpdateChecker checker = AppUpdateChecker(
      minimumVersion: '1.2.5',
      platform: FakePlatform(),
      source: const StaticVersionSource(version: '1.3.0'),
    );
    await pumpAndTrigger(tester, checker);
    expect((await checker.check()).updateType, AppUpdateType.required);
    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
  });

  testWidgets('nothing is shown when up to date', (WidgetTester tester) async {
    final AppUpdateChecker checker = AppUpdateChecker(
      platform: FakePlatform(),
      source: const StaticVersionSource(version: '1.2.0'),
    );
    final List<AppUpdateStatus> results = await pumpAndTrigger(
      tester,
      checker,
      force: true,
    );
    expect(results.single.shouldUpdate, isFalse);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('does not open a second dialog while one is visible', (
    WidgetTester tester,
  ) async {
    final AppUpdateChecker checker = AppUpdateChecker(
      platform: FakePlatform(),
      source: const StaticVersionSource(version: '1.3.0'),
    );
    await pumpAndTrigger(tester, checker);
    expect(find.text('Update available'), findsOneWidget);
    // The button sits behind the dialog; call the API directly instead.
    final BuildContext context = tester.element(find.byType(Scaffold));
    await checker.showUpdateDialogIfNeeded(context);
    await tester.pumpAndSettle();
    expect(find.text('Update available'), findsOneWidget);
  });

  testWidgets('custom texts are used', (WidgetTester tester) async {
    final AppUpdateChecker checker = AppUpdateChecker(
      platform: FakePlatform(),
      source: const StaticVersionSource(version: '1.3.0'),
    );
    await pumpAndTrigger(
      tester,
      checker,
      texts: const AppUpdateDialogTexts(
        title: 'Có bản mới',
        message: 'Cập nhật để dùng tính năng mới nhé',
        updateButton: 'Cập nhật',
        laterButton: 'Để sau',
      ),
    );
    expect(find.text('Có bản mới'), findsOneWidget);
    expect(find.text('Cập nhật để dùng tính năng mới nhé'), findsOneWidget);
    expect(find.text('Cập nhật'), findsOneWidget);
    expect(find.text('Để sau'), findsOneWidget);
  });

  testWidgets('custom builder replaces the default dialog', (
    WidgetTester tester,
  ) async {
    final FakePlatform platform = FakePlatform();
    final AppUpdateChecker checker = AppUpdateChecker(
      platform: platform,
      source: const StaticVersionSource(version: '1.3.0'),
    );
    await pumpAndTrigger(
      tester,
      checker,
      builder:
          (
            BuildContext context,
            AppUpdateStatus status,
            bool mandatory,
            Future<bool> Function() openStore,
          ) {
            return Dialog(
              child: TextButton(
                onPressed: openStore,
                child: Text(
                  'custom ${status.storeVersion} ${mandatory ? 'must' : 'may'}',
                ),
              ),
            );
          },
    );
    expect(find.text('custom 1.3.0 may'), findsOneWidget);
    expect(find.text('Update available'), findsNothing);
    await tester.tap(find.text('custom 1.3.0 may'));
    await tester.pumpAndSettle();
    expect(platform.openedUrls, isNotEmpty);
  });

  testWidgets('uses Cupertino widgets on iOS', (WidgetTester tester) async {
    final AppUpdateChecker checker = AppUpdateChecker(
      platform: FakePlatform(info: iosInfo),
      source: const StaticVersionSource(version: '1.3.0'),
    );
    await pumpAndTrigger(tester, checker, platform: TargetPlatform.iOS);
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.byType(CupertinoDialogAction), findsNWidgets(2));
  });
}
