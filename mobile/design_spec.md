# StudyCompanion UI/UX Design Specification

> **Version:** 1.0
> **Last Updated:** 2026-03-18
> **Target:** Flutter (Android + iOS)
> **Audience:** College students, ages 18-25
> **Design Philosophy:** Clean academic aesthetics with playful AI personality. Inspired by Linear's precision, Notion's content focus, Duolingo's gamified feedback, and ChatGPT's conversational warmth. Every surface should feel like a well-organized desk in a beautiful library.

---

## 1. Design System

### 1.1 Color Palette

#### Primary Gradient (Brand)
| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#7C3AED` | Buttons, active states, links |
| `primaryLight` | `#A78BFA` | Hover states, secondary emphasis |
| `primaryDark` | `#5B21B6` | Pressed states, headers |
| `primaryGradientStart` | `#7C3AED` | Gradient left/top |
| `primaryGradientEnd` | `#4F46E5` | Gradient right/bottom (indigo) |
| `primaryGradientAngle` | 135deg | Top-left to bottom-right |

The primary gradient is `LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)])`.

#### Light Theme
| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#F8F7FF` | Scaffold background (very faint purple tint) |
| `surface` | `#FFFFFF` | Cards, sheets, dialogs |
| `surfaceVariant` | `#F3F0FF` | Alternate card backgrounds, input fills |
| `surfaceContainer` | `#EEEAFF` | Grouped sections, chip backgrounds |
| `surfaceContainerHigh` | `#E5E0F5` | Pressed card states, dividers |
| `onBackground` | `#1A1625` | Primary text |
| `onSurface` | `#1A1625` | Body text on cards |
| `onSurfaceVariant` | `#6B6580` | Secondary/caption text |
| `outline` | `#D4D0E0` | Borders, dividers |
| `outlineVariant` | `#E8E5F0` | Subtle borders |

#### Dark Theme (Rich purple-tinted darks, NOT gray)
| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#0F0B1A` | Scaffold background (deep indigo-black) |
| `surface` | `#1A1528` | Cards, sheets, dialogs |
| `surfaceVariant` | `#221C35` | Alternate card backgrounds, input fills |
| `surfaceContainer` | `#2A2340` | Grouped sections, chip backgrounds |
| `surfaceContainerHigh` | `#332B4D` | Pressed card states |
| `onBackground` | `#F0ECF9` | Primary text |
| `onSurface` | `#F0ECF9` | Body text on cards |
| `onSurfaceVariant` | `#9B93B0` | Secondary/caption text |
| `outline` | `#3D3555` | Borders, dividers |
| `outlineVariant` | `#2E2745` | Subtle borders |

#### Semantic Colors
| Token | Light Hex | Dark Hex | Usage |
|-------|-----------|----------|-------|
| `success` | `#10B981` | `#34D399` | Correct answers, completed states |
| `successContainer` | `#D1FAE5` | `#064E3B` | Success backgrounds |
| `error` | `#EF4444` | `#F87171` | Errors, incorrect, destructive |
| `errorContainer` | `#FEE2E2` | `#7F1D1D` | Error backgrounds |
| `warning` | `#F59E0B` | `#FBBF24` | Warnings, medium difficulty |
| `warningContainer` | `#FEF3C7` | `#78350F` | Warning backgrounds |
| `info` | `#3B82F6` | `#60A5FA` | Informational, B-grade |
| `infoContainer` | `#DBEAFE` | `#1E3A5F` | Info backgrounds |

#### Quiz-Specific Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `quizCorrect` | `#10B981` | Correct answer highlight |
| `quizCorrectBg` | `#D1FAE5` (light) / `#064E3B` (dark) | Correct answer card fill |
| `quizIncorrect` | `#EF4444` | Incorrect answer highlight |
| `quizIncorrectBg` | `#FEE2E2` (light) / `#7F1D1D` (dark) | Incorrect answer card fill |
| `quizUnanswered` | `#9CA3AF` | Unanswered dot indicator |
| `quizUnansweredBg` | `#F3F4F6` (light) / `#1F2937` (dark) | Unanswered card fill |

#### Grade Colors
| Grade | Hex |
|-------|-----|
| A (90-100%) | `#10B981` (success green) |
| B (80-89%) | `#3B82F6` (info blue) |
| C (70-79%) | `#F59E0B` (warning amber) |
| D (60-69%) | `#F97316` (orange) |
| F (<60%) | `#EF4444` (error red) |

#### Difficulty Colors
| Level | Hex | Usage |
|-------|-----|-------|
| Easy | `#10B981` | Green pill badge |
| Medium | `#F59E0B` | Amber pill badge |
| Hard | `#EF4444` | Red pill badge |

#### Notebook Preset Colors (12 choices)
```
#7C3AED  (Purple - default)
#4F46E5  (Indigo)
#3B82F6  (Blue)
#06B6D4  (Cyan)
#10B981  (Emerald)
#84CC16  (Lime)
#F59E0B  (Amber)
#F97316  (Orange)
#EF4444  (Red)
#EC4899  (Pink)
#8B5CF6  (Violet)
#6366F1  (Slate Indigo)
```

#### Accent / Highlight
| Token | Hex | Usage |
|-------|-----|-------|
| `accent` | `#EC4899` | Special highlights, pro features |
| `highlight` | `#FBBF24` | Star ratings, favorited items |
| `aiGlow` | `#A78BFA` | AI-related shimmer/glow effects |

---

### 1.2 Typography

#### Font Family
- **Primary:** `Inter` (Google Fonts) -- already in use, excellent for UI readability
- **Monospace:** `JetBrains Mono` (for code snippets in notes, chunk counts)
- **Fallback:** System default sans-serif

#### Type Scale
| Token | Size (sp) | Weight | Line Height | Letter Spacing | Usage |
|-------|-----------|--------|-------------|----------------|-------|
| `displayLarge` | 40 | 700 (Bold) | 1.2 | -0.5 | Score gauge number |
| `displayMedium` | 34 | 700 (Bold) | 1.2 | -0.25 | Grade letter |
| `displaySmall` | 28 | 600 (SemiBold) | 1.3 | 0 | Onboarding titles |
| `headlineLarge` | 24 | 700 (Bold) | 1.3 | 0 | Screen titles (Model Download) |
| `headlineMedium` | 22 | 700 (Bold) | 1.3 | 0 | Section headers |
| `headlineSmall` | 20 | 600 (SemiBold) | 1.3 | 0 | Card group titles |
| `titleLarge` | 18 | 600 (SemiBold) | 1.4 | 0 | AppBar titles |
| `titleMedium` | 16 | 600 (SemiBold) | 1.4 | 0.1 | Card titles, question text |
| `titleSmall` | 14 | 600 (SemiBold) | 1.4 | 0.1 | Section labels, form labels |
| `bodyLarge` | 16 | 400 (Regular) | 1.6 | 0.15 | Primary body copy |
| `bodyMedium` | 14 | 400 (Regular) | 1.5 | 0.15 | Default body text, messages |
| `bodySmall` | 12 | 400 (Regular) | 1.5 | 0.2 | Descriptions, subtitles |
| `labelLarge` | 14 | 500 (Medium) | 1.4 | 0.1 | Button text |
| `labelMedium` | 12 | 500 (Medium) | 1.4 | 0.5 | Chip text, tab labels |
| `labelSmall` | 11 | 500 (Medium) | 1.4 | 0.5 | Metadata, timestamps |
| `caption` | 10 | 400 (Regular) | 1.3 | 0.4 | Fine print, counters |

---

### 1.3 Spacing & Layout

#### Base Grid: 4px

#### Spacing Scale
| Token | Value | Usage |
|-------|-------|-------|
| `space2` / `xxs` | 2px | Icon-text micro gap |
| `space4` / `xs` | 4px | Tight inline spacing, dot gaps |
| `space6` | 6px | Chip internal padding vertical |
| `space8` / `sm` | 8px | Small gaps, inline elements, list item spacing |
| `space12` | 12px | Card internal section gaps, button icon gap |
| `space16` / `md` | 16px | Standard content padding, field gaps |
| `space20` | 20px | Card internal padding |
| `space24` / `lg` | 24px | Section separators, card padding large |
| `space32` / `xl` | 32px | Large section gaps |
| `space40` | 40px | Major section separators |
| `space48` / `xxl` | 48px | Screen section spacing, onboarding gaps |
| `space64` | 64px | Onboarding illustration spacing |

#### Layout Constants
| Token | Value | Usage |
|-------|-------|-------|
| `screenPaddingH` | 20px | Horizontal screen padding (was 16, increased for breathing room) |
| `screenPaddingV` | 16px | Vertical screen padding |
| `cardPadding` | 16px | Internal card padding |
| `cardPaddingLarge` | 20px | Feature cards, quiz cards |
| `sectionGap` | 24px | Gap between major sections |
| `listItemGap` | 12px | Gap between list/grid items |
| `bottomNavHeight` | 64px | Bottom navigation bar |
| `fabBottomMargin` | 16px | FAB distance from bottom |
| `inputHeight` | 48px | Standard text field height |
| `buttonHeight` | 48px | Standard button height |
| `buttonHeightSmall` | 36px | Compact buttons |

#### Border Radii
| Token | Value | Usage |
|-------|-------|-------|
| `radiusXs` | 4px | Progress bars, tiny elements |
| `radiusSm` | 8px | Buttons, text fields, inline chips |
| `radiusMd` | 12px | Cards, dialogs, sheets |
| `radiusLg` | 16px | Chat bubbles, large cards |
| `radiusXl` | 20px | Bottom sheets, image containers |
| `radiusPill` | 999px | Pills, circular chips, FAB |
| `radiusCircle` | 50% | Avatars, color swatches |

---

### 1.4 Elevation & Depth

#### Shadow Definitions
```dart
// Shadow Level 1 - Cards at rest
BoxShadow(
  color: Color(0x0A000000),  // 4% black
  blurRadius: 8,
  offset: Offset(0, 2),
)

// Shadow Level 2 - Hovered cards, elevated elements
BoxShadow(
  color: Color(0x0F000000),  // 6% black
  blurRadius: 16,
  offset: Offset(0, 4),
)
// + inner subtle glow for primary elements:
BoxShadow(
  color: Color(0x147C3AED),  // 8% primary
  blurRadius: 24,
  offset: Offset(0, 8),
)

// Shadow Level 3 - Modals, dialogs, FAB
BoxShadow(
  color: Color(0x1A000000),  // 10% black
  blurRadius: 24,
  offset: Offset(0, 8),
),
BoxShadow(
  color: Color(0x0D000000),  // 5% black
  blurRadius: 4,
  offset: Offset(0, 2),
)

// Shadow Level 4 - Bottom navigation, floating elements
BoxShadow(
  color: Color(0x1F000000),
  blurRadius: 32,
  offset: Offset(0, -4),
)
```

**Dark mode shadows:** Replace black-based shadows with `Color(0x33000000)` (20% black) and add a subtle `Color(0x0A7C3AED)` (4% primary) glow to interactive elements.

#### Glassmorphism Specs
Used for: Loading overlay, onboarding cards, special feature cards.
```dart
// Glass surface
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
)
// Container decoration
BoxDecoration(
  color: Colors.white.withOpacity(0.08),         // light: 0.65
  borderRadius: BorderRadius.circular(16),
  border: Border.all(
    color: Colors.white.withOpacity(0.15),        // light: 0.25
    width: 1,
  ),
)
```

#### Gradient Definitions
```dart
// Primary gradient (brand, buttons, user bubbles)
primaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
);

// Onboarding page 1: Import
onboarding1Gradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5), Color(0xFF312E81)],
);

// Onboarding page 2: AI
onboarding2Gradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF6D28D9), Color(0xFF4338CA), Color(0xFF1E1B4B)],
);

// Onboarding page 3: Offline
onboarding3Gradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF5B21B6), Color(0xFF3730A3), Color(0xFF1E1B4B)],
);

// Success gradient (quiz A-grade background)
successGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF10B981), Color(0xFF059669)],
);

// Surface gradient (subtle card sheen, light mode only)
surfaceGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFFFFFF), Color(0xFFF8F7FF)],
);

// AI shimmer gradient (for loading/generating states)
aiShimmerGradient = LinearGradient(
  colors: [Color(0xFF7C3AED), Color(0xFFA78BFA), Color(0xFF7C3AED)],
);

// Notebook card color overlay (use notebook color at 12% opacity over surface)
```

---

### 1.5 Motion & Animation

#### Duration Tokens
| Token | Duration | Usage |
|-------|----------|-------|
| `durationFast` | 150ms | Micro-interactions: button press, toggle, opacity |
| `durationMedium` | 300ms | Page transitions, card reveal, tab switch |
| `durationSlow` | 500ms | Onboarding transitions, score animation wind-up |
| `durationEmphasis` | 800ms | Confetti, score gauge fill, celebration |
| `durationSpring` | 600ms | Bouncy FAB reveal, expandable elements |

#### Easing Curves
| Token | Curve | Usage |
|-------|-------|-------|
| `easeOut` | `Curves.easeOutCubic` | Elements entering (fade in, slide in) |
| `easeIn` | `Curves.easeInCubic` | Elements exiting (fade out, slide out) |
| `easeInOut` | `Curves.easeInOutCubic` | Symmetric transitions (page swipe) |
| `spring` | `Curves.elasticOut` | Playful bounces (FAB, score gauge) |
| `decelerate` | `Curves.decelerate` | Content settling into place |
| `overshoot` | `Curves.easeOutBack` | Attention-drawing pop-in (badges, dots) |

#### Page Transitions
- **Forward navigation:** Slide in from right + fade in (300ms, easeOutCubic)
- **Back navigation:** Slide out to right + fade out (250ms, easeInCubic)
- **Modal/bottom sheet:** Slide up from bottom + fade in (300ms, easeOutCubic)
- **Tab switch:** Cross-fade (200ms, easeInOut)

#### Micro-Interactions
| Element | Animation |
|---------|-----------|
| Button press | Scale to 0.97 (150ms ease-in), release to 1.0 (150ms ease-out) |
| Card tap | Subtle scale to 0.98 + shadow reduce (150ms) |
| Color swatch select | Scale to 1.15 then 1.0 (300ms spring) + checkmark fade in (200ms) |
| FAB expand | Stagger children at 50ms intervals, rotate main icon 45deg (300ms spring) |
| Chip select | Background fill sweep from left (200ms ease-out) |
| Progress bar fill | Animated width (500ms ease-out) |
| Score gauge | 0 to final score (800ms ease-out with overshoot) |
| Confetti | 80 particles, 2s duration, gravity + random velocity |
| Typing indicator dots | 3 dots, staggered bounce at 200ms intervals, 1s cycle |
| Streaming text | Per-word fade in with 50ms stagger |
| Pagination dot | Active: expand width 8->24px (300ms ease-out). Inactive: shrink 24->8px |
| Tab indicator | Slide (300ms ease-in-out) |
| Empty state icon | Slow pulse scale 1.0->1.05->1.0 (2s loop, ease-in-out) |

---

## 2. Screen-by-Screen Specifications

### 2.1 Onboarding Screen (3 pages)

**Layout:** Full-screen `PageView` with gradient backgrounds, no AppBar.

**Background per page:**
- Page 1: `onboarding1Gradient` (purple-to-indigo-to-deep)
- Page 2: `onboarding2Gradient` (violet-to-blue-to-navy)
- Page 3: `onboarding3Gradient` (deep purple-to-indigo-to-night)

**Content (centered vertically, 20px horizontal padding):**
- **Illustration area** (top 40% of content area):
  - Composed icon inside a frosted-glass circle:
    - Circle: 160x160px, glassmorphism surface (white at 10% opacity, blur 20, 1px white-15% border)
    - Icon: 72px, `Colors.white`
    - Outer ring: 180x180px, 2px border of `Colors.white.withOpacity(0.15)`, dashed via CustomPainter
  - Floating accent shapes around the circle:
    - 3 small circles (12px, 8px, 6px) at random offsets, white at 20% opacity
    - Gentle floating animation: translate Y by +/-8px over 3s, staggered starts
  - Page 1 icon: `Icons.auto_stories`
  - Page 2 icon: `Icons.psychology`
  - Page 3 icon: `Icons.wifi_off`

- **Title** (48px below illustration):
  - Style: `displaySmall` (28sp, SemiBold)
  - Color: `Colors.white`
  - Text align: center

- **Description** (16px below title):
  - Style: `bodyLarge` (16sp, Regular)
  - Color: `Colors.white.withOpacity(0.8)`
  - Text align: center
  - Max width: 300px (centered)

**Pagination dots (24px below description):**
- Container: Row, centered, 4px horizontal spacing between dots
- Active dot: 24px wide x 8px tall, `Colors.white`, radiusPill
- Inactive dot: 8px x 8px, `Colors.white.withOpacity(0.35)`, radiusPill
- Transition: `AnimatedContainer` 300ms ease-out

**Bottom area (pinned to bottom, 20px padding, 16px above safe area):**
- Last page only:
  - Full-width `ScButton` with variant `gradient` (NOT elevated):
    - Label: "Get Started"
    - Icon: `Icons.arrow_forward_rounded`
    - Background: White, text: `primaryDark`
    - Height: 52px, radiusPill
    - Shadow level 2
- Other pages:
  - Left: `TextButton` "Skip" -- color `Colors.white.withOpacity(0.7)`, no background
  - Right: `ScButton` variant `secondary` on dark:
    - Label: "Next"
    - Background: `Colors.white.withOpacity(0.15)`, text: `Colors.white`
    - Height: 44px, radiusPill, border: 1px white at 20%

---

### 2.2 Model Download Screen

**AppBar:** None. Custom header area.

**Header (top, 32px top padding from safe area, 20px horizontal):**
- Title: "Download AI Model" -- `headlineLarge`, `onBackground`
- Subtitle (8px below): "Choose a model to power your study companion. You can change this later." -- `bodyMedium`, `onSurfaceVariant`

**Model cards (32px below subtitle, 12px vertical gap between cards):**
Each card:
- Container: `surface` background, radiusMd (12px), shadow level 1, 16px padding
- Top row:
  - Left: 40x40px container, `primaryGradient` background, radiusSm (8px), centered `Icons.memory` 20px white icon
  - 12px gap
  - Column:
    - Model name: `titleSmall` (14sp SemiBold)
    - Size label: `labelSmall`, `onSurfaceVariant`
  - Right: Size badge -- Container with `surfaceContainer` background, radiusPill, 8px H / 4px V padding, text: `labelSmall` bold
- Description (8px below top row): `bodySmall`, `onSurfaceVariant`
- Action area (12px below description):
  - If downloading:
    - Linear progress bar: 8px height, radiusXs (4px), primaryGradient as value color, `surfaceContainer` as track
    - Percentage text (4px below): `labelSmall`, `onSurfaceVariant`, e.g. "47.3%"
  - If not downloading:
    - `ScButton` outlined variant, label "Download", icon `Icons.download`
  - If downloaded: Chip with checkmark icon, label "Downloaded", `successContainer` background

**Bottom area (pinned):**
- `ScButton`:
  - If model active: filled variant, label "Continue", icon `Icons.arrow_forward_rounded`
  - If no model: outlined variant, label "Skip for now"
- 16px bottom padding

---

### 2.3 Home Dashboard

**AppBar:** Transparent, no elevation.

**Greeting header (replaces current plain title):**
- Top safe area + 20px
- Row:
  - Left column:
    - Greeting: "Good evening, Student!" -- `headlineMedium` (22sp Bold)
      - Time-based: "Good morning" (5-12), "Good afternoon" (12-17), "Good evening" (17-5)
    - Subtitle (4px below): "Ready to study?" -- `bodyMedium`, `onSurfaceVariant`
  - Right: 44x44px circular avatar placeholder
    - `surfaceContainer` background, `Icons.person_rounded` 24px `onSurfaceVariant`
    - Tap navigates to Settings
- Actions row aligned to avatar position:
  - If no model: Warning icon button (as current)

**Quick stats row (20px below greeting, 20px horizontal padding):**
- Row of 3 stat cards, 12px gap between them, each `Expanded`:
  - Container: `surface` background, radiusMd (12px), shadow level 1, 16px padding
  - Icon: 20px, color = per-stat accent (notebooks=primary, notes=info, quizzes=success)
  - Value (4px below icon): `headlineSmall` (20sp SemiBold), `onSurface`
  - Label (2px below): `caption` (10sp), `onSurfaceVariant`
  - Stats:
    - Notebooks: `Icons.menu_book_rounded`, count, "Notebooks"
    - Notes: `Icons.description_rounded`, count, "Notes"
    - Quizzes: `Icons.quiz_rounded`, count, "Quizzes"

**Notebook grid (24px below stats, 20px horizontal padding):**
- Section header row:
  - Left: "Your Notebooks" -- `titleMedium` (16sp SemiBold)
  - Right: "See All" text button if > 4 notebooks -- `labelMedium`, `primary`
- Grid: 2 columns, `SliverGrid` or `GridView`, 12px cross-axis spacing, 12px main-axis spacing
- Each notebook card:
  - Container: `surface` background, radiusMd (12px), shadow level 1
  - Top: 4px tall color accent bar (notebook color), spans full width, top-left and top-right corners radiusMd
  - Content (16px padding below bar):
    - Icon container: 36x36px, notebook color at 12% opacity background, radiusSm (8px), centered `Icons.menu_book_rounded` 18px in notebook color
    - Title (12px below icon): `titleSmall` (14sp SemiBold), maxLines 2, ellipsis
    - Note count (4px below title): `labelSmall`, `onSurfaceVariant`, e.g. "5 notes"
  - Entire card is tappable via InkWell with radiusMd

**Empty state (when no notebooks):**
- Centered `EmptyStateWidget` (redesigned, see Component Specs 3.4)

**Bottom Navigation Bar:**
- Container: `surface` background, shadow level 4 (upward shadow), 0px border radius (flat top)
- Height: 64px + safe area bottom
- 5 items, evenly distributed:
  1. `Icons.home_rounded` / `Icons.home_outlined` -- "Home" (active)
  2. `Icons.search_rounded` -- "Search" (disabled/placeholder, 40% opacity)
  3. Center: FAB slot (see below)
  4. `Icons.insights_rounded` -- "Activity" (disabled/placeholder, 40% opacity)
  5. `Icons.settings_rounded` / `Icons.settings_outlined` -- "Settings"
- Active item: `primary` color, label visible
- Inactive item: `onSurfaceVariant` at 60% opacity, label hidden
- Label: `caption` (10sp Medium)
- Center FAB:
  - 56x56px, `primaryGradient` background, radiusCircle
  - Shadow level 2 + primary glow: `BoxShadow(color: Color(0x337C3AED), blurRadius: 16, offset: Offset(0, 4))`
  - Icon: `Icons.add_rounded`, 28px, white
  - Tap: navigate to Create Notebook
  - Elevated -8px above the bar baseline (overlapping)

---

### 2.4 Create Notebook Screen

**AppBar:** "Create Notebook" -- `titleLarge`, back arrow

**Body (SingleChildScrollView, 20px horizontal padding, 24px top):**

**Title field:**
- `ScTextField` with floating label "Notebook Title"
- Hint: "e.g., Biology 101"
- Autofocus: true
- Below field (4px): Character count aligned right -- `caption`, `onSurfaceVariant`
  - Format: "12/50" -- turns `warning` at 40+, `error` at 50
  - Animated counter via `AnimatedSwitcher` (150ms fade)

**Description field (16px below):**
- `ScTextField` with floating label "Description (optional)"
- Hint: "What is this notebook about?"
- maxLines: 3
- Below field (4px): Character count "0/200"

**Color picker (24px below):**
- Label: "Color" -- `titleSmall`
- 12px below label
- Wrap with 12px spacing, 12px runSpacing
- Each swatch:
  - 44x44px circle (BoxShape.circle)
  - Filled with the preset color
  - If selected:
    - 3px white border (or `onSurface` in light mode)
    - Outer 2px ring in the same color at 40% (total visual: color -> white gap -> color ring)
    - Centered checkmark: `Icons.check_rounded`, 20px, white
    - Entry animation: Scale 0.8->1.0 (200ms spring) + checkmark fade-in (150ms)
  - If not selected:
    - No border
    - On tap: spring scale animation (100ms)

**Save button (32px below color picker):**
- Full-width `ScButton` gradient variant
- Label: "Create Notebook"
- Icon: `Icons.add_rounded`
- Loading state: spinner replaces icon+label, gradient dims to 70%
- Disabled if title is empty: opacity 0.5, no gradient (flat `surfaceContainer`)

---

### 2.5 Notebook Detail Screen

**Header (replaces standard AppBar):**
- SliverAppBar with expandedHeight: 140px
- Background: LinearGradient using notebook color as base:
  - `Color(notebookColor)` -> `Color(notebookColor).withOpacity(0.7)` overlaid on `primaryDark`
- Collapsed: Standard height, notebook title in `titleLarge` white
- Expanded:
  - Bottom-left: Notebook title in `headlineMedium` white
  - Below title: "{n} notes" `labelMedium` white at 80%
- Actions: PopupMenuButton (delete, edit) -- white icons
- Pinned: true

**Tab Selector (below header, pinned):**
- NOT a default TabBar. Custom chip-based horizontal scrollable row:
  - Container: 12px vertical padding, 20px horizontal padding, `background` color
  - 3 chips in a Row with 8px spacing:
    - Each chip: `FilterChip`-style but custom:
      - Active: `primary` background, white text, shadow level 1
      - Inactive: `surfaceContainer` background, `onSurfaceVariant` text, no shadow
      - Size: 36px tall, 16px horizontal padding, radiusPill
      - Icon (left of label): 16px
        - Notes: `Icons.description_rounded`
        - Quizzes: `Icons.quiz_rounded`
        - Chat: `Icons.chat_rounded`
      - Label: `labelMedium` (12sp Medium)
      - Count badge (right of label): small circle 18px diameter, `accent` background, white text `caption`
    - Transition: background color fill 200ms ease-out

**Notes Tab content:**
- Staggered card grid would be ideal but for simplicity: `ListView` with `NoteCard` widgets
- Each `NoteCard`: see Component Spec 3.5 (redesigned)
- 12px bottom margin between cards
- 20px horizontal padding

**Quizzes Tab content:**
- `ListView` of quiz cards
- Each quiz card:
  - Container: `surface`, radiusMd, shadow level 1, 16px padding
  - Row:
    - Left: 40x40px container, difficulty color at 12% background, radiusSm, `Icons.quiz_rounded` 20px in difficulty color
    - 12px gap
    - Column:
      - Title: `titleSmall`
      - Subtitle: `bodySmall`, `onSurfaceVariant` -- e.g. "10 questions - Multiple Choice"
    - Right column:
      - Difficulty pill badge: radiusPill, 8px H / 4px V padding, difficulty color bg at 15%, text in difficulty color, `labelSmall` Medium
      - Chevron: `Icons.chevron_right`, `onSurfaceVariant`
  - 8px bottom margin

**Chat Tab content:**
- `ListView` of chat session cards
- Each card:
  - Container: `surface`, radiusMd, shadow level 1, 16px padding
  - Row:
    - Left: 40x40px `surfaceContainer`, radiusSm, `Icons.chat_bubble_outline_rounded` 20px `primary`
    - 12px gap
    - Column:
      - Title: `titleSmall`
      - Subtitle: `labelSmall`, `onSurfaceVariant` -- "{n} messages"
    - Right: Chevron
  - 8px bottom margin

**Speed Dial FAB (replaces single FAB):**
- Main button: 56x56px, `primaryGradient`, radiusCircle, `Icons.add_rounded` 28px white
- On tap: rotate icon 45deg (becoming X) over 300ms spring, reveal sub-action buttons above:
  - Staggered from bottom, 50ms apart, slide up + fade in from 0px to final offset
  - Each sub-button: 44x44px, `surface`, radiusCircle, shadow level 2
    - With a label chip to the left: `surfaceContainer` bg, radiusPill, 8px H / 4px V padding, `labelSmall`
  - Sub-actions depend on active tab:
    - Notes tab:
      - "Import File" -- `Icons.upload_file_rounded`, navigates to NoteImport
      - "Write Note" -- `Icons.edit_rounded`, navigates to NoteImport manual tab
    - Quizzes tab:
      - "Create Quiz" -- `Icons.auto_awesome_rounded`, navigates to QuizConfig
    - Chat tab:
      - "New Chat" -- `Icons.chat_rounded`, creates new session
- Backdrop: semi-transparent black (15%) that dismisses on tap, 200ms fade
- **BUG FIX REQUIRED:** The current FAB uses `DefaultTabController.of(context).index` in `build()`, which reads the initial index (0) and never updates. Fix: wrap in `AnimatedBuilder(animation: DefaultTabController.of(context), ...)` or use a `ValueListenableBuilder` with the tab controller's `animation` property. Alternatively, convert to StatefulWidget and listen to tab changes.

---

### 2.6 Note Import Screen

**AppBar:** "Add Note" -- `titleLarge`, back arrow

**Tab selector (in AppBar bottom):**
- Custom chip-based (matching Notebook Detail style), NOT default TabBar
- 2 chips: "Import File" (icon: `Icons.upload_file_rounded`), "Write Manually" (icon: `Icons.edit_rounded`)

**Import File Tab:**

**Drop zone (centered, 20px padding):**
- Container:
  - `surfaceVariant` fill (dashed border area)
  - Dashed border: 2px, `primary` at 40%, dash pattern: 8px on / 6px off
    - Implement with `CustomPainter` using `Path.dashPath` or `dotted_border` package
  - radiusLg (16px)
  - Width: full - 40px, height: 240px
  - Pulsing animation: border opacity cycles 30%->60%->30% over 2s, ease-in-out loop
- Interior (centered column):
  - Animated icon: `Icons.cloud_upload_outlined`, 64px, `primary` at 60%
    - Gentle float: translateY 0->-8->0 over 2s loop
  - 20px below: "Tap to import a document" -- `titleMedium`, `onSurface`
  - 8px below: "Supports PDF, TXT, and Markdown" -- `bodySmall`, `onSurfaceVariant`
  - 16px below: File type badges row, 8px spacing:
    - Each badge: `surfaceContainer` bg, radiusSm (8px), 10px H / 6px V padding
      - Icon: 14px + label: `labelSmall` Medium
      - PDF: `Icons.picture_as_pdf_rounded`, red-500 tint
      - TXT: `Icons.text_snippet_rounded`, blue-500 tint
      - MD: `Icons.article_rounded`, green-500 tint

**Import progress state (replaces drop zone when importing):**
- Card: `surface`, radiusMd, shadow level 1, 24px padding, centered
- Animated steps column (each step is a row):
  - Step indicator: 24px circle, numbered
    - Completed: `success` bg, white checkmark
    - Current: `primary` bg with pulsing ring animation, white number
    - Pending: `surfaceContainer` bg, `onSurfaceVariant` number
  - Connecting line between steps: 2px wide, 24px tall, completed=`success`, pending=`outline`
  - Steps:
    1. "Reading file..." -> "File loaded"
    2. "Extracting text..." -> "Text extracted"
    3. "Chunking content..." -> "Content chunked"
    4. "Ready to study!"
  - 12px gap between step indicator and label
  - Label: `bodyMedium`, current step is `onSurface`, others are `onSurfaceVariant`
- File name below steps: `labelSmall`, `onSurfaceVariant`, truncated with ellipsis

**Write Manually Tab (20px padding):**
- Title field: `ScTextField` floating label "Title", hint "Note title"
- 16px gap
- Content field: `ScTextField` floating label "Content", hint "Paste or type your study notes here..."
  - maxLines: 15
  - Min height: 300px
  - Styled to feel like a text editor: slightly larger font (`bodyLarge`), line height 1.8
  - Subtle left border: 2px `primary` at 20%, as a "page margin" feel
- 24px gap
- `ScButton` gradient variant, "Create Note", icon `Icons.save_rounded`

---

### 2.7 Note Detail Screen

**AppBar (pinned SliverAppBar):**
- Title: Note title, `titleLarge`, truncated with ellipsis
- Collapsed height: standard
- No expansion

**Tab selector (AppBar bottom):**
- 2 chips: "Content" (icon: `Icons.description_rounded`), "Summary" (icon: `Icons.auto_awesome_rounded`)

**Content Tab:**
- Top row (20px padding, 8px below tabs):
  - Left: `ProcessingIndicator` chip (see Component Spec 3.6)
  - Right: chunk count -- `labelSmall` monospace, `onSurfaceVariant`, e.g. "12 chunks"
- 16px below: Note content
  - `SelectableText`, `bodyMedium`, lineHeight 1.7
  - Good reading typography: 20px horizontal padding for comfortable line length
  - Paragraph spacing: detect double newlines, render with 16px bottom margin per paragraph

**Summary Tab:**

**State 1: No summary generated (centered):**
- Container: `surfaceVariant` bg, radiusLg (16px), 32px padding, max-width 280px, centered
- Sparkle icon: `Icons.auto_awesome_rounded`, 48px, `primaryGradient` shader mask (gradient-colored icon)
- 16px below: "AI Summary" -- `titleMedium`, `onSurface`
- 8px below: "Generate a concise summary of your notes" -- `bodySmall`, `onSurfaceVariant`, text-align center
- 24px below: `ScButton` gradient variant, "Generate Summary", icon `Icons.auto_awesome_rounded`
  - On tap: button transforms:
    1. Label changes to "Generating..." (200ms cross-fade)
    2. Icon replaced with AI shimmer animation (pulsing gradient)
    3. Button width stays fixed (not expanded/contracted)

**State 2: Generating (centered):**
- AI shimmer skeleton loading:
  - 5 horizontal bars at varying widths (100%, 85%, 92%, 78%, 60%)
  - Each bar: 12px tall, radiusSm, shimmer gradient animation sweeping left-to-right
  - Shimmer gradient: `surfaceContainer` -> `surfaceVariant` -> `surfaceContainer`
  - 8px gap between bars
- Below skeleton: "Analyzing your notes..." -- `labelMedium`, `primary`, pulsing opacity 60%->100%

**State 3: Summary ready (scroll):**
- Fade-in animation: 500ms ease-out, from opacity 0 + translateY 16px
- Content: `SelectableText`, `bodyMedium`, lineHeight 1.7, 20px horizontal padding
- Top: Small label row -- "AI Generated" badge (`surfaceContainer` bg, `Icons.auto_awesome` 12px `primary`, `labelSmall` `primary`, radiusPill, 8px H / 4px V)

---

### 2.8 Chat Screen

**AppBar:** "Ask AI" -- `titleLarge`, back arrow, info icon button (as current)

**Background:**
- Subtle pattern: Tiny dots grid at 1% opacity, 24px spacing -- via CustomPainter
- Or simpler: `background` base with a very faint radial gradient centered at top: `primary` at 3% opacity, 400px radius

**Message area (Expanded ListView, 20px horizontal padding, 12px vertical padding):**

**Empty state (no messages):**
- Centered:
  - `Icons.chat_bubble_outline_rounded`, 56px, `onSurfaceVariant` at 25%
  - 16px below: "Ask a question about your notes" -- `bodyLarge`, `onSurfaceVariant`
  - 8px below: "I'll search your notes and give you answers" -- `bodySmall`, `onSurfaceVariant` at 70%
  - 24px below: 3 suggestion chips in a `Wrap`, 8px spacing:
    - Each chip: `surfaceContainer` bg, `outline` border (1px), radiusPill, 12px H / 8px V padding
    - Text: `labelMedium`, `onSurface`
    - Suggestions: "Summarize key concepts", "Explain [topic]", "Quiz me on this"
    - Tap: inserts text into input field

**User message bubble:**
- Align: right
- Margin: left 64px, right 0, bottom 8px
- Container: `primaryGradient` background, shadow level 1
- Border radius: TL 16, TR 16, BL 16, BR 4 (tail on bottom-right)
- Padding: 14px H, 10px V
- Text: `bodyMedium`, white, lineHeight 1.5
- Timestamp (below bubble, right-aligned): `caption`, `onSurfaceVariant` at 50%, format "2:34 PM"

**AI message bubble:**
- Align: left
- Row:
  - AI avatar: 28x28px circle, `primaryGradient` background, `Icons.auto_awesome_rounded` 14px white
  - 8px gap
  - Bubble:
    - Margin: right 64px, bottom 8px
    - Container: `surface` background, 1px `outline` border, shadow level 1
    - Border radius: TL 16, TR 16, BR 16, BL 4 (tail on bottom-left)
    - Padding: 14px H, 10px V
    - Text: `bodyMedium`, `onSurface`, lineHeight 1.5

**Source citations (inside AI bubble, below text):**
- 8px above, thin `outlineVariant` divider
- 8px below divider: "Sources" label -- `labelSmall`, `primary`
- 4px below: `Wrap` of source chips, 6px spacing
  - Each chip: `surfaceContainer` bg, radiusPill, 8px H / 4px V
    - `Icons.description_rounded` 10px + chunk reference text `caption`
    - Expandable: tap toggles showing the source chunk text below as a small card
    - Expanded: slide down reveal (200ms ease-out), `surfaceVariant` bg, radiusSm, 8px padding, `bodySmall`, max 3 lines

**Typing indicator (when AI generating):**
- See Component Spec 3.12
- Position: left-aligned, same layout as AI bubble (with avatar)

**Streaming text:** When `streamingContent` is not null:
- Render in AI bubble layout
- Each word appears with a 50ms stagger, opacity 0->1 (150ms ease-out)
- Cursor: blinking `|` at end of text, `primary` color, 500ms blink cycle

**Input area (pinned to bottom):**
- Container: `surface` bg, shadow level 4 (upward), 1px `outlineVariant` top border
- Padding: 12px H, 10px V
- Row:
  - Microphone icon button (placeholder): `Icons.mic_rounded`, 40x40px, `onSurfaceVariant` at 40%
  - 8px gap
  - Expanded text field:
    - Pill-shaped: radiusPill, `surfaceVariant` fill, no border
    - Padding: 16px H, 12px V
    - Hint: "Ask a question..." -- `bodyMedium`, `onSurfaceVariant` at 50%
    - Max lines: 4 (grows with content)
  - 8px gap
  - Send button: 40x40px circle
    - When input has text: `primaryGradient` bg, `Icons.arrow_upward_rounded` 20px white, shadow level 1
    - When empty: `surfaceContainer` bg, `Icons.arrow_upward_rounded` 20px `onSurfaceVariant` at 40%, disabled
    - When AI generating: `surfaceContainer` bg, `Icons.stop_rounded` 20px `error`, tap to cancel
    - Transition: cross-fade 200ms

---

### 2.9 Quiz Config Screen

**AppBar:** "Create Quiz" -- `titleLarge`, back arrow

**Body (SingleChildScrollView, 20px horizontal padding, 24px top):**

**Question Type Picker (card-based, NOT chips):**
- Label: "Question Type" -- `titleSmall`, 12px bottom margin
- Grid: 2 columns, 12px spacing
- Each type card:
  - Container: `surface` bg, radiusMd (12px), 1px border
    - Selected: `primary` border (2px), `primaryGradient` at 8% fill, shadow level 1
    - Unselected: `outlineVariant` border (1px), no fill, no shadow
  - Padding: 16px
  - Centered column:
    - Icon container: 44x44px, `surfaceContainer` (unselected) or `primary` at 15% (selected), radiusSm
      - Icon 24px:
        - MCQ: `Icons.format_list_bulleted_rounded`
        - True/False: `Icons.toggle_on_rounded`
        - Fill Blank: `Icons.text_fields_rounded`
        - Essay: `Icons.article_rounded`
      - Color: `onSurfaceVariant` (unselected) or `primary` (selected)
    - 8px below: Type label -- `labelMedium`, same color logic
  - Selection animation: border color + bg fill 200ms ease-out, icon color 150ms

**Difficulty Picker (24px below):**
- Label: "Difficulty" -- `titleSmall`, 12px bottom margin
- Row of 3 pills, 8px spacing, each `Expanded`:
  - Each pill: 44px tall, radiusPill
    - Selected: difficulty color bg, white text, shadow level 1
    - Unselected: `surfaceContainer` bg, `onSurfaceVariant` text, no shadow
  - Label: `labelLarge` (14sp Medium)
  - Easy/Medium/Hard with color indicators:
    - Small 8px circle on left of text, filled with difficulty color
  - Selection animation: background color fill 200ms ease-out

**Question Count (24px below):**
- Label: "Number of Questions" -- `titleSmall`, 12px bottom margin
- Custom stepper (NOT Slider):
  - Row:
    - Minus button: 40x40px circle, `surfaceContainer` bg, `Icons.remove_rounded` 20px
      - Disabled (at min): opacity 0.3
    - 16px gap
    - Count display: `headlineMedium` (22sp Bold), `onSurface`, 48px wide centered
      - Animated number change: slide up-out old, slide up-in new (200ms ease-out)
    - 16px gap
    - Plus button: 40x40px circle, `primaryGradient` bg, `Icons.add_rounded` 20px white
      - Disabled (at max): opacity 0.3, no gradient
  - Below stepper (8px): Range hint -- `caption`, `onSurfaceVariant`, e.g. "3 - 20 questions"

**Generate button (40px below):**
- Full-width `ScButton` gradient variant
- Label: "Generate Quiz"
- Icon: `Icons.auto_awesome_rounded`
- Loading state:
  - Shimmer gradient sweeps across button surface (AI shimmer)
  - Label changes to "Generating..."
  - Icon replaced with pulsing sparkle animation

**Error text (if present, 16px below button):**
- `bodySmall`, `error` color, `Icons.error_outline` 14px inline

---

### 2.10 Quiz Taking Screen

**AppBar:** "Quiz" -- `titleLarge`, back arrow, "Submit" text button (right)

**Progress section (top, 20px padding):**
- `QuizProgressBar` redesigned (see Component Spec 3.10):
  - Top: Circular progress indicator (left) + question counter text (right)
  - Below: Dot indicators for each question

**Question area (Expanded, swipeable via PageView):**
- One question per page
- Swipe left/right to navigate (with PageView physics)
- Each page: 20px horizontal padding, 16px top
- Question text: `titleMedium` (16sp SemiBold), `onSurface`
- Question number label above: "Question {n}" -- `labelMedium`, `primary`
- Answer widgets below (24px gap): see Component Specs 3.7-3.9

**Bottom navigation (pinned, 20px padding):**
- Row:
  - Previous button (if not first): `ScButton` outlined, "Previous", `Icons.chevron_left_rounded`
    - Takes 40% width
  - Flexible spacer
  - Question dots: Row of small dots, 6px each, 4px spacing
    - Answered: `primary` filled
    - Current: `primary` border (2px), no fill, scale 1.3
    - Unanswered: `quizUnanswered` at 40%
    - Tap on dot: jump to that question
    - If many questions (>10): show 5 dots around current with "..." indicators
  - Flexible spacer
  - Next/Submit button: takes 40% width
    - If not last: `ScButton` filled, "Next", `Icons.chevron_right_rounded`
    - If last: `ScButton` gradient, "Submit", `Icons.check_rounded`
      - If all answered: subtle pulse animation (scale 1.0->1.02->1.0, 1.5s loop)
      - If not all answered: standard, no pulse

---

### 2.11 Quiz Results Screen

**AppBar:** "Results" -- `titleLarge`, back arrow

**Score section (top, centered, 32px top padding):**

**Animated circular score gauge:**
- Size: 180x180px, centered
- Track: `surfaceContainer`, 12px stroke width
- Value arc: grade color, 12px stroke width, `StrokeCap.round`
- Animation: 0 to final percentage over 800ms, `Curves.easeOutBack` (slight overshoot)
- Center content:
  - Grade letter: `displayLarge` (40sp Bold), grade color
  - Below: percentage -- `titleMedium`, `onSurfaceVariant`, e.g. "85%"
- Below gauge (16px): "{score} / {total} correct" -- `bodyLarge`, `onSurface`

**Confetti animation (for A grades only):**
- Trigger: when score gauge animation completes
- 100 particles, 2.5s duration
- Colors: `[primary, accent, success, info, warning]`
- Origin: top-center of screen
- Physics: random X velocity -200..200, Y velocity 200..600, gravity 300
- Particle shapes: small rectangles (6x4) and circles (4px)

**Grade breakdown card (24px below gauge, 20px horizontal):**
- Container: `surface`, radiusMd, shadow level 1, 16px padding
- Row: evenly spaced stat cells:
  - Correct: `success` icon `Icons.check_circle_rounded`, count, "Correct"
  - Incorrect: `error` icon `Icons.cancel_rounded`, count, "Wrong"
  - Skipped: `quizUnanswered` icon `Icons.remove_circle_outline_rounded`, count, "Skipped"
  - Each cell: Column, `labelSmall` for label, `titleMedium` for count, icon 20px

**Review section (24px below breakdown):**
- Header: "Review Answers" -- `titleMedium`, 16px bottom margin
- Expandable question cards:
  - Container: `surface`, radiusMd, 1px border
    - Correct question: `success` left border 3px
    - Incorrect question: `error` left border 3px
    - Skipped: `quizUnanswered` left border 3px
  - Collapsed (default): 16px padding
    - Row: Question number badge (24px circle, colored) + question text preview (1 line) + expand icon
  - Expanded (on tap): slide down reveal 300ms ease-out
    - Full question text
    - Answer options (same as quiz-taking but in review mode)
    - Explanation card (if present): `surfaceVariant` bg, radiusSm, lightbulb icon + text
  - 8px bottom margin between cards

**Bottom: Full-width `ScButton` outlined, "Done", 20px horizontal padding, 16px bottom**

**Alternative actions (if quiz retakable):**
- Row below "Done" button, 8px above:
  - "Retake Quiz" text button -- `primary`
  - "View History" text button -- `onSurfaceVariant`

---

### 2.12 Quiz History Screen

**AppBar:** "Quiz History" -- `titleLarge`, back arrow

**Timeline list (20px horizontal padding, 16px top):**
- Each attempt card:
  - Row:
    - Timeline indicator (left, 28px wide):
      - Dot: 12px circle, grade color filled
      - Line: 2px wide, `outlineVariant`, connecting dots vertically
      - First/last: line starts at dot / ends at dot
    - 12px gap
    - Card (Expanded): `surface`, radiusMd, shadow level 1, 16px padding
      - Top row:
        - Grade badge: 36x36px circle, grade color at 12% bg, grade letter `titleMedium` Bold in grade color
        - 12px gap
        - Column:
          - Score: `titleSmall` -- "8/10 correct (80%)"
          - Date: `labelSmall`, `onSurfaceVariant` -- "Mar 15, 2026 at 3:45 PM"
        - Right: Chevron
      - 8px bottom margin

**Score trend sparkline (if 3+ attempts):**
- Positioned at top of list, before first card
- Container: `surface`, radiusMd, shadow level 1, 16px padding
- Label: "Score Trend" -- `titleSmall`
- 12px below: mini chart, 120px tall, full width
  - Line chart: `primary` color, 2px stroke, smooth cubic bezier between points
  - Fill below line: `primary` at 8%
  - Dots at each data point: 6px circle `primary`
  - Y axis: 0-100%, grid lines at 25% increments, `outlineVariant` at 30%
  - X axis: attempt numbers ("1", "2", "3"...) -- `caption`, `onSurfaceVariant`

**Empty state:** `EmptyStateWidget` with clock icon

---

### 2.13 Settings Screen

**AppBar:** "Settings" -- `titleLarge`, back arrow

**User section (top, 20px horizontal, 24px top):**
- Container: `surface`, radiusMd, shadow level 1, 20px padding
- Row:
  - Avatar: 56x56px circle, `primaryGradient` background
    - `Icons.person_rounded` 28px white
  - 16px gap
  - Column:
    - "Student" -- `titleMedium` (placeholder for future user name)
    - "StudyCompanion" -- `labelSmall`, `onSurfaceVariant`
  - Right: Edit icon button, `Icons.edit_rounded`, `onSurfaceVariant`

**Grouped sections (24px below user card):**

**Section: Appearance**
- Section header: "APPEARANCE" -- `labelSmall` (11sp Medium), `primary`, 20px H padding, 16px top, 8px bottom
- Theme toggle card:
  - Container: `surface`, radiusMd, shadow level 1
  - ListTile:
    - Leading: Custom sun/moon animated icon
      - Light mode: `Icons.light_mode_rounded`, `warning` (amber)
      - Dark mode: `Icons.dark_mode_rounded`, `info` (blue)
      - System: `Icons.brightness_auto_rounded`, `onSurfaceVariant`
    - Title: "Theme" -- `titleSmall`
    - Subtitle: Current mode name -- `bodySmall`, `onSurfaceVariant`
    - Trailing: Custom toggle switch (NOT SegmentedButton, too wide):
      - 3-state pill toggle: Sun | Auto | Moon
      - Container: `surfaceContainer`, radiusPill, 4px padding
      - Active thumb: `primary` bg, white icon, radiusPill
      - Inactive icons: `onSurfaceVariant` at 50%
      - Thumb slides with 200ms ease-in-out
      - Total width: 108px, height: 36px

**Section: AI Model**
- Section header: "AI MODEL" (same style as above)
- Model info card:
  - Container: `surface`, radiusMd, shadow level 1
  - ListTile:
    - Leading: `Icons.memory_rounded` in 40x40 `primaryGradient` container, radiusSm, white icon
    - Title: "Active Model" -- `titleSmall`
    - Subtitle: Model name or "No model loaded" -- `bodySmall`, `onSurfaceVariant`
    - Trailing: Chevron
    - Tap: navigate to Model Management

**Section: About**
- Section header: "ABOUT"
- App info card:
  - Container: `surface`, radiusMd, shadow level 1
  - Column of ListTiles:
    - Study Companion -- icon `Icons.school_rounded` in `primary`, subtitle: version
    - Privacy -- icon `Icons.shield_rounded` in `success`, subtitle: "All data stays on your device"
    - Licenses -- icon `Icons.description_rounded` in `info`, subtitle: "Open source licenses", tap to show licenses page

---

### 2.14 Model Management Screen

**AppBar:** "AI Models" -- `titleLarge`, back arrow

**Storage usage bar (top, 20px padding, 16px top):**
- Container: `surface`, radiusMd, shadow level 1, 16px padding
- Label: "Storage Used" -- `titleSmall`
- 8px below: Segmented bar showing model sizes:
  - Full width, 8px tall, radiusPill
  - Each downloaded model segment colored by a unique color
  - Remaining space: `surfaceContainer`
- 8px below: Total text -- `labelSmall`, `onSurfaceVariant`, e.g. "1.2 GB / 8 GB used"

**Downloaded Models section (24px below, if any):**
- Section header: "DOWNLOADED" -- `labelSmall`, `primary`
- Each model card:
  - Container: `surface`, radiusMd, shadow level 1, 16px padding
  - Row:
    - Active indicator:
      - Active: `Icons.check_circle_rounded` 24px `success` with gentle glow (BoxShadow success at 30%, blur 8)
      - Inactive: `Icons.circle_outlined` 24px `onSurfaceVariant`
    - 12px gap
    - Column:
      - Name: `titleSmall`
      - Size: `labelSmall`, `onSurfaceVariant`
    - Right actions:
      - If not active: "Use" pill button (`primary` outlined, 32px tall, radiusPill)
      - Delete icon: `Icons.delete_outline_rounded`, `onSurfaceVariant`
  - 8px bottom margin

**Available Models section (24px below):**
- Section header: "AVAILABLE" -- `labelSmall`, `primary`
- Each model card:
  - Container: `surface`, radiusMd, shadow level 1, 16px padding
  - Top row:
    - Model icon: 44x44px, `primaryGradient`, radiusSm, `Icons.memory_rounded` 22px white
    - 12px gap
    - Column:
      - Name: `titleSmall`
      - Size badge: inline, `surfaceContainer` bg, radiusPill, `labelSmall`
    - Right: "Downloaded" chip if already downloaded (`successContainer` bg, `success` text)
  - Description (8px below): `bodySmall`, `onSurfaceVariant`
  - Download button (12px below, only if not downloaded):
    - If downloading this model:
      - Circular progress ring: 44x44px, 3px stroke, `primary`, with percentage in center `labelSmall`
      - Animation: smooth progress fill
      - Cancel button to the right: `Icons.close_rounded`, `error`
    - If not downloading:
      - `ScButton` filled, "Download ({size})", icon `Icons.download_rounded`
  - 12px bottom margin

---

## 3. Component Specifications

### 3.1 ScButton

**Variants:** `primary` (default), `secondary`, `outlined`, `ghost`, `gradient`

| Property | Primary | Secondary | Outlined | Ghost | Gradient |
|----------|---------|-----------|----------|-------|----------|
| Background | `primary` | `surfaceContainer` | transparent | transparent | `primaryGradient` |
| Border | none | none | 1.5px `primary` | none | none |
| Text color | white | `onSurface` | `primary` | `primary` | white |
| Icon color | white | `onSurface` | `primary` | `primary` | white |
| Shadow | level 1 | none | none | none | level 2 + primary glow |

**Sizes:**
- Default: 48px height, 24px horizontal padding, radiusSm (8px), `labelLarge` text
- Small: 36px height, 16px horizontal padding, radiusSm (8px), `labelMedium` text
- Pill: 48px height, 24px horizontal padding, radiusPill, `labelLarge` text

**States:**
- Default: As specified per variant
- Pressed: Scale 0.97 (150ms), background darkens 10%
- Disabled: opacity 0.4, no shadow, no press animation
- Loading: Content replaced with 20x20 CircularProgressIndicator (strokeWidth 2.5, white or `primary`)
  - Width/height maintained (no layout shift)
  - For gradient variant: shimmer sweep animation across button surface

**Icon position:** Left of label, 8px gap. Icon size: 18px.

**Expanded:** When `expanded: true`, `SizedBox(width: double.infinity)` wrapper.

**Dark mode adjustments:**
- Primary: slightly lighter `#8B5CF6`
- Secondary: `surfaceContainer` (dark values)
- Outlined: border `#8B5CF6`

---

### 3.2 ScTextField

**Visual design:**
- Container: `surfaceVariant` fill, radiusSm (8px), no border at rest
- Focus: 2px `primary` border fades in (200ms), fill lightens slightly
- Error: 2px `error` border, error text below (12px top, `bodySmall` `error`)

**Floating label animation:**
- Rest (no text, unfocused): label inside field, `bodyMedium`, `onSurfaceVariant` at 60%
- Focused or has text: label floats up to top edge, shrinks to `labelSmall`, color changes to `primary` (focused) or `onSurfaceVariant` (unfocused with text)
- Animation: 200ms ease-out, translate Y and scale simultaneously
- Implementation: Use Flutter's built-in `InputDecoration.floatingLabelBehavior: FloatingLabelBehavior.auto` with custom styling

**Padding:** 16px horizontal, 14px vertical (or 12px if single-line with label)

**Prefix/Suffix icons:** 20px, `onSurfaceVariant`, 12px padding from edge

**Multiline (maxLines > 1):**
- Min height scales with maxLines
- Content padding: 16px all sides
- Scrollable when content exceeds maxLines

**Dark mode:** `surfaceVariant` uses dark palette values. Focus border `#A78BFA`.

---

### 3.3 LoadingOverlay

**Visual design:**
- Backdrop: `BackdropFilter` with blur sigmaX/Y: 8, overlay color `Color(0x40000000)` (25% black)
- Centered card:
  - `surface` bg, radiusMd (12px), shadow level 3
  - Padding: 32px
  - Content column:
    - Custom AI shimmer loader (not plain CircularProgressIndicator):
      - 48x48px container
      - Pulsing `Icons.auto_awesome_rounded` with gradient color cycling through `aiShimmerGradient`
      - Scale pulse: 1.0->1.1->1.0 over 1s loop
    - 20px below: message text -- `bodyMedium`, `onSurface`, text-align center
- Fade in: 200ms ease-out
- Blocks interaction with underlying content

---

### 3.4 EmptyStateWidget

**Visual design (redesigned with more personality):**
- Centered, constrained to max-width 280px
- Padding: 32px all

**Icon area:**
- 80x80px circle container
- Background: `primaryGradient` at 10% opacity
- Inner 56x56px circle: `primaryGradient` at 15% opacity
- Icon: 32px, `primary`
- Gentle pulse: scale 1.0->1.05->1.0, 2s loop, ease-in-out

**Title (20px below icon):**
- `titleMedium`, `onSurface`, text-align center

**Subtitle (8px below title):**
- `bodyMedium`, `onSurfaceVariant` at 70%, text-align center

**Action button (24px below subtitle, if provided):**
- `ScButton` variant `gradient`, pill size
- Icon provided by caller

---

### 3.5 NoteCard (Redesigned)

**Visual design:**
- Container: `surface` bg, radiusMd (12px), shadow level 1
- Bottom margin: 12px

**Layout (16px padding):**
- Top row:
  - Source type icon badge: 28x28px, colored bg at 12%, radiusSm (8px)
    - PDF: `Icons.picture_as_pdf_rounded`, `#EF4444` (red)
    - TXT: `Icons.text_snippet_rounded`, `#3B82F6` (blue)
    - MD: `Icons.article_rounded`, `#10B981` (green)
    - Manual: `Icons.edit_note_rounded`, `#F59E0B` (amber)
  - 10px gap
  - Title: `titleSmall`, maxLines 1, ellipsis
  - Spacer
  - Status indicator:
    - If loading: 16x16 CircularProgressIndicator, strokeWidth 2, `primary`
    - If error: `Icons.error_outline_rounded` 16px `error`
    - If ready: nothing (clean)
  - Delete icon button: 18px, `onSurfaceVariant` at 40%

- Content preview (8px below):
  - 2 lines max, `bodySmall`, `onSurfaceVariant`, overflow ellipsis
  - If empty: "No content" in italic

- Bottom metadata row (8px below):
  - Left: Chunk count badge -- `surfaceContainer` bg, radiusPill, 6px H / 2px V
    - `labelSmall`, `onSurfaceVariant`, e.g. "12 chunks"
  - Right: Date -- `labelSmall`, `onSurfaceVariant` at 60%

- Processing overlay (if status is importing/processing):
  - Full card overlay, `surface` at 90%, radiusMd
  - Centered: small progress indicator + status label

**Dark mode:** Use dark palette `surface` and adjusted opacity values.

---

### 3.6 ProcessingIndicator

**Visual design (as current, minor refinements):**
- Container: semantic color container bg, radiusPill, 12px H / 6px V padding
- Row:
  - Status icon: 12px
    - Loading: mini spinner (12px, strokeWidth 2)
    - Error: `Icons.error_outline_rounded`, `error`
    - Ready: `Icons.check_circle_rounded`, `success`
  - 6px gap
  - Label: `labelSmall`, semantic color text

**Animation:**
- Loading state: spinner rotates continuously
- Transition between states: 200ms cross-fade

---

### 3.7 McqQuestionWidget (Selectable Cards)

**Question text:** `titleMedium`, `onSurface`, 24px bottom margin

**Option cards (8px bottom margin each):**
- Container: radiusSm (8px), 1px border
- Padding: 14px H, 12px V

**States:**
| State | Background | Border | Text Color | Right Icon |
|-------|-----------|--------|------------|------------|
| Default | transparent | `outline` at 30% (1px) | `onSurface` | none |
| Selected | `primary` at 8% | `primary` (2px) | `onSurface` | `Icons.check_circle` 20px `primary` |
| Correct (review) | `quizCorrectBg` | `success` (2px) | `onSurface` | `Icons.check_circle` 20px `success` |
| Incorrect (review) | `quizIncorrectBg` | `error` (2px) | `onSurface` | `Icons.cancel` 20px `error` |

**Selection animation:**
- Border: color transition 200ms ease-out
- Background: fill 200ms ease-out
- Right icon: scale 0->1 pop-in 200ms with overshoot curve
- Left: Option letter badge (A, B, C, D):
  - 24px circle, `surfaceContainer` bg (default) or variant-colored bg
  - `labelMedium` Bold, centered

**Explanation card (review mode, 12px below options):**
- `surfaceVariant` bg, radiusSm, 12px padding
- Row: `Icons.lightbulb_outline_rounded` 16px `warning` + 8px gap + text `bodySmall`

---

### 3.8 TrueFalseQuestionWidget (Large Toggle Cards)

**Question text:** `titleMedium`, `onSurface`, 24px bottom margin

**Two cards side by side (Row, 12px gap):**
- Each card: Expanded, 64px tall (increased from current 60px+padding), radiusMd (12px)
- Centered content: Label `titleMedium` + icon on right

**States:**
| State | Background | Border | Label Color |
|-------|-----------|--------|-------------|
| Default | transparent | `outline` at 30% (1px) | `onSurface` |
| Selected | `primary` at 10% | `primary` (2px) | `primary` |
| Correct (review) | `quizCorrectBg` | `success` (2px) | `success` |
| Incorrect (review) | `quizIncorrectBg` | `error` (2px) | `error` |

**Icons:**
- True: `Icons.check_rounded` 20px
- False: `Icons.close_rounded` 20px
- Position: left of label, 8px gap

**Selection animation:** Same as MCQ -- border + bg fill 200ms.

---

### 3.9 FillBlankQuestionWidget (Inline Blank Style)

**Question text:** `titleMedium`, `onSurface`
- If question contains "___" (blank marker): render question with inline styled blank
  - Blank: underline decoration, `primary` color, thicker weight
- If plain question: render normally, 16px bottom margin then input field

**Input field:**
- `ScTextField` styling with `radiusSm`
- Bottom border only style (clean inline feel): no fill, just 2px bottom border
  - Unfocused: `outline` at 40%
  - Focused: `primary`
  - Correct (review): `success`
  - Incorrect (review): `error`
- Suffix icon in review mode: check/cross icon

**Correct answer reveal (review, incorrect):**
- 8px below input: "Correct: {answer}" -- `bodySmall`, `success`
- Slide-down reveal 200ms

---

### 3.10 QuizProgressBar (Circular + Linear Hybrid, Redesigned)

**Layout: Row**

**Left: Circular progress (48x48px):**
- Track: `surfaceContainer`, 4px stroke
- Progress arc: `primary`, 4px stroke, rounded cap
- Center: current question number -- `labelLarge` Bold, `primary`
- Animation: arc fills 300ms ease-out on question change

**Center (Expanded, 12px left margin): Question dots:**
- Horizontal scroll if many, 6px dot size, 4px spacing
- Answered: `primary` filled
- Current: `primary` border ring (2px), scale 1.5, no fill
- Unanswered: `surfaceContainerHigh` filled
- Transition: 200ms ease-out for dot state changes

**Right: Answered count text:**
- `labelMedium`, `onSurfaceVariant`
- Format: "{answered}/{total}"

---

### 3.11 ChatBubble (Redesigned with Avatar)

**User bubble:**
- Align: right
- Max width: 75% of screen
- Margin: left 64px, bottom 4px
- Background: `primaryGradient`
- Border radius: TL 16, TR 16, BL 16, BR 4
- Padding: 14px H, 10px V
- Text: `bodyMedium`, white, lineHeight 1.5
- Shadow: level 1

**AI bubble:**
- Row:
  - Avatar: 28x28px circle, `surface` bg, 1px `outline` border
    - `Icons.auto_awesome_rounded` 14px, `primary`
  - 8px gap
  - Bubble container:
    - Max width: 75% of screen
    - Margin: right 64px, bottom 4px
    - Background: `surface` (light) / `surfaceVariant` (dark)
    - Border: 1px `outlineVariant`
    - Border radius: TL 4, TR 16, BR 16, BL 16
    - Padding: 14px H, 10px V
    - Text: `bodyMedium`, `onSurface`, lineHeight 1.5
    - Shadow: level 1

**Source citations (AI bubbles only, if sources exist):**
- Thin divider: `outlineVariant`, 8px top/bottom margin
- Label: "Sources" -- `labelSmall`, `primary`
- Chips below (4px gap, Wrap, 6px spacing):
  - Container: `surfaceContainer`, radiusPill, 8px H / 4px V
  - `Icons.description_rounded` 10px `onSurfaceVariant` + text `caption` `onSurfaceVariant`
  - Tappable: expand below to show source text snippet (max 3 lines, `bodySmall`)

**Timestamp (below each bubble group):**
- `caption`, `onSurfaceVariant` at 40%, right-aligned (user) or left-aligned (AI, with avatar offset)

---

### 3.12 TypingIndicator (Bouncing Dots)

**Layout:** Same as AI bubble (with avatar)

**Dots container:**
- Background: same as AI bubble
- Border radius: same as AI bubble
- Padding: 14px H, 12px V

**Animation:**
- 3 dots, each 8px diameter circle, `onSurfaceVariant` at 60%
- 4px horizontal spacing between dots
- Each dot bounces up (translateY -6px) then back down
- Stagger: 200ms between each dot start
- Duration: each dot bounce 400ms, ease-in-out
- Total cycle: ~1000ms then repeat

**Streaming text state:**
- When `streamingText` is not null/empty:
  - Use AI bubble layout
  - Text renders with blinking cursor `|` at end
  - Cursor: `primary` color, 1px wide, opacity toggles 0/1 at 530ms interval
  - Text itself uses `bodyMedium`, same as regular AI bubble

---

## 4. Bug Fixes Required

### 4.1 Router Recreation Bug (app.dart)

**File:** `lib/app.dart`

**Problem:** `createRouter()` is called inside `build()`, creating a new `GoRouter` instance on every rebuild. This:
- Resets navigation history on theme changes
- Causes unnecessary memory allocation
- Breaks deep linking state

**Fix:** Store the router as a `late final` field, or move it to a Riverpod provider.

```dart
class StudyCompanionApp extends ConsumerStatefulWidget {
  final bool showOnboarding;
  const StudyCompanionApp({super.key, this.showOnboarding = false});

  @override
  ConsumerState<StudyCompanionApp> createState() => _StudyCompanionAppState();
}

class _StudyCompanionAppState extends ConsumerState<StudyCompanionApp> {
  late final GoRouter _router = createRouter(showOnboarding: widget.showOnboarding);

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Study Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
```

### 4.2 FAB Not Responding to Active Tab (notebook_detail_screen.dart)

**File:** `lib/presentation/screens/notebook/notebook_detail_screen.dart`

**Problem:** The FAB uses `DefaultTabController.of(context).index` inside `Builder.build()`, but this value is only read once when the Builder first builds. It does NOT rebuild when the tab changes because `Builder` doesn't listen to `DefaultTabController` changes.

**Root cause:** `DefaultTabController.of(context).index` returns the initial index; the `Builder` widget has no mechanism to trigger rebuilds on tab changes.

**Fix:** Use `AnimatedBuilder` with the `TabController.animation` to rebuild on tab changes, or convert the screen to a `StatefulWidget` and listen to tab controller changes:

```dart
// Option A: AnimatedBuilder approach (minimal change)
floatingActionButton: AnimatedBuilder(
  animation: DefaultTabController.of(context),
  builder: (context, child) {
    final tabIndex = DefaultTabController.of(context).index;
    // ... switch on tabIndex as before
  },
),

// Option B (recommended): Convert to StatefulWidget with explicit TabController
// This also enables the Speed Dial FAB to know which tab is active
class _NotebookDetailScreenState extends ConsumerState<NotebookDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  // Then use _activeTab in the FAB builder
}
```

### 4.3 TypingIndicator AnimatedBuilder Typo

**File:** `lib/presentation/widgets/chat/typing_indicator.dart`

**Problem:** Line 71 uses `AnimatedBuilder` which is not a Flutter widget. The correct widget name is `AnimatedBuilder` -- actually checking again: Flutter's widget is `AnimatedBuilder`. This appears correct. However, if this causes a compilation error, the fix is to use `AnimatedBuilder` (which is an alias for the same thing in modern Flutter) or use `AnimatedWidget`/`ListenableBuilder`.

**Note:** If using Flutter 3.10+, `AnimatedBuilder` was renamed to `ListenableBuilder` and `AnimatedBuilder` is kept as an alias. Verify compilation.

---

## 5. Implementation Priority

### Phase 1: Foundation (Design System)
1. Update `AppColors` with full palette (light + dark)
2. Update `Spacing` with complete token set
3. Update `AppTheme` with full component theming
4. Add gradient definitions utility class
5. Add animation constants utility class

### Phase 2: Core Components
1. Redesign `ScButton` with all 5 variants
2. Redesign `ScTextField` with floating label
3. Redesign `LoadingOverlay` with blur + shimmer
4. Redesign `EmptyStateWidget` with personality
5. Apply bug fixes (app.dart, notebook_detail_screen.dart)

### Phase 3: Screens (in user flow order)
1. Onboarding (gradient backgrounds, glass illustrations)
2. Model Download (card redesign)
3. Home Dashboard (greeting, stats, grid, bottom nav)
4. Create Notebook (color picker animation, character count)
5. Notebook Detail (gradient header, chip tabs, speed dial FAB)
6. Note Import (animated drop zone, step progress)
7. Note Detail (summary generation states)
8. Chat Screen (bubble redesign, suggestions, streaming)
9. Quiz Config (card picker, custom stepper)
10. Quiz Taking (PageView, dot nav, answer cards)
11. Quiz Results (score gauge, confetti, expandable review)
12. Quiz History (timeline, sparkline)
13. Settings (grouped sections, custom toggle)
14. Model Management (progress ring, storage bar)

### Phase 4: Polish
1. Page transitions
2. Micro-interactions
3. Dark mode fine-tuning
4. Accessibility audit (contrast ratios, touch targets 48px+)
