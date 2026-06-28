# Changelog

All notable changes to StudyCompanion.
Format: [version] — date — change.

## [1.7.0] — 2026-06-28

### Feature — Annotate: pinch-to-zoom + scroll to turn pages
- **Pinch-to-zoom** the annotate page with two fingers (zoom is saved); two-finger drag also pans. The 🔍 button still works.
- **PDF page turning by scrolling:** drag past the bottom of a page to go to the next page (and past the top for the previous) — no need to tap the arrows (arrows kept as a fallback).

## [1.6.0] — 2026-06-28

### Feature — Finer pen/marker sizes
- Added two thinner sizes each for the pen (1.0, 1.5) and marker (5, 7) in annotate, for finer writing/highlighting. Size dots now render smaller sizes accurately.

## [1.5.0] — 2026-06-28

### Feature — Import images (OCR)
- Import an image (JPG/PNG/WebP/HEIC/etc.) as a note; the text is extracted with the vision model (OCR) at import.
- The source image is shown above its extracted (Markdown) text in the note; works with summary/quiz/flashcards and chat after building the AI index.
- If no API key is set when importing, the note is created image-only and an "Extract text (OCR)" banner lets you OCR it later.

## [1.3.1] — 2026-06-28

### Fix — PDF/index UI issues
- The AI-index banner no longer overlaps the status bar — it now sits below the app bar (as a header sliver).
- PDF inline preview scrolls smoothly: rendered as a `ListView` of page images instead of the nested PdfViewer (which fought the outer scroll). Pinch-zoom remains in the fullscreen reader.
- Annotate page now scrolls natively (smooth + fling) when the **Move** tool is active; drawing tools still capture one finger and scroll on two.

## [1.3.0] — 2026-06-27

### Feature — Page citations + scanned-PDF OCR
- **Page citations:** AI chat answers now show the source page numbers for PDF notes (e.g. "Lecture 13 · p.12, 42") in the per-answer sources.
- **Scanned-PDF OCR:** PDFs with no selectable text now show "Scanned PDF — Extract text (OCR)" in the note detail. Tapping renders each page and transcribes it with the vision model (capped, with progress); you can then build the AI index and use chat/quiz/flashcards on it.

## [1.2.0] — 2026-06-27

### Feature — On-demand AI (RAG) indexing
- **Imports no longer call AI** — uploading (incl. large PDFs) just extracts + chunks text; it's instant, free, and works offline / without an API key.
- Summary, quiz, flashcards, preview & annotate all work immediately on the raw text.
- **Build AI Index** when you want semantic chat/search: a banner in the note detail (per note, with progress) and an **Index all** prompt in the chat screen (per notebook). Capped + evenly sampled for very large docs.
- Chat still works via keyword search when not indexed; indexing only improves answer quality.

## [1.1.0] — 2026-06-27

### Feature — PDF support (multi-page) with pdfrx
- Import multi-page **PDF** files (copied into app storage); per-page text extraction for AI.
- **Large-file handling:** map-reduce summaries, quiz/flashcard sampling across the whole document, page-aware chunks, embedding cap for very large files.
- **PDF preview:** rendered, zoomable, scrollable page viewer in the note's Content tab + fullscreen reader.
- **Per-page annotation:** draw / highlight / eraser / sidenotes / Box-AI over each rendered PDF page, with a page navigation bar; ink saved per page.

## [1.0.4] — 2026-06-24

### Fix — tablet annotate page now uses the full screen width
- `NoteAnnotateScreen._buildPage` removed the 640px width cap that was leaving ~half the tablet screen empty. The page now expands to fill the full available width on tablets/wide screens (text scales up proportionally since the page is rendered at a fixed 400-wide coord system inside `FittedBox`).
