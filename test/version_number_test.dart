import 'package:flutter_test/flutter_test.dart';
import 'package:app_update_check/app_update_check.dart';

void main() {
  group('VersionNumber.parse', () {
    test('reads dotted numbers', () {
      final VersionNumber v = VersionNumber.parse('1.2.3');
      expect(v.components, <int>[1, 2, 3]);
      expect(v.major, 1);
      expect(v.minor, 2);
      expect(v.patch, 3);
      expect(v.raw, '1.2.3');
    });

    test('ignores prefixes, suffixes and build metadata', () {
      expect(VersionNumber.parse('v1.2.3').components, <int>[1, 2, 3]);
      expect(VersionNumber.parse('1.2.3-beta+7').components, <int>[1, 2, 3]);
      expect(VersionNumber.parse('1.2.3 (45)').components, <int>[1, 2, 3]);
      expect(VersionNumber.parse('Version 2').components, <int>[2]);
      expect(VersionNumber.parse('1.2.3.4').components, <int>[1, 2, 3, 4]);
      expect(VersionNumber.parse('1.2.prod.3').components, <int>[1, 2]);
    });

    test('missing components read as zero', () {
      final VersionNumber v = VersionNumber.parse('3');
      expect(v.minor, 0);
      expect(v.patch, 0);
      expect(v[10], 0);
    });

    test('rejects strings without digits', () {
      expect(VersionNumber.tryParse('abc'), isNull);
      expect(VersionNumber.tryParse(null), isNull);
      expect(VersionNumber.tryParse(''), isNull);
      expect(() => VersionNumber.parse('abc'), throwsFormatException);
    });

    test('rejects empty or negative components', () {
      expect(() => VersionNumber(<int>[]), throwsArgumentError);
      expect(() => VersionNumber(<int>[1, -1]), throwsArgumentError);
    });
  });

  group('VersionNumber comparison', () {
    VersionNumber v(String s) => VersionNumber.parse(s);

    test('orders numerically, not lexically', () {
      expect(v('1.10.0') > v('1.9.9'), isTrue);
      expect(v('1.2.3') < v('1.2.4'), isTrue);
      expect(v('2.0') > v('1.99.99'), isTrue);
      expect(v('1.2.0.1') > v('1.2'), isTrue);
    });

    test('treats trailing zeros as equal', () {
      expect(v('1.2') == v('1.2.0'), isTrue);
      expect(v('1.2').hashCode, v('1.2.0.0').hashCode);
      expect(v('1.2') >= v('1.2.0'), isTrue);
      expect(v('1.2') <= v('1.2.0'), isTrue);
      expect(v('1.2').compareTo(v('1.2.0')), 0);
    });

    test('zero is the smallest', () {
      expect(VersionNumber.zero < v('0.0.1'), isTrue);
      expect(VersionNumber.zero == v('0.0.0'), isTrue);
    });

    test('toString is canonical', () {
      expect(v('v1.2.3-beta').toString(), '1.2.3');
      expect(VersionNumber(<int>[1, 0]).toString(), '1.0');
    });
  });
}
