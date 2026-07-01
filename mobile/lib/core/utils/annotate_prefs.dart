import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which notes were last left in "annotate" mode, so reopening a note
/// returns to the annotate page. Loaded once at startup so the check is sync
/// (no preview flash before redirect).
class AnnotatePrefs {
  AnnotatePrefs._();
  static final AnnotatePrefs instance = AnnotatePrefs._();

  static const _key = 'annotate_mode_notes';
  static const _penOnlyKey = 'annotate_pen_only';
  final Set<int> _notes = {};

  /// When true, only a stylus draws; a finger scrolls/pans (palm rejection).
  bool _penOnly = false;
  bool get penOnly => _penOnly;

  Future<void> setPenOnly(bool value) async {
    _penOnly = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_penOnlyKey, value);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? const [];
    _notes
      ..clear()
      ..addAll(list.map(int.tryParse).whereType<int>());
    _penOnly = prefs.getBool(_penOnlyKey) ?? false;
  }

  bool isAnnotate(int noteId) => _notes.contains(noteId);

  Future<void> setAnnotate(int noteId, bool value) async {
    if (value) {
      _notes.add(noteId);
    } else {
      _notes.remove(noteId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _notes.map((e) => e.toString()).toList(),
    );
  }
}
