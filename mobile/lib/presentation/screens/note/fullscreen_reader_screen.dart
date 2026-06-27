import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/view_prefs.dart';
import '../../providers/note_provider.dart';
import '../../widgets/common/markdown_view.dart';
import '../../widgets/common/view_scale_sheet.dart';

/// Distraction-free, immersive fullscreen reader for a note (rendered Markdown
/// for `.md`, plain selectable text for `.txt`). Hides the system bars; tap to
/// toggle a minimal top bar, or use the always-present close button.
class FullscreenReaderScreen extends ConsumerStatefulWidget {
  final int noteId;
  const FullscreenReaderScreen({super.key, required this.noteId});

  @override
  ConsumerState<FullscreenReaderScreen> createState() =>
      _FullscreenReaderScreenState();
}

class _FullscreenReaderScreenState
    extends ConsumerState<FullscreenReaderScreen> {
  bool _loaded = false;
  String _title = '';
  String _rawText = '';
  String _sourceType = 'md';
  String? _sourcePath;
  bool _barVisible = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _load();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _load() async {
    final note = await ref.read(noteRepositoryProvider).getById(widget.noteId);
    if (!mounted) return;
    setState(() {
      _title = note?.title ?? '';
      _rawText = note?.rawText ?? '';
      _sourceType = note?.sourceType ?? 'md';
      _sourcePath = note?.sourcePath;
      _loaded = true;
    });
  }

  Widget _pdfBody() {
    final path = _sourcePath;
    if (path == null || !File(path).existsSync()) {
      return const Center(child: Text('PDF file unavailable'));
    }
    return PdfViewer.file(path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                if (_sourceType == 'pdf')
                  _pdfBody()
                else
                  GestureDetector(
                  onTap: () => setState(() => _barVisible = !_barVisible),
                  behavior: HitTestBehavior.opaque,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      topInset + 56,
                      24,
                      MediaQuery.of(context).padding.bottom + 56,
                    ),
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler:
                            TextScaler.linear(ViewPrefs.instance.readScale),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: _sourceType == 'md'
                              ? MarkdownView(data: _rawText, selectable: true)
                              : SelectableText(
                                _rawText,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  height: 1.8,
                                  color: isDark
                                      ? AppColors.onSurfaceDark
                                      : AppColors.onSurfaceLight,
                                ),
                              ),
                      ),
                    ),
                    ),
                  ),
                ),

                // Minimal top bar (revealed on tap)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  top: _barVisible ? 0 : -(topInset + 56),
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(8, topInset + 4, 8, 8),
                    color: (isDark ? AppColors.surfaceDark : Colors.white)
                        .withValues(alpha: 0.95),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Text-size button (not for PDF — pdfrx has its own zoom)
                if (_sourceType != 'pdf')
                  Positioned(
                  top: topInset + 8,
                  right: 60,
                  child: Material(
                    color: (isDark ? Colors.black : Colors.white)
                        .withValues(alpha: 0.55),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Text size',
                      icon: const Icon(Icons.format_size_rounded),
                      onPressed: () => showViewScaleSheet(
                        context,
                        title: 'Text size',
                        value: ViewPrefs.instance.readScale,
                        min: ViewPrefs.minRead,
                        max: ViewPrefs.maxRead,
                        onChanged: (v) async {
                          await ViewPrefs.instance.setReadScale(v);
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: topInset + 8,
                  right: 12,
                  child: Material(
                    color: (isDark ? Colors.black : Colors.white)
                        .withValues(alpha: 0.55),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Exit fullscreen',
                      icon: const Icon(Icons.fullscreen_exit_rounded),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
