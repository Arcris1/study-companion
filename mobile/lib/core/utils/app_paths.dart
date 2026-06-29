import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves stored file paths against the app's documents directory.
///
/// iOS changes the app container's absolute path across installs/updates, so
/// absolute paths saved in the DB go stale (the file still exists, just at a
/// new path). We store paths **relative** to the documents dir and rebuild the
/// absolute path at read time. Legacy absolute paths are salvaged too.
class AppPaths {
  static String? _docsDir;

  /// Cache the documents dir once at startup (read sites are synchronous).
  static Future<void> init() async {
    _docsDir = (await getApplicationDocumentsDirectory()).path;
  }

  static String? get docsDir => _docsDir;

  /// Converts an absolute path inside the documents dir to a stored relative
  /// path (e.g. "pdfs/123_x.pdf"). Falls back to the input if outside.
  static String toRelative(String absolutePath) {
    final docs = _docsDir;
    if (docs != null && p.isWithin(docs, absolutePath)) {
      return p.relative(absolutePath, from: docs);
    }
    return absolutePath;
  }

  /// Resolves a stored path (relative or legacy absolute) to a usable absolute
  /// path. Returns the input unchanged if it can't be resolved.
  static String? resolve(String? stored) {
    if (stored == null || stored.isEmpty) return stored;
    if (File(stored).existsSync()) return stored; // already valid
    final docs = _docsDir;
    if (docs == null) return stored;

    // Relative path → join with the current documents dir.
    final joined = p.join(docs, stored);
    if (File(joined).existsSync()) return joined;

    // Legacy absolute path → rebuild from the pdfs/ or images/ tail.
    final norm = stored.replaceAll('\\', '/');
    for (final sub in const ['pdfs/', 'images/']) {
      final idx = norm.lastIndexOf(sub);
      if (idx != -1) {
        final candidate = p.join(docs, norm.substring(idx));
        if (File(candidate).existsSync()) return candidate;
      }
    }
    return stored;
  }
}
