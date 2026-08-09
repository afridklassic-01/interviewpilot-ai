import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the real Roboto family into the test font manager.
///
/// flutter_test otherwise renders with the "Ahem" placeholder font, where
/// every glyph is a full-em square — text measures roughly twice as wide
/// as production, which produces false RenderFlex overflow reports.
Future<void> loadRealFonts() async {
  final sdk = _sdkRoot();
  final fontsDir = Directory('$sdk/bin/cache/artifacts/material_fonts');
  if (!fontsDir.existsSync()) {
    // Without the fonts the test still runs, just with Ahem metrics.
    return;
  }

  const family = 'Roboto';
  const files = [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ];

  final loader = FontLoader(family);
  for (final file in files) {
    final f = File('${fontsDir.path}/$file');
    if (!f.existsSync()) continue;
    final bytes = f.readAsBytesSync();
    // The internal font name matches the 'Roboto' family.
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

String? _sdkRoot() {
  final fromEnv = Platform.environment['FLUTTER_ROOT'];
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

  // flutter_tester lives at <sdk>/bin/cache/flutter_tester.
  final executable = Platform.resolvedExecutable;
  final tester = File(executable);
  if (tester.path.contains('flutter_tester')) {
    return tester.parent.parent.parent.path;
  }
  return null;
}
