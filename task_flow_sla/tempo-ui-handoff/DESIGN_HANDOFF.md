# Tempo: UI redesign handoff (frontend only)

## Goal
Restyle the existing Tempo Flutter app to match the new designs in `design-reference/`.
The backend and app logic are already built and working. **Only the visual layer changes.**

## Hard rules (read before touching anything)

**Do NOT change:**
- Models, data classes, database code (sqflite tables, queries, migrations)
- Services, repositories, providers/controllers, state management logic
- SharedPreferences keys and how the signed-in user is saved or cleared
- SLA rules and calculations (Completed / Overdue / At Risk under 48h / On Track)
- Form validation rules (title required, 3 to 60 characters; due date in the future; assignee required)
- Route names, navigation logic, and what each screen passes to the next
- Existing tests (they must still pass without being edited)

**You MAY change:**
- Widget trees inside screen files (`build` methods and private UI helpers)
- Theme files (`ThemeData`, colors, text styles)
- New files for shared UI widgets (e.g. `lib/widgets/`, `lib/theme/`)
- `pubspec.yaml`, only to add `google_fonts`

**If a design element needs data or logic that doesn't exist yet, stop and ask. Do not invent backend code.**
For elements removed from the design (see the "Removed from the old UI" section), remove only the widget. Leave the underlying logic in place, set to its current default.

## How to work
1. Create a branch: `git checkout -b ui-redesign`.
2. First explore the project and report back: the folder structure, where each screen lives, the state management used, and where the theme is defined. Make no edits during this step.
3. Build the theme and shared widgets first (see "Shared widgets" below). Then do **one screen per commit**, in this order: Sign In, Dashboard, Task List, Task Details, Create/Edit Task, Team, then the new Landing and Register screens.
4. After each screen:
   - Run `flutter analyze` and `flutter test`.
   - Run `git diff --stat` and confirm only UI and theme files changed.
5. Open the matching `design-reference/*.dc.html` file to get exact values. These are HTML mockups, so read their inline styles as the spec. Ignore the `<script>` blocks except as a guide to how each screen behaves.

## Design tokens

### Colors
| Token | Hex | Use |
|---|---|---|
| ground | `#E6E8E7` | Light screen background |
| surface | `#FFFFFF` | Cards, inputs |
| surfaceMuted | `#F1F2F2` | Chips, icon buttons inside cards |
| ink | `#2B2E2D` | Main text, dark cards, primary buttons, bottom nav |
| inkDeep | `#222524` | Dashboard background (dark screen) |
| darkCard | `#2E3231` | Cards on the dark dashboard |
| darkCardAlt | `#3A3E3D` | Inner rows on dark cards |
| darkBorder | `#3B403E` | 1px borders on dark cards |
| textMuted | `#535856` | Secondary text on light backgrounds |
| textMutedDark | `#A7ACAA` | Secondary text on dark backgrounds |
| moss | `#6F8F5E` | Accent: active nav pill, On Track, button arrow circle |
| mossLight | `#8FAA7F` | Moss text/links on dark backgrounds |
| mossDeep | `#56734A` | Small dots and accent text on light backgrounds |
| onMoss | `#121A0D` | Text and icons placed on moss |
| amber | `#D9A441` | At Risk |
| amberBg / amberText | `#F1E2C2` / `#5C3A00` | At Risk badge |
| coral | `#D9785F` | Overdue (badge background, text `#2A0C04`) |
| coralText | `#E59C88` | Coral text on dark backgrounds |
| error | `#B3361A` | Validation errors |
| doneBg / doneText | `#E6E8E7` / `#2E3230` | Done / Completed badge |

### Typography (`google_fonts`)
- **Sora** (700): screen titles 30 to 34px with letter-spacing -1 to -1.2; big numbers 22 to 48px.
- **Manrope** (500 to 800): everything else. Body 15px, labels 12 to 13px weight 700 to 800, buttons 15 to 16px weight 800.

### Shape and spacing
- Screen side padding: 16px. Gap between cards: 10 to 16px.
- Radii: inputs 20, cards 24 to 28, hero cards 32, buttons and chips fully round (999).
- Inputs: 56 to 58px tall, white, no border (1.5px ink border when focused, error color when invalid).
- Touch targets: at least 44 x 44.

## Shared widgets to build
- `PrimaryPillButton`: 64px tall, ink background, label on the left, 48px moss circle with an arrow on the right. Animations:
  - press: `AnimatedScale` to 0.96
  - arrow: a repeating nudge, `AnimationController` moving it +5px every 2.4s
- `OutlinePillButton`: 56 to 64px, 1.5px ink border.
- `SlaBadge(status)`: rounded pill, using the badge colors above.
- `AppCard`: white, radius 24, no shadow.
- `TempoBottomNav`: floating pill, 16px from the screen edges, 72px tall, ink background (`#353938` on the dark dashboard). The active item is a moss pill with icon and label; inactive items show the icon only. Stats has no screen yet, so leave it disabled or keep its current behavior.
- `IconCircleButton`: 46px white circle (back, menu, sort, more).

## Screens (each file in `design-reference/`)
| Existing screen | Reference file | Notes |
|---|---|---|
| Sign In | `Main.dc.html` | Plain form: back button, "Welcome back" title, email, password with show toggle, Sign In button, "New to the team? Create account" link. Fields slide up in sequence on entry. |
| Dashboard | `Dashboard.dc.html` | Dark screen. Progress card uses 21 segment bars (13 filled). 2x2 SLA tiles (On Track tile is moss). Donut chart via `CustomPaint`. "Needs attention" list. All counts come from the EXISTING SLA logic. |
| Task List | `TaskList.dc.html` | Search pill, filter chips (All, On Track, At Risk, Overdue, Done) using the EXISTING filter logic. Overdue cards are dark. Moss FAB to Create Task. |
| Task Details | `TaskDetails.dc.html` | SLA card with a tick-scale "time used" bar (36 ticks). 2x2 info tiles. The status dropdown uses the EXISTING update logic. Delete opens a bottom-aligned dialog, wired to the EXISTING delete. |
| Create / Edit Task | `CreateTask.dc.html` | Same validation as today, restyled. Priority uses a segmented pill. Assignee, due date and status sit in one grouped white card. |
| Team | `Team.dc.html` | Dark signed-in card with stats and Switch user / Sign out (EXISTING actions). Member cards with SLA chips. |
| **New:** Landing | `Landing.dc.html` | `CarouselView(itemExtent: 280, shrinkExtent: 240, itemSnapping: true)` with 3 slides and autoplay every 3.2s (pause 4s after the user drags). "Get started" goes to Register, "I already have an account" goes to Sign In. Purely visual, no backend. |
| **New:** Register | `Register.dc.html` | UI only. **Ask me before wiring it to anything**: if the app has no registration backend, it should just navigate. Has a live password-strength bar and a "passwords don't match" message (UI-side checks only). |

## Removed from the old UI
- Sign In: "Remember me", "Forgot password?", and the quick sign-in demo avatars. Keep any related logic. Remember-me should behave as if always on, unless I say otherwise.
- The Tempo logo (icon and text) does not appear anywhere.

## Assets
- `sticky-desk.png` (Landing slide 1) is an **unlicensed Alamy preview, used as a placeholder**. Add it to `assets/images/` for now, and leave a `// TODO: replace with licensed image` comment.

## Done when
- Every screen matches its reference file.
- `flutter analyze` is clean and all existing tests pass unchanged.
- `git diff main --stat` shows only UI, theme, widget, asset and pubspec (google_fonts) changes.
