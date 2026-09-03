import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_app_version/lib_app_version.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('lib_app_version');
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
    const MethodChannelLibAppVersion platform = MethodChannelLibAppVersion();
    final LocalAppInfo info = await platform.getAppInfo();
    expect(info.version, '2.0.1');
    expect(info.buildNumber, '7');
    expect(info.packageName, 'com.x.y');
    expect(info.installSource, AppInstallSource.testFlight);
    expect(info.isTestFlight, isTrue);
    expect(log.single.method, 'getAppInfo');
  });

  test('openUrl passes the url', () async {
    const MethodChannelLibAppVersion platform = MethodChannelLibAppVersion();
    expect(await platform.openUrl('market://details?id=a'), isTrue);
    expect(log.single.method, 'openUrl');
    expect(log.single.arguments, <String, Object?>{
      'url': 'market://details?id=a',
    });
  });

  test('the default checker talks to the channel', () async {
    final AppVersionChecker checker = AppVersionChecker(
      source: const StaticVersionSource(version: '1.0.0'),
    );
    expect(await checker.isTestFlight(), isTrue);
  });
}
