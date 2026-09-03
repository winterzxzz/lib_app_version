import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// A small, dependency-free version number used for comparisons.
///
/// Only the leading numeric components are considered, so all of these parse:
/// `1.2.3`, `1.2`, `1.2.3.4`, `v1.2.3`, `1.2.3-beta+7`, `1.2.3 (12)`.
///
/// Missing components count as `0`, therefore `1.2 == 1.2.0`.
/// Pre-release and build metadata are ignored on purpose: store listings only
/// expose the public `MAJOR.MINOR.PATCH` string anyway.
@immutable
class VersionNumber implements Comparable<VersionNumber> {
  const VersionNumber._(this.components, this.raw);

  /// Creates a version from its numeric [components], e.g. `[1, 2, 3]`.
  factory VersionNumber(List<int> components, {String? raw}) {
    if (components.isEmpty) {
      throw ArgumentError.value(components, 'components', 'must not be empty');
    }
    if (components.any((c) => c < 0)) {
      throw ArgumentError.value(components, 'components', 'must be >= 0');
    }
    return VersionNumber._(
      List<int>.unmodifiable(components),
      raw ?? components.join('.'),
    );
  }

  /// Parses [input]. Throws a [FormatException] when no digits are found.
  factory VersionNumber.parse(String input) {
    final VersionNumber? parsed = tryParse(input);
    if (parsed == null) {
      throw FormatException('Not a valid version string', input);
    }
    return parsed;
  }

  /// `0`
  static const VersionNumber zero = VersionNumber._(<int>[0], '0');

  static final RegExp _pattern = RegExp(r'\d+(?:\.\d+)*');

  /// Parses [input], returning `null` instead of throwing on invalid input.
  static VersionNumber? tryParse(String? input) {
    if (input == null) return null;
    final RegExpMatch? match = _pattern.firstMatch(input);
    if (match == null) return null;
    final List<int> parts = match
        .group(0)!
        .split('.')
        .map((String p) => int.tryParse(p) ?? 0)
        .toList(growable: false);
    return VersionNumber(parts, raw: input.trim());
  }

  /// Numeric components, e.g. `[1, 2, 3]` for `1.2.3`.
  final List<int> components;

  /// The original string this version was parsed from.
  final String raw;

  /// Component at [index]; missing components are `0`.
  int operator [](int index) =>
      index < components.length ? components[index] : 0;

  int get major => this[0];
  int get minor => this[1];
  int get patch => this[2];

  @override
  int compareTo(VersionNumber other) {
    final int length = math.max(components.length, other.components.length);
    for (int i = 0; i < length; i++) {
      final int diff = this[i].compareTo(other[i]);
      if (diff != 0) return diff;
    }
    return 0;
  }

  bool operator >(VersionNumber other) => compareTo(other) > 0;
  bool operator >=(VersionNumber other) => compareTo(other) >= 0;
  bool operator <(VersionNumber other) => compareTo(other) < 0;
  bool operator <=(VersionNumber other) => compareTo(other) <= 0;

  List<int> get _normalized {
    int end = components.length;
    while (end > 1 && components[end - 1] == 0) {
      end--;
    }
    return components.sublist(0, end);
  }

  @override
  bool operator ==(Object other) =>
      other is VersionNumber && compareTo(other) == 0;

  @override
  int get hashCode => Object.hashAll(_normalized);

  /// Canonical dotted form, e.g. `1.2.3`.
  @override
  String toString() => components.join('.');
}
