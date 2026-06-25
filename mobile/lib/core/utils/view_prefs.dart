import 'package:shared_preferences/shared_preferences.dart';

/// User-chosen view scaling, persisted across restarts.
/// - [readScale]    text-size multiplier for reading md/txt notes.
/// - [annotateZoom] page zoom for the annotate canvas (scales text + ink).
/// Loaded once at startup so reads are synchronous.
class ViewPrefs {
  ViewPrefs._();
  static final ViewPrefs instance = ViewPrefs._();

  double readScale = 1.0;
  double annotateZoom = 1.0;

  static const double minRead = 0.7, maxRead = 2.2;
  static const double minZoom = 0.6, maxZoom = 2.5;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    readScale = (p.getDouble('view_read_scale') ?? 1.0).clamp(minRead, maxRead);
    annotateZoom =
        (p.getDouble('view_annotate_zoom') ?? 1.0).clamp(minZoom, maxZoom);
  }

  Future<void> setReadScale(double v) async {
    readScale = v.clamp(minRead, maxRead);
    final p = await SharedPreferences.getInstance();
    await p.setDouble('view_read_scale', readScale);
  }

  Future<void> setAnnotateZoom(double v) async {
    annotateZoom = v.clamp(minZoom, maxZoom);
    final p = await SharedPreferences.getInstance();
    await p.setDouble('view_annotate_zoom', annotateZoom);
  }
}
