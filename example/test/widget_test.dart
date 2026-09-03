import 'package:flutter_test/flutter_test.dart';
import 'package:app_update_check/app_update_check.dart';
import 'package:app_update_check_example/main.dart';

class _FakePlatform extends AppUpdateCheckPlatform {
  const _FakePlatform();

  @override
  Future<LocalAppInfo> getAppInfo() async => const LocalAppInfo(
    version: '1.0.0',
    buildNumber: '1',
    packageName: 'com.example.app',
    installSource: AppInstallSource.development,
  );

  @override
  Future<bool> openUrl(String url) async => true;
}

void main() {
  testWidgets('renders local build info', (WidgetTester tester) async {
    AppUpdate.instance = AppUpdateChecker(
      platform: const _FakePlatform(),
      source: const StaticVersionSource(version: '1.0.0'),
    );
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    expect(find.text('com.example.app'), findsOneWidget);
    expect(find.text('development'), findsOneWidget);
  });
}
