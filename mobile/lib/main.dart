import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/ai/ai_config.dart';
import 'core/utils/annotate_prefs.dart';
import 'core/utils/view_prefs.dart';
import 'core/database/objectbox.dart';
import 'core/openai/api_key_store.dart';
import 'core/openai/openai_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load editable AI prompts + token limits.
  await AiConfig.instance.load();
  await AnnotatePrefs.instance.load();
  await ViewPrefs.instance.load();

  // Initialize ObjectBox
  final objectBox = await ObjectBox.create();

  // Load the saved OpenAI API key into the in-memory client so the AI
  // services report ready without an async lookup.
  final apiKey = await ApiKeyStore().read();
  OpenAiClient.instance.setApiKey(apiKey);

  // Onboarding is complete once an API key has been configured.
  final hasApiKey = OpenAiClient.instance.hasKey;

  runApp(
    ProviderScope(
      overrides: [
        objectBoxProvider.overrideWithValue(objectBox),
      ],
      child: StudyCompanionApp(showOnboarding: !hasApiKey),
    ),
  );
}
