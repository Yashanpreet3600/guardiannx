import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/localization/app_strings.dart';
import 'core/services/local_store.dart';
import 'core/services/supabase_service.dart';
import 'features/sos/services/sos_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await LocalStore.init();
  LocaleController.instance.load();

  if (AppConfig.isConfigured) {
    await SupabaseService.init();
    // If an SOS was running when the app closed, start it again right away.
    if (SupabaseService.currentUser != null) {
      try {
        await SosEngine.instance.restore();
      } catch (_) {}
    }
  }

  runApp(const GuardianXApp());
}
