import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_config.dart';
import '../../../config/routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/gradients.dart';
import '../../../config/theme/spacing.dart';
import '../../../core/openai/api_key_store.dart';
import '../../../core/openai/openai_client.dart';

/// Lets the user enter / update their OpenAI API key. Used both as the
/// first-run setup step ([isFirstRun] = true → go to Home on save) and from
/// Settings ([isFirstRun] = false → pop on save).
class ApiKeySetupScreen extends ConsumerStatefulWidget {
  final bool isFirstRun;
  const ApiKeySetupScreen({super.key, this.isFirstRun = false});

  @override
  ConsumerState<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends ConsumerState<ApiKeySetupScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    // Prefill with the currently configured key (if any).
    _controller.text = OpenAiClient.instance.apiKey ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _looksValid {
    final v = _controller.text.trim();
    return v.startsWith('sk-') && v.length > 20;
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (!_looksValid) {
      setState(() => _error = 'That doesn\'t look like an OpenAI key (starts with "sk-").');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });

    await ref.read(apiKeyStoreProvider).write(key);
    OpenAiClient.instance.setApiKey(key);

    if (!mounted) return;
    setState(() => _busy = false);

    if (widget.isFirstRun) {
      context.go(AppRoutes.home);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _test() async {
    final key = _controller.text.trim();
    if (!_looksValid) {
      setState(() => _error = 'Enter a valid key first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });

    // Apply the key in-memory and try a tiny embeddings call to verify it.
    final previous = OpenAiClient.instance.apiKey;
    OpenAiClient.instance.setApiKey(key);
    try {
      await OpenAiClient.instance.embed(['ping']);
      if (!mounted) return;
      setState(() => _success = 'Connection successful — your key works.');
    } catch (e) {
      OpenAiClient.instance.setApiKey(previous);
      if (!mounted) return;
      setState(() => _error = 'Test failed: ${e.toString().replaceFirst('LlmException: ', '')}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    await ref.read(apiKeyStoreProvider).delete();
    OpenAiClient.instance.setApiKey(null);
    _controller.clear();
    if (!mounted) return;
    setState(() {
      _success = 'Key removed.';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasExistingKey = (OpenAiClient.instance.apiKey ?? '').isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstRun ? 'Connect OpenAI' : 'OpenAI API Key',
            style: theme.textTheme.titleLarge),
        automaticallyImplyLeading: !widget.isFirstRun,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          Spacing.screenPaddingH,
          Spacing.lg,
          Spacing.screenPaddingH,
          Spacing.lg + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.primary,
            ),
            child: const Icon(Icons.key_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'Add your OpenAI API key',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Study Companion uses your own OpenAI key for chat, quizzes, '
            'flashcards and search. Your notes stay on this device — only the '
            'text needed to answer a request is sent to OpenAI. The key is '
            'stored securely in your device keystore.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Get a key at platform.openai.com/api-keys',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: Spacing.xl),

          TextField(
            controller: _controller,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: 'sk-...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onChanged: (_) => setState(() {
              _error = null;
              _success = null;
            }),
          ),

          if (_error != null) ...[
            const SizedBox(height: Spacing.sm),
            Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13)),
          ],
          if (_success != null) ...[
            const SizedBox(height: Spacing.sm),
            Text(_success!, style: TextStyle(color: AppColors.success, fontSize: 13)),
          ],

          const SizedBox(height: Spacing.lg),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(widget.isFirstRun ? 'Save & Continue' : 'Save'),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _test,
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: const Text('Test connection'),
            ),
          ),
          if (hasExistingKey) ...[
            const SizedBox(height: Spacing.sm),
            TextButton(
              onPressed: _busy ? null : _clear,
              child: Text('Remove key', style: TextStyle(color: AppColors.error)),
            ),
          ],

          const SizedBox(height: Spacing.lg),
          Text(
            'Model: ${AppConfig.openAiChatModel}  ·  Embeddings: ${AppConfig.openAiEmbeddingModel}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
