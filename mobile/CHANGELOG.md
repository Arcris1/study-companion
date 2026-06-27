# Changelog

All notable changes to StudyCompanion.
Format: [version] — date — change.

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
