import 'package:flutter_test/flutter_test.dart';
import 'package:lib_app_version/lib_app_version.dart';
import 'package:lib_app_version_example/main.dart';

class _FakePlatform extends LibAppVersionPlatform {
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
    AppVersion.instance = AppVersionChecker(
      platform: const _FakePlatform(),
      source: const StaticVersionSource(version: '1.0.0'),
    );
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    expect(find.text('com.example.app'), findsOneWidget);
    expect(find.text('development'), findsOneWidget);
  });
}
