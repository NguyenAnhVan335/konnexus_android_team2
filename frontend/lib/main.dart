import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppServices services = await AppServices.bootstrap();
  runApp(KonnexusApp(services: services));
}
