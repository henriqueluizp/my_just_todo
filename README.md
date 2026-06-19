# Minimalist To‑Do

A premium, minimalist task & calendar planner for iOS, built with **SwiftUI**,
**Core Data** and **MVVM**. Designed to feel calm, focused and native — soft
shadows, rounded cards, fluid animations, full Light/Dark support and haptics.

> Targets **iOS 18+**. Built and verified with Xcode 26 on the iPhone simulator.

---

## ✨ Features

**Planning & calendar**
- Large date headers with a daily progress ring
- Day / Week / Month views with a paging week strip and a full month grid
- Effectively infinite navigation, swipe between weeks, “Today” jump button
- Selected‑day indicator and dots marking days that contain tasks
- Move tasks between dates (Today / Tomorrow / Next week / custom)

**Tasks (full CRUD)**
- Quick add (floating button) and a detailed form
- Title, notes, due date & time, priority (Low/Med/High), category, colour tag, reminder
- Toggle completion with a spring animation + haptic celebration
- Swipe to complete / delete, long‑press context menu, drag to reorder
- Duplicate tasks, **soft delete with Undo**
- Creation date & “last edited” timestamps

**Smart features**
- Real‑time search across title & notes
- Filter by status (All / Pending / Done) and category
- Sort by due date, creation date, priority or alphabetically

**Productivity**
- Daily progress (total / completed / remaining / %)
- Insights dashboard: streak counter, completed today, all‑time total,
  weekly & monthly completion rates, and a 7‑day Swift Charts bar chart

**System integration**
- Localization: **English + Português (Brasil)**. Follows the OS language by
  default and can be switched in‑app at runtime (live, no restart) via a Bundle
  redirect + `Locale.app` for date/number formatting. See `Services/Localization.swift`.
- Local notifications: per‑task reminders + optional daily agenda
- Appearance (System/Light/Dark) and a 9‑colour accent system
- Custom categories (create / edit / delete, colour + SF Symbol)
- JSON **export & restore** (share sheet + file importer)
- Beautiful onboarding, elegant empty states, motivational copy

**Accessibility**
- Dynamic Type (rounded system fonts throughout), VoiceOver labels/traits,
  Reduce Motion–aware animations, adapts to High Contrast via system colours.

---

## 🏗 Architecture (MVVM + DI)

```
Views  ⇄  ViewModels  ⇄  Repositories (protocols)  ⇄  Core Data
                              ▲
                         AppContainer (composition root / DI)
```

- **Views** are declarative and dumb; they read an injected `Theme` and call
  view‑model methods.
- **ViewModels** (`@Observable`) own presentation state and depend only on
  repository *protocols* — so they are unit‑testable with fakes.
- **Repositories** (`TaskRepositoryProtocol`, `CategoryRepositoryProtocol`)
  encapsulate all Core Data access (Dependency Inversion).
- **`AppContainer`** is the single composition root. It builds the persistence
  stack, services and repositories once and injects them through the
  environment, and exposes factory methods for view models.

### Folder structure
```
minimalist_todo/
├── App/                 MinimalistTodoApp (@main), AppContainer (DI)
├── Models/              Priority, sort/filter, appearance enums
├── Theme/               Design tokens (Theme), AccentPalette
├── Persistence/         PersistenceController, entity extensions, SampleData
├── Services/            Task/Category repositories, Notifications, Export,
│                        Haptics, SettingsStore
├── ViewModels/          Calendar, TaskEdit, Category, Statistics
├── Views/               Calendar/, Tasks/, Stats/, Settings/, Onboarding/, RootView
├── Components/          TaskCard, CheckCircle, ProgressRing, EmptyState, Badges
└── Utilities/           Date+/Color+Hex, ShareSheet
```

### Key design decisions
- **File‑system‑synchronized Xcode group** (objectVersion 77): new `.swift`
  files are compiled automatically — no fragile `pbxproj` edits.
- **Core Data automatic codegen** (`codeGenerationType="class"`) keeps the model
  the single source of truth; `wrapped*` extensions provide non‑optional,
  domain‑level accessors.
- **`@Observable`** (Observation framework) for clean, fine‑grained reactivity.
- **Single design‑token `Theme`** injected via `\.theme` so the whole UI restyles
  from one place and the live accent colour flows everywhere.
- View models reload on `.NSManagedObjectContextDidSave`, so edits made anywhere
  (detail screen, restore, notifications) stay reflected.

---

## ▶️ Running

```bash
open minimalist_todo.xcodeproj      # then ⌘R on an iOS 18+ simulator
```

**Debug helpers** (DEBUG builds only, never in Release):
- `SEED_SAMPLE_DATA=1` — populate sample tasks into an empty store
- `INITIAL_TAB=0|1|2` — launch directly on Planner / Insights / Settings

```bash
SIMCTL_CHILD_SEED_SAMPLE_DATA=1 xcrun simctl launch booted com.henrique.todo.minimalist-todo
```

---

## 🧪 Testing notes

Because view models depend on protocols, tests can inject an in‑memory
`PersistenceController(inMemory: true)` or fake repositories. `StatisticsViewModel`
streak/rate logic and `ExportService` round‑tripping are good first unit targets.

---

## 📈 Scalability & next steps

The in‑app experience is complete. The following premium extras need **additional
Xcode targets / capabilities** and are intentionally left as scaffolded next
steps so the main app target stays clean:

1. **WidgetKit** (Home & Lock screen) — add a Widget Extension target, move the
   Core Data stack to an **App Group** container, and read via the existing
   repositories. Persistent history tracking is already enabled.
2. **App Intents / App Shortcuts** — expose “Add task”, “Show today” as intents
   for Siri & Shortcuts.
3. **Spotlight (Core Spotlight)** — index tasks as `CSSearchableItem`s on save.
4. **CloudKit sync** — switch to `NSPersistentCloudKitContainer` (the model is
   already CloudKit‑compatible) for multi‑device sync.
5. **Model versioning** — lightweight migration is enabled; add new `.xcdatamodel`
   versions as the schema evolves.

---

Built with care to feel like a calm, premium App Store productivity app.
