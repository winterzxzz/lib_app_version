import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_update_check/app_update_check.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('app_update_check');
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          log.add(call);
          switch (call.method) {
            case 'getAppInfo':
              return <String, Object?>{
                'version': '2.0.1',
                'buildNumber': 7,
                'packageName': 'com.x.y',
                'installSource': 'testflight',
              };
            case 'openUrl':
              return true;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getAppInfo decodes the native map', () async {
    const MethodChannelAppUpdateCheck platform = MethodChannelAppUpdateCheck();
    final LocalAppInfo info = await platform.getAppInfo();
    expect(info.version, '2.0.1');
    expect(info.buildNumber, '7');
    expect(info.packageName, 'com.x.y');
    expect(info.installSource, AppInstallSource.testFlight);
    expect(info.isTestFlight, isTrue);
    expect(log.single.method, 'getAppInfo');
  });

  test('openUrl passes the url', () async {
    const MethodChannelAppUpdateCheck platform = MethodChannelAppUpdateCheck();
    expect(await platform.openUrl('market://details?id=a'), isTrue);
    expect(log.single.method, 'openUrl');
    expect(log.single.arguments, <String, Object?>{
      'url': 'market://details?id=a',
    });
  });

  test('the default checker talks to the channel', () async {
    final AppUpdateChecker checker = AppUpdateChecker(
      source: const StaticVersionSource(version: '1.0.0'),
    );
    expect(await checker.isTestFlight(), isTrue);
  });
}
