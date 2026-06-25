import 'package:flutter/material.dart';
import '../../../config/theme/spacing.dart';

/// A small bottom sheet with a slider (and ± buttons) to choose a view scale.
/// [onChanged] fires live so the underlying view updates as the user drags.
Future<void> showViewScaleSheet(
  BuildContext context, {
  required String title,
  required double value,
  required double min,
  required double max,
  required ValueChanged<double> onChanged,
}) {
  return showModalBottomSheet(
    context: context,
    builder: (_) => _ViewScaleSheet(
      title: title,
      value: value,
      min: min,
      max: max,
      onChanged: onChanged,
    ),
  );
}

class _ViewScaleSheet extends StatefulWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  const _ViewScaleSheet({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_ViewScaleSheet> createState() => _ViewScaleSheetState();
}

class _ViewScaleSheetState extends State<_ViewScaleSheet> {
  late double _v = widget.value;

  void _set(double v) {
    final clamped = double.parse(v.clamp(widget.min, widget.max).toStringAsFixed(2));
    setState(() => _v = clamped);
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divisions = ((widget.max - widget.min) / 0.1).round();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.screenPaddingH,
          Spacing.md,
          Spacing.screenPaddingH,
          Spacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(widget.title, style: theme.textTheme.titleMedium),
                const Spacer(),
                Text('${(_v * 100).round()}%',
                    style: theme.textTheme.titleMedium),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.text_decrease_rounded),
                  onPressed: _v > widget.min ? () => _set(_v - 0.1) : null,
                ),
                Expanded(
                  child: Slider(
                    value: _v,
                    min: widget.min,
                    max: widget.max,
                    divisions: divisions,
                    onChanged: _set,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.text_increase_rounded),
                  onPressed: _v < widget.max ? () => _set(_v + 0.1) : null,
                ),
              ],
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => _set(1.0),
                  child: const Text('Reset'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
