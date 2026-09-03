// Runs on a real device / emulator:
//   cd example && flutter test integration_test
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lib_app_version/lib_app_version.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native getAppInfo returns this build', (
    WidgetTester tester,
  ) async {
    final LocalAppInfo info = await AppVersion.getLocalInfo();
    expect(info.version, isNotEmpty);
    expect(info.buildNumber, isNotEmpty);
    expect(info.packageName, isNotEmpty);
    expect(info.installSource, isNot(AppInstallSource.unknown));
  });
}
