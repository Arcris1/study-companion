import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';
import '../../../core/openai/openai_client.dart';
import '../../../core/llm/llm_service.dart';
import '../../../core/utils/annotate_prefs.dart';
import '../../../data/models/note_annotation_model.dart';
import '../../providers/note_provider.dart';
import '../../providers/note_annotation_provider.dart';
import '../../widgets/common/markdown_view.dart';

/// Fixed page width all ink is stored in; the page is scaled to fit any screen
/// so ink always stays aligned with the text.
const double _kPageWidth = 400;

const List<int> _penColors = [
  0xFFEF4444, // red
  0xFF3B82F6, // blue
  0xFF22C55E, // green
  0xFFF59E0B, // amber
  0xFFA855F7, // purple
  0xFF111827, // ink
];

enum _Tool { move, pen, highlighter, eraser, sidenote, box }

class _Stroke {
  final List<Offset> points;
  final int colorValue;
  final double width;
  final bool highlighter;
  _Stroke({
    required this.points,
    required this.colorValue,
    required this.width,
    required this.highlighter,
  });

  Map<String, dynamic> toJson() => {
        'c': colorValue,
        'w': width,
        'h': highlighter,
        'p': [for (final o in points) ...[o.dx, o.dy]],
      };

  factory _Stroke.fromJson(Map<String, dynamic> m) {
    final flat = (m['p'] as List).map((e) => (e as num).toDouble()).toList();
    final pts = <Offset>[];
    for (var i = 0; i + 1 < flat.length; i += 2) {
      pts.add(Offset(flat[i], flat[i + 1]));
    }
    return _Stroke(
      points: pts,
      colorValue: m['c'] as int,
      width: (m['w'] as num).toDouble(),
      highlighter: m['h'] == true,
    );
  }
}

class _Sidenote {
  Offset pos;
  String text;
  _Sidenote(this.pos, this.text);

  Map<String, dynamic> toJson() => {'x': pos.dx, 'y': pos.dy, 't': text};
  factory _Sidenote.fromJson(Map<String, dynamic> m) => _Sidenote(
        Offset((m['x'] as num).toDouble(), (m['y'] as num).toDouble()),
        m['t'] as String? ?? '',
      );
}

class NoteAnnotateScreen extends ConsumerStatefulWidget {
  final int noteId;
  const NoteAnnotateScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteAnnotateScreen> createState() => _NoteAnnotateScreenState();
}

class _NoteAnnotateScreenState extends ConsumerState<NoteAnnotateScreen> {
  bool _loaded = false;
  String _title = 'Annotate';
  String _rawText = '';
  String _sourceType = 'md';

  final List<_Stroke> _strokes = [];
  final List<_Sidenote> _sidenotes = [];
  _Stroke? _current;

  _Tool _tool = _Tool.move;
  int _colorIndex = 5; // ink
  bool _dirty = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _captureKey = GlobalKey();
  Offset _lastFocal = Offset.zero;
  bool _scrolling = false;

  // Box-AI region (page coords).
  Offset? _boxStart;
  Rect? _boxRect;
  bool _capturing = false;
  bool _movingBox = false;
  Offset _boxGrab = Offset.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final note = await ref.read(noteRepositoryProvider).getById(widget.noteId);
    final ann =
        ref.read(noteAnnotationDatasourceProvider).getByNoteId(widget.noteId);
    if (ann != null) {
      for (final s in (jsonDecode(ann.strokesJson) as List)) {
        _strokes.add(_Stroke.fromJson(s as Map<String, dynamic>));
      }
      for (final s in (jsonDecode(ann.sidenotesJson) as List)) {
        _sidenotes.add(_Sidenote.fromJson(s as Map<String, dynamic>));
      }
    }
    if (!mounted) return;
    setState(() {
      _title = note?.title ?? 'Annotate';
      _rawText = note?.rawText ?? '';
      _sourceType = note?.sourceType ?? 'md';
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final model = ref
            .read(noteAnnotationDatasourceProvider)
            .getByNoteId(widget.noteId) ??
        NoteAnnotationModel(noteId: widget.noteId, updatedAt: DateTime.now());
    model
      ..strokesJson = jsonEncode(_strokes.map((s) => s.toJson()).toList())
      ..sidenotesJson = jsonEncode(_sidenotes.map((s) => s.toJson()).toList())
      ..updatedAt = DateTime.now();
    ref.read(noteAnnotationDatasourceProvider).save(model);
    ref.invalidate(noteAnnotationProvider(widget.noteId));
    _dirty = false;
  }

  int get _activeColor => _penColors[_colorIndex];

  // ── Gestures: 1 finger = tool, 2 fingers = scroll (always) ──────────────────

  void _onScaleStart(ScaleStartDetails d) {
    _lastFocal = d.focalPoint;
    _scrolling = _tool == _Tool.move || d.pointerCount >= 2;
    if (_scrolling) return;
    final p = d.localFocalPoint;
    if (_tool == _Tool.pen || _tool == _Tool.highlighter) {
      setState(() {
        _current = _Stroke(
          points: [p],
          colorValue: _activeColor,
          width: _tool == _Tool.highlighter ? 18 : 3,
          highlighter: _tool == _Tool.highlighter,
        );
      });
    } else if (_tool == _Tool.eraser) {
      _eraseAt(p);
    } else if (_tool == _Tool.box) {
      // Grab an existing box to move it; otherwise start a new one.
      if (_boxRect != null && _boxRect!.contains(p)) {
        _movingBox = true;
        _boxGrab = p - _boxRect!.topLeft;
      } else {
        _movingBox = false;
        _boxStart = p;
        setState(() => _boxRect = Rect.fromPoints(p, p));
      }
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final delta = d.focalPoint - _lastFocal;
    _lastFocal = d.focalPoint;

    // Two fingers (or Move tool) → scroll the page.
    if (_tool == _Tool.move || d.pointerCount >= 2) {
      _scrolling = true;
      if (_current != null) setState(() => _current = null);
      if (_scrollController.hasClients) {
        final max = _scrollController.position.maxScrollExtent;
        _scrollController
            .jumpTo((_scrollController.offset - delta.dy).clamp(0.0, max));
      }
      return;
    }

    final p = d.localFocalPoint;
    if (_current != null) {
      setState(() => _current!.points.add(p));
    } else if (_tool == _Tool.eraser) {
      _eraseAt(p);
    } else if (_tool == _Tool.box) {
      if (_movingBox && _boxRect != null) {
        setState(() => _boxRect = (p - _boxGrab) & _boxRect!.size);
      } else if (_boxStart != null) {
        setState(() => _boxRect = Rect.fromPoints(_boxStart!, p));
      }
    }
  }

  void _onScaleEnd(ScaleEndDetails d) {
    if (_scrolling) {
      _scrolling = false;
      _flingScroll(d.velocity.pixelsPerSecond.dy);
      return;
    }
    if (_current != null) {
      setState(() {
        _strokes.add(_current!);
        _current = null;
        _dirty = true;
      });
    }
    _boxStart = null;
    _movingBox = false;
  }

  /// Adds inertia after a two-finger scroll so it doesn't stop dead.
  void _flingScroll(double velocityY) {
    if (!_scrollController.hasClients || velocityY.abs() < 80) return;
    final max = _scrollController.position.maxScrollExtent;
    final target =
        (_scrollController.offset - velocityY * 0.25).clamp(0.0, max);
    final dist = (target - _scrollController.offset).abs();
    if (dist < 1) return;
    _scrollController.animateTo(
      target,
      duration: Duration(milliseconds: (dist * 1.2).clamp(150, 700).toInt()),
      curve: Curves.decelerate,
    );
  }

  void _eraseAt(Offset p) {
    final before = _strokes.length;
    _strokes.removeWhere((s) => s.points.any((pt) => (pt - p).distance < 14));
    if (_strokes.length != before) setState(() => _dirty = true);
  }

  Future<void> _addSidenoteAt(Offset p) async {
    final text = await _editSidenoteText(initial: '');
    if (text == null || text.trim().isEmpty) return;
    setState(() {
      _sidenotes.add(_Sidenote(p, text.trim()));
      _dirty = true;
    });
  }

  Future<void> _openSidenote(int i) async {
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => _SidenoteDialog(
        initialText: _sidenotes[i].text,
        allowDelete: true,
        onAiAssist: _generateSidenote,
      ),
    );
    if (result == null) return;
    setState(() {
      if (result == ' delete') {
        _sidenotes.removeAt(i);
      } else {
        _sidenotes[i].text = result;
      }
      _dirty = true;
    });
  }

  Future<String?> _editSidenoteText({required String initial}) {
    return showDialog<String?>(
      context: context,
      builder: (ctx) => _SidenoteDialog(
        initialText: initial,
        onAiAssist: _generateSidenote,
      ),
    );
  }

  Future<String> _generateSidenote(String hint) async {
    if (!OpenAiClient.instance.hasKey) {
      throw Exception('No OpenAI API key set (Settings > AI)');
    }
    final h = hint.trim();
    final prompt = '''<|begin_of_turn|>system
You write concise study margin-notes (1-3 short sentences). Output ONLY the note text — no preamble, labels or quotes.<|end_of_turn|>
<|begin_of_turn|>user
Lecture/note title: "$_title".
${h.isEmpty ? 'Write a brief, useful study margin-note for this topic.' : 'Write a brief margin-note based on: $h'}<|end_of_turn|>
<|begin_of_turn|>assistant
''';
    final buf = StringBuffer();
    await for (final t in ref
        .read(llmServiceProvider)
        .generateStream(prompt, maxTokens: 220)) {
      buf.write(t);
    }
    return buf.toString().trim();
  }

  // ── Box → Ask AI (vision) ───────────────────────────────────────────────────

  Future<void> _askBoxAi() async {
    final rect = _boxRect;
    if (rect == null || rect.width < 10 || rect.height < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draw a box over the content first')),
      );
      return;
    }
    if (!OpenAiClient.instance.hasKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No OpenAI API key set (Settings > AI)')),
      );
      return;
    }
    setState(() => _capturing = true);
    try {
      final boundary = _captureKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      const pr = 3.0;
      final fullImage = await boundary.toImage(pixelRatio: pr);
      final src = Rect.fromLTWH(
          rect.left * pr, rect.top * pr, rect.width * pr, rect.height * pr);
      final dst = Rect.fromLTWH(0, 0, rect.width * pr, rect.height * pr);
      final recorder = ui.PictureRecorder();
      Canvas(recorder)
        ..drawColor(Colors.white, BlendMode.src)
        ..drawImageRect(fullImage, src, dst, Paint());
      final cropped = await recorder.endRecording().toImage(
            (rect.width * pr).round(),
            (rect.height * pr).round(),
          );
      final bytes = await cropped.toByteData(format: ui.ImageByteFormat.png);
      fullImage.dispose();
      cropped.dispose();
      if (!mounted) return;
      if (bytes == null) throw Exception('capture failed');
      final png = bytes.buffer.asUint8List();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _BoxAiSheet(png: png),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t read the box: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.removeLast();
      _dirty = true;
    });
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all annotations?'),
        content: const Text('This removes every stroke and sidenote.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Clear')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() {
      _strokes.clear();
      _sidenotes.clear();
      _boxRect = null;
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boxReady =
        _tool == _Tool.box && _boxRect != null && _boxRect!.width > 10;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (_dirty) _save();
      },
      child: Scaffold(
        backgroundColor: theme.brightness == Brightness.dark
            ? const Color(0xFF15151E)
            : Colors.white,
        appBar: AppBar(
          title: Text(_title,
              style: theme.textTheme.titleMedium,
              overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              tooltip: 'Preview (exit annotate)',
              icon: const Icon(Icons.visibility_rounded),
              onPressed: () async {
                final router = GoRouter.of(context);
                await _save();
                await AnnotatePrefs.instance.setAnnotate(widget.noteId, false);
                router.pushReplacement('/note/${widget.noteId}');
              },
            ),
            TextButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await _save();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Annotations saved')),
                );
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save'),
            ),
          ],
        ),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(child: _buildPage(theme)),
                  if (boxReady) _buildBoxBar(theme),
                  _buildToolbar(theme),
                ],
              ),
      ),
    );
  }

  Widget _buildBoxBar(ThemeData theme) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.xs),
        child: Row(
          children: [
            Icon(Icons.crop_free_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Ask AI about the boxed region')),
            TextButton(
              onPressed: () => setState(() => _boxRect = null),
              child: const Text('Clear'),
            ),
            FilledButton.icon(
              onPressed: _capturing ? null : _askBoxAi,
              icon: _capturing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 16),
              label: const Text('Ask AI'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const NeverScrollableScrollPhysics(), // scroll driven manually
      child: FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: _kPageWidth,
          child: Stack(
            children: [
              // Capturable layer: content + ink (used by Box-AI).
              RepaintBoundary(
                key: _captureKey,
                child: Stack(
                  children: [
                    Container(
                      width: _kPageWidth,
                      color: isDark ? const Color(0xFF15151E) : Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: _sourceType == 'md'
                          ? MarkdownView(data: _rawText, selectable: false)
                          : Text(
                              _rawText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.7,
                                color: isDark
                                    ? AppColors.onSurfaceDark
                                    : AppColors.onSurfaceLight,
                              ),
                            ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                            painter: _InkPainter(_strokes, _current)),
                      ),
                    ),
                  ],
                ),
              ),
              // Box overlay
              if (_boxRect != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _BoxPainter(_boxRect!)),
                  ),
                ),
              // Gesture capture
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  onScaleEnd: _onScaleEnd,
                  onTapUp: _tool == _Tool.sidenote
                      ? (d) => _addSidenoteAt(d.localPosition)
                      : null,
                ),
              ),
              // Sidenote markers (above gesture so they stay tappable)
              for (var i = 0; i < _sidenotes.length; i++)
                Positioned(
                  left: _sidenotes[i].pos.dx - 12,
                  top: _sidenotes[i].pos.dy - 12,
                  child: GestureDetector(
                    onTap: () => _openSidenote(i),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33000000), blurRadius: 3),
                        ],
                      ),
                      child: const Icon(Icons.sticky_note_2_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final showColors = _tool == _Tool.pen || _tool == _Tool.highlighter;

    return Material(
      elevation: 8,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm, vertical: Spacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showColors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _penColors.length; i++)
                        GestureDetector(
                          onTap: () => setState(() => _colorIndex = i),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Color(_penColors[i]),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _colorIndex == i
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _toolBtn(Icons.pan_tool_alt_rounded, 'Move', _Tool.move),
                    _toolBtn(Icons.edit_rounded, 'Pen', _Tool.pen),
                    _toolBtn(Icons.brush_rounded, 'Marker', _Tool.highlighter),
                    _toolBtn(
                        Icons.auto_fix_normal_rounded, 'Eraser', _Tool.eraser),
                    _toolBtn(
                        Icons.sticky_note_2_outlined, 'Note', _Tool.sidenote),
                    _toolBtn(Icons.crop_free_rounded, 'Box AI', _Tool.box),
                    const SizedBox(width: 4),
                    Container(
                        width: 1,
                        height: 28,
                        color: theme.colorScheme.outlineVariant),
                    IconButton(
                      tooltip: 'Undo',
                      onPressed: _strokes.isEmpty ? null : _undo,
                      icon: const Icon(Icons.undo_rounded),
                    ),
                    IconButton(
                      tooltip: 'Clear all',
                      onPressed: (_strokes.isEmpty && _sidenotes.isEmpty)
                          ? null
                          : _clearAll,
                      icon: const Icon(Icons.delete_sweep_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, _Tool tool) {
    final selected = _tool == tool;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() {
          _tool = tool;
          if (tool != _Tool.box) _boxRect = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20,
                  color: selected
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                    fontSize: 10,
                    color: selected
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final _Stroke? current;
  _InkPainter(this.strokes, this.current);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in [...strokes, ?current]) {
      final paint = Paint()
        ..color =
            Color(s.colorValue).withValues(alpha: s.highlighter ? 0.32 : 1.0)
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (s.points.length == 1) {
        canvas.drawPoints(ui.PointMode.points, s.points, paint);
        continue;
      }
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (final p in s.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) => true;
}

class _BoxPainter extends CustomPainter {
  final Rect rect;
  _BoxPainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTRB(
      rect.left < rect.right ? rect.left : rect.right,
      rect.top < rect.bottom ? rect.top : rect.bottom,
      rect.left < rect.right ? rect.right : rect.left,
      rect.top < rect.bottom ? rect.bottom : rect.top,
    );
    canvas.drawRect(
        r, Paint()..color = const Color(0xFF7C3AED).withValues(alpha: 0.12));
    canvas.drawRect(
      r,
      Paint()
        ..color = const Color(0xFF7C3AED)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _BoxPainter old) => old.rect != rect;
}

// ── Box-AI vision result sheet ───────────────────────────────────────────────

class _BoxAiSheet extends StatefulWidget {
  final Uint8List png;
  const _BoxAiSheet({required this.png});

  @override
  State<_BoxAiSheet> createState() => _BoxAiSheetState();
}

class _BoxAiSheetState extends State<_BoxAiSheet> {
  final StringBuffer _buf = StringBuffer();
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    const prompt =
        'A student boxed this region of their study notes. Explain the content '
        'shown clearly and concisely for studying. If it includes a diagram, '
        'formula or table, explain what it means. Use Markdown.';
    try {
      await for (final t in OpenAiClient.instance
          .visionStream(prompt, widget.png, maxTokens: 700)) {
        if (!mounted) return;
        setState(() => _buf.write(t));
      }
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('LlmException: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final answer = _buf.toString();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: Spacing.sm),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Spacing.screenPaddingH),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: Spacing.sm),
                    Text('Explain region', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    if (!_done && _error == null)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: Spacing.borderRadiusSm,
                child: Image.memory(widget.png,
                    height: 110, fit: BoxFit.contain),
              ),
              const SizedBox(height: Spacing.sm),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(Spacing.screenPaddingH),
                  child: _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _error!.contains('internet')
                                    ? Icons.wifi_off_rounded
                                    : Icons.error_outline_rounded,
                                size: 40,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: Spacing.sm),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : answer.isEmpty
                          ? Text('Reading the box…',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ))
                          : MarkdownView(data: answer, selectable: true),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SidenoteDialog extends StatefulWidget {
  final String initialText;
  final bool allowDelete;
  final Future<String> Function(String hint)? onAiAssist;
  const _SidenoteDialog({
    required this.initialText,
    this.allowDelete = false,
    this.onAiAssist,
  });

  @override
  State<_SidenoteDialog> createState() => _SidenoteDialogState();
}

class _SidenoteDialogState extends State<_SidenoteDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);
  bool _aiLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ai() async {
    if (widget.onAiAssist == null) return;
    setState(() => _aiLoading = true);
    try {
      final text = await widget.onAiAssist!(_controller.text);
      if (!mounted) return;
      if (text.isNotEmpty) {
        _controller.text = text;
        _controller.selection = TextSelection.collapsed(offset: text.length);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sidenote'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Write a margin note...',
              border: OutlineInputBorder(),
            ),
          ),
          if (widget.onAiAssist != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _aiLoading ? null : _ai,
                icon: _aiLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text(_aiLoading ? 'Writing...' : 'AI assist'),
              ),
            ),
        ],
      ),
      actions: [
        if (widget.allowDelete)
          TextButton(
            onPressed: () => Navigator.of(context).pop(' delete'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
