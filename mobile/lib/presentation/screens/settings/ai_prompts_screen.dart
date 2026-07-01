import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/spacing.dart';
import '../../../core/ai/ai_config.dart';
import '../../../core/openai/api_key_store.dart';
import '../../../core/openai/openai_client.dart';

/// Lets the user view/edit the system prompt + token limit for each AI
/// feature, and reset any (or all) back to defaults.
class AiPromptsScreen extends StatefulWidget {
  const AiPromptsScreen({super.key});

  @override
  State<AiPromptsScreen> createState() => _AiPromptsScreenState();
}

class _AiPromptsScreenState extends State<AiPromptsScreen> {
  final Map<AiOp, TextEditingController> _promptCtrls = {};
  final Map<AiOp, TextEditingController> _tokenCtrls = {};
  late final TextEditingController _chatModelCtrl =
      TextEditingController(text: AiConfig.instance.chatModel);
  late final TextEditingController _embeddingModelCtrl =
      TextEditingController(text: AiConfig.instance.embeddingModel);
  late final TextEditingController _deepseekModelCtrl =
      TextEditingController(text: AiConfig.instance.deepseekModel);
  final TextEditingController _deepseekKeyCtrl = TextEditingController();
  String _provider = AiConfig.instance.llmProvider;

  @override
  void initState() {
    super.initState();
    for (final op in AiOp.values) {
      _promptCtrls[op] =
          TextEditingController(text: AiConfig.instance.systemPrompt(op));
      _tokenCtrls[op] =
          TextEditingController(text: AiConfig.instance.tokenLimit(op).toString());
    }
    ApiKeyStore().readDeepseek().then((k) {
      if (mounted && k != null && k.isNotEmpty) _deepseekKeyCtrl.text = k;
    });
  }

  Future<void> _saveDeepseek() async {
    await AiConfig.instance.setLlmProvider(_provider);
    await AiConfig.instance.setDeepseekModel(_deepseekModelCtrl.text);
    final key = _deepseekKeyCtrl.text.trim();
    if (key.isEmpty) {
      await ApiKeyStore().deleteDeepseek();
      OpenAiClient.instance.setDeepseekApiKey(null);
    } else {
      await ApiKeyStore().writeDeepseek(key);
      OpenAiClient.instance.setDeepseekApiKey(key);
    }
  }

  @override
  void dispose() {
    for (final c in _promptCtrls.values) {
      c.dispose();
    }
    for (final c in _tokenCtrls.values) {
      c.dispose();
    }
    _chatModelCtrl.dispose();
    _embeddingModelCtrl.dispose();
    _deepseekModelCtrl.dispose();
    _deepseekKeyCtrl.dispose();
    super.dispose();
  }

  void _syncControllers() {
    for (final op in AiOp.values) {
      _promptCtrls[op]!.text = AiConfig.instance.systemPrompt(op);
      _tokenCtrls[op]!.text = AiConfig.instance.tokenLimit(op).toString();
    }
    _chatModelCtrl.text = AiConfig.instance.chatModel;
    _embeddingModelCtrl.text = AiConfig.instance.embeddingModel;
  }

  Future<void> _save() async {
    await AiConfig.instance.setChatModel(_chatModelCtrl.text);
    await AiConfig.instance.setEmbeddingModel(_embeddingModelCtrl.text);
    for (final op in AiOp.values) {
      final text = _promptCtrls[op]!.text.trim();
      await AiConfig.instance.setSystemPrompt(
        op,
        text.isEmpty ? aiOps[op]!.defaultPrompt : text,
      );
      final tokens = int.tryParse(_tokenCtrls[op]!.text.trim());
      if (tokens != null) {
        await AiConfig.instance.setTokenLimit(op, tokens);
      }
    }
    if (!mounted) return;
    _syncControllers(); // reflect clamping / default-fallbacks
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI settings saved')),
    );
  }

  Future<void> _resetOp(AiOp op) async {
    await AiConfig.instance.reset(op);
    if (!mounted) return;
    setState(() {
      _promptCtrls[op]!.text = AiConfig.instance.systemPrompt(op);
      _tokenCtrls[op]!.text = AiConfig.instance.tokenLimit(op).toString();
    });
  }

  Future<void> _resetAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all to defaults?'),
        content: const Text(
            'This restores every AI prompt and token limit to its default value.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Reset all')),
        ],
      ),
    );
    if (confirm != true) return;
    await AiConfig.instance.resetAll();
    if (!mounted) return;
    setState(_syncControllers);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset all AI settings to defaults')),
    );
  }

  Widget _buildProviderCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: Spacing.borderRadiusMd,
        boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub_rounded,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: Spacing.sm),
              Text('Text generation provider',
                  style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'DeepSeek powers chat, quizzes, flashcards & summaries. Search '
            'indexing (embeddings) and image OCR always use OpenAI, so keep an '
            'OpenAI key set for those.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.md),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'openai', label: Text('OpenAI')),
              ButtonSegment(value: 'deepseek', label: Text('DeepSeek')),
            ],
            selected: {_provider},
            onSelectionChanged: (s) => setState(() => _provider = s.first),
          ),
          if (_provider == 'deepseek') ...[
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _deepseekKeyCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'DeepSeek API key',
                hintText: 'sk-...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: _deepseekModelCtrl,
              decoration: const InputDecoration(
                labelText: 'DeepSeek model',
                helperText: 'deepseek-v4-flash (fast) · deepseek-v4-pro (stronger)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: Spacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () async {
                await _saveDeepseek();
                if (!mounted) return;
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI provider saved')),
                );
              },
              child: const Text('Save provider'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Settings', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            tooltip: 'Reset all',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: _resetAll,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.save_rounded),
        label: const Text('Save'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          Spacing.screenPaddingH,
          Spacing.md,
          Spacing.screenPaddingH,
          Spacing.xl * 2 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          Text(
            'Customize the models, prompts and token limits. Changes apply to new '
            'requests. For Quiz & Flashcards, the required JSON format is added '
            'automatically.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.md),
          _ModelsCard(
            chatController: _chatModelCtrl,
            embeddingController: _embeddingModelCtrl,
            isDark: isDark,
            onReset: () async {
              await AiConfig.instance.setChatModel(AiConfig.instance.defaultChatModel);
              await AiConfig.instance
                  .setEmbeddingModel(AiConfig.instance.defaultEmbeddingModel);
              if (!mounted) return;
              setState(() {
                _chatModelCtrl.text = AiConfig.instance.chatModel;
                _embeddingModelCtrl.text = AiConfig.instance.embeddingModel;
              });
            },
          ),
          const SizedBox(height: Spacing.md),
          _buildProviderCard(theme, isDark),
          const SizedBox(height: Spacing.md),
          for (final op in AiOp.values) ...[
            _OpCard(
              meta: aiOps[op]!,
              promptController: _promptCtrls[op]!,
              tokenController: _tokenCtrls[op]!,
              isDark: isDark,
              onReset: () => _resetOp(op),
            ),
            const SizedBox(height: Spacing.md),
          ],
        ],
      ),
    );
  }
}

class _ModelsCard extends StatelessWidget {
  final TextEditingController chatController;
  final TextEditingController embeddingController;
  final bool isDark;
  final VoidCallback onReset;

  const _ModelsCard({
    required this.chatController,
    required this.embeddingController,
    required this.isDark,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: Spacing.borderRadiusMd,
        boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Models', style: theme.textTheme.titleSmall),
              ),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          TextField(
            controller: chatController,
            autocorrect: false,
            enableSuggestions: false,
            style: theme.textTheme.bodyMedium,
            decoration: const InputDecoration(
              labelText: 'Chat model',
              helperText: 'e.g. gpt-4o-mini, gpt-4o, gpt-4.1-mini',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Spacing.md),
          TextField(
            controller: embeddingController,
            autocorrect: false,
            enableSuggestions: false,
            style: theme.textTheme.bodyMedium,
            decoration: const InputDecoration(
              labelText: 'Embedding model',
              helperText: 'e.g. text-embedding-3-small or -large',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Embeddings are requested at 384 dimensions to match the search '
                  'index. If you change the embedding model, re-import (or re-embed) '
                  'existing notes for accurate search & chat.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpCard extends StatelessWidget {
  final AiOpMeta meta;
  final TextEditingController promptController;
  final TextEditingController tokenController;
  final bool isDark;
  final VoidCallback onReset;

  const _OpCard({
    required this.meta,
    required this.promptController,
    required this.tokenController,
    required this.isDark,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: Spacing.borderRadiusMd,
        boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(meta.title, style: theme.textTheme.titleSmall),
              ),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
          Text(
            meta.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          TextField(
            controller: promptController,
            minLines: 3,
            maxLines: 10,
            style: theme.textTheme.bodySmall,
            decoration: const InputDecoration(
              labelText: 'System prompt',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              Text('Max tokens',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
              const SizedBox(width: Spacing.md),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: tokenController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: theme.textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text('(${meta.defaultTokens} default)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
