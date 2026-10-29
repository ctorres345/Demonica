import 'dart:io';

import 'package:demonica/app/version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('appVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version:\s*([0-9.]+)', multiLine: true).firstMatch(pubspec)!;
    expect(appVersion, version.group(1));
  });
}
