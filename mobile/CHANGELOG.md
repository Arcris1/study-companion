# Changelog

All notable changes to StudyCompanion.
Format: [version] — date — change.

## [1.0.4] — 2026-06-24

### Fix — tablet annotate page now uses the full screen width
- `NoteAnnotateScreen._buildPage` removed the 640px width cap that was leaving ~half the tablet screen empty. The page now expands to fill the full available width on tablets/wide screens (text scales up proportionally since the page is rendered at a fixed 400-wide coord system inside `FittedBox`).
