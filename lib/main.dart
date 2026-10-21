import 'package:easy_localization/easy_localization.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flundel/app/app.dart';
import 'package:flundel/storage/local_storage.dart';
import 'package:flundel/audio/flundel_audio_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await HiveLocalStorageRepository.init();
  flundelAudioHandler = await AudioService.init<FlundelAudioHandler>(
    builder: FlundelAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.flundel.focus.audio',
      androidNotificationChannelName: 'Flundel Focus',
      androidNotificationOngoing: true,
    ),
  );
  final audioSession = await AudioSession.instance;
  await audioSession.configure(const AudioSessionConfiguration.music());

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(
        child: FlundelApp(),
      ),
    ),
  );
}
