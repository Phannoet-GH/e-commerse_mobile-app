import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/ecommerce_app.dart';
import 'app/app_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: provider,
      child: DevicePreview(
        enabled: !kReleaseMode,
        builder: (context) => const ECommerceApp(),
      ),
    ),
  );
}
