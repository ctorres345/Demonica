import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';

void main() {
  usePathUrlStrategy();
  LicenseRegistry.addLicense(_fontLicenses);
  runApp(const ProviderScope(child: DemonicaApp()));
}

/// The bundled fonts' OFL texts, so they appear on the licences page that
/// Settings opens alongside the Flutter and package licences.
Stream<LicenseEntry> _fontLicenses() async* {
  const fonts = {
    'Chakra Petch': 'assets/fonts/OFL-ChakraPetch.txt',
    'Inter': 'assets/fonts/OFL-Inter.txt',
    'JetBrains Mono': 'assets/fonts/OFL-JetBrainsMono.txt',
  };
  for (final MapEntry(key: name, value: path) in fonts.entries) {
    yield LicenseEntryWithLineBreaks([name], await rootBundle.loadString(path));
  }
}
