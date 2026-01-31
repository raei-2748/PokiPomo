# CLAUDE.md

This file provides comprehensive guidance to Claude Code (claude.ai/code) when working with code in the PokiPomo repository. PokiPomo is a focus timer app designed for Australian high school students featuring a cute cat mascot and distraction-free study sessions.

## Project Overview

**PokiPomo App** is a native iOS application built with SwiftUI targeting iOS 17.0+. It uses Swift 5.0 and follows modern SwiftUI architectural patterns with a focus on reliability, minimal distraction during focus sessions, and delightful post-session rewards.

### Core Philosophy
- **Timer reliability is non-negotiable**: Drift must be ≤ 1 second over 2 hours
- **Zero distractions during sessions**: No animations, notifications, or gamification while timer is active
- **Delightful completions**: Cat mascot and rewards appear only after session completion
- **Protocol-first design**: Each "space" enforces specific focus behaviors

### Target Audience
- Australian Year 11-12 students preparing for HSC/VCE exams
- Age 16-18, mobile-first users who struggle with phone distractions
- Users seeking gamified productivity without mid-session interruptions

### Key Features (MVP)
- Focus timer with three preset durations (20/35/50 minutes)
- Three enforcement levels: Gentle, Standard, Strict
- Urge Hold exit mechanism (10-second hold to quit)
- Resume Wall (3-second delay after backgrounding)
- Scene system with animated backgrounds and outcomes
- Post-session reflections and deliverable tracking
- Streak tracking and UFM (Uninterrupted Focus Minutes) analytics
- Break bank bonus system

## Build Commands

```bash
# Build for debug
xcodebuild -project "PokiPomo App.xcodeproj" -scheme "PokiPomo App" -configuration Debug build

# Build for release
xcodebuild -project "PokiPomo App.xcodeproj" -scheme "PokiPomo App" -configuration Release build

# Clean build folder
xcodebuild -project "PokiPomo App.xcodeproj" -scheme "PokiPomo App" clean

# Build and run on simulator
xcodebuild -project "PokiPomo App.xcodeproj" -scheme "PokiPomo App" -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run unit tests
xcodebuild -project "PokiPomo App.xcodeproj" -scheme "PokiPomo App" test -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test suite
xcodebuild -project "PokiPomo App.xcodeproj" -scheme "PokiPomo App" test -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:"PokiPomo AppTests/TimerViewModelTests"

# Run UI tests
xcodebuild -project "PokiPomo App.xcodeproj" -scheme "PokiPomo App" test -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:"PokiPomo AppUITests"

# Static analysis
xcodebuild -project "PokiPomo App.xcodeproj" -scheme "PokiPomo App" analyze

# Archive for distribution
xcodebuild -project "PokiPomo App.xcodeproj" -scheme "PokiPomo App" -configuration Release archive -archivePath ./build/PokiPomo.xcarchive
```

## Project Structure

```
PokiPomo App/
├── PokiPomo_AppApp.swift          # App entry point with TabView
├── Models/                         # Data models and enums
│   ├── TimerSession.swift         # Core session data model
│   ├── TimerStatus.swift          # Session state enum
│   ├── Scene.swift                # Scene/world definitions
│   ├── OutcomeType.swift          # Completion outcome types
│   └── EnforcementLevel.swift     # Focus enforcement modes
├── ViewModels/                     # Business logic and state
│   ├── TimerViewModel.swift       # Timer engine and lifecycle
│   ├── StatsViewModel.swift       # Analytics and history
│   └── SceneViewModel.swift       # Scene selection and animation
├── Views/                          # SwiftUI views
│   ├── HomeView.swift             # Main landing screen
│   ├── TimerView.swift            # Active focus session
│   ├── CompletionView.swift       # Post-session celebration
│   ├── ReflectionView.swift       # Optional reflection input
│   ├── StatsView.swift            # Progress and analytics
│   ├── SettingsView.swift         # App configuration
│   └── Components/                # Reusable UI components
│       ├── DurationButton.swift   # Preset time picker
│       ├── UrgeHoldButton.swift   # Exit with hold gesture
│       └── ResumeWall.swift       # Background return overlay
├── Services/                       # Core services
│   ├── TimerPersistence.swift     # UserDefaults wrapper
│   ├── BackgroundTaskManager.swift # iOS background handling
│   ├── SceneManager.swift         # Scene asset loading
│   └── AnalyticsService.swift     # Event logging (local)
├── Extensions/                     # Swift extensions
│   ├── Color+Hex.swift            # Hex color initializer
│   ├── Date+Format.swift          # Date formatting helpers
│   └── View+Extensions.swift      # Custom view modifiers
└── Assets.xcassets/               # Images, colors, scenes
    ├── Colors/                    # Brand color palette
    ├── Mascot/                    # Cat character sprites
    └── Scenes/                    # Background animations

PokiPomo AppTests/                 # Unit tests
├── TimerViewModelTests.swift     # Timer logic tests
├── TimerPersistenceTests.swift   # Storage tests
└── StreakLogicTests.swift        # Streak calculation tests

PokiPomo AppUITests/               # UI automation tests
└── PokiPomo_AppUITests.swift     # End-to-end flow tests
```

## Architecture

### MVVM Pattern
PokiPomo follows the Model-View-ViewModel pattern:

- **Models**: Plain Swift structs conforming to `Codable` and `Identifiable`
- **ViewModels**: `ObservableObject` classes managing state and business logic
- **Views**: SwiftUI views using `@StateObject`, `@ObservedObject`, and `@State`
- **Services**: Singleton classes for cross-cutting concerns (persistence, background tasks)

### State Management
- `@StateObject`: For owning ViewModels (created once)
- `@ObservedObject`: For passing ViewModels between views
- `@State`: For local view state only
- `@AppStorage`: For simple UserDefaults values (settings)
- `@Environment`: For system values (scenePhase, colorScheme)

### Data Flow
```
User Action → View → ViewModel → Model Update → Persistence → View Re-render
```

### Critical Components

#### TimerViewModel
The heart of the app. Responsibilities:
- Run countdown timer with `Timer.publish()` and Combine
- Calculate elapsed time from stored `startTime` (not tick counting)
- Persist state every 60 seconds AND on app lifecycle changes
- Handle crash recovery on app launch
- Detect app backgrounding and trigger Resume Wall
- Track app switches and urge hold attempts

**Non-negotiable Requirements**:
- Timer drift must be ≤ 1 second over 2 hours
- Must survive phone calls, notifications, low battery alerts
- Must restore correctly after force quit
- Must persist state before any termination

#### TimerPersistence Service
Wraps UserDefaults for type-safe storage:
- `save(_ session:)` - Encode and store active session
- `restore() -> TimerSession?` - Decode active session
- `clearActive()` - Remove active session
- `saveHistory(_ session:)` - Append to session history
- `loadHistory() -> [TimerSession]` - Load past sessions

**Storage Keys**:
```swift
enum StorageKeys {
    static let activeSession = "active_session"
    static let sessionHistory = "session_history"
    static let currentStreak = "current_streak"
    static let lastSessionDate = "last_session_date"
    static let breakBankMinutes = "break_bank_minutes"
    static let totalUFM = "total_ufm"
}
```

#### Background Task Manager
Handles iOS background execution:
- Register background task on app launch
- Schedule periodic timer checks
- Keep timer running when app is backgrounded
- Gracefully handle background time expiration

### View Hierarchy
```
TabView
├── HomeView (Tab 1)
│   └── .fullScreenCover → TimerView
│       └── .fullScreenCover → CompletionView
│           └── .sheet → ReflectionView
├── StatsView (Tab 2)
└── SettingsView (Tab 3)
```

## Design System

### Color Palette
```swift
// Primary colors
Color.cream       // #FFF8E7 - Card backgrounds
Color.nearBlack   // #0D0D0D - Main background
Color.softCoral   // #FFB5A7 - Accent and selections

// Semantic colors
Color.textPrimary // High contrast text
Color.textGray    // #8E8E93 - Secondary text
Color.success     // Completion states
Color.warning     // Urge hold attempts
```

### Typography
- **Primary Font**: SF Rounded Medium (system font with rounded design)
- **Timer Display**: SF Mono (monospaced for consistent width)
- **Sizes**: 
  - Heading: 28pt
  - Body: 17pt
  - Caption: 13pt
  - Timer: 80pt

### Spacing
- Standard padding: 24pt
- Compact padding: 16pt
- Minimum touch target: 44x44pt
- Card corner radius: 20pt

### Animation Guidelines
- **During active timer**: ZERO animations (black screen, static UI)
- **Completion**: ≤ 3 seconds, skippable
- **Transitions**: 0.3s ease-in-out
- **Scene backgrounds**: Subtle loops, no distracting motion

## Coding Standards

### Swift Style
- Use Swift 5.0+ features (async/await where appropriate)
- Prefer structs over classes unless reference semantics needed
- Use enums for state representation
- Leverage Codable for serialization
- Use optionals appropriately (avoid force unwrapping)

### SwiftUI Patterns
```swift
// ✅ Good: @StateObject for ownership
struct HomeView: View {
    @StateObject private var viewModel = TimerViewModel()
    
    var body: some View {
        // View code
    }
}

// ✅ Good: Extract complex views
var timerDisplay: some View {
    Text(viewModel.formattedTime)
        .font(.system(size: 80, design: .monospaced))
}

// ❌ Avoid: Business logic in views
// Instead move to ViewModel

// ✅ Good: Computed properties for formatting
var formattedTime: String {
    let minutes = timeRemaining / 60
    let seconds = timeRemaining % 60
    return String(format: "%02d:%02d", minutes, seconds)
}
```

### Error Handling
```swift
// Use Result type for operations that can fail
func loadSession() -> Result<TimerSession, PersistenceError> {
    guard let data = UserDefaults.standard.data(forKey: key) else {
        return .failure(.notFound)
    }
    
    do {
        let session = try JSONDecoder().decode(TimerSession.self, from: data)
        return .success(session)
    } catch {
        return .failure(.decodingFailed(error))
    }
}

// Handle errors gracefully
switch TimerPersistence.loadSession() {
case .success(let session):
    self.currentSession = session
case .failure(let error):
    print("Failed to load session: \(error)")
    // Fallback to clean state
}
```

### Naming Conventions
- **Classes/Structs**: PascalCase (`TimerViewModel`, `SceneManager`)
- **Properties/Methods**: camelCase (`currentSession`, `startTimer()`)
- **Constants**: camelCase (`maxSessionMinutes`)
- **Enums**: PascalCase with lowercase cases (`TimerStatus.running`)
- **Files**: Match primary type name (`TimerViewModel.swift`)

### Documentation
```swift
/// Manages the countdown timer lifecycle and persistence
/// 
/// This ViewModel handles:
/// - Timer execution with drift compensation
/// - State persistence on app lifecycle events  
/// - Crash recovery for interrupted sessions
/// - Background/foreground transition detection
class TimerViewModel: ObservableObject {
    /// Current active session, nil if no session running
    @Published var currentSession: TimerSession?
    
    /// Starts a new focus session with the given parameters
    /// - Parameters:
    ///   - duration: Target duration in minutes
    ///   - taskName: Optional task description
    func startSession(duration: Int, taskName: String?) {
        // Implementation
    }
}
```

## Testing Strategy

### Unit Tests
Use modern Swift Testing framework (`@Test` macro):

```swift
import Testing
@testable import PokiPomo_App

struct TimerViewModelTests {
    @Test func timerDriftWithinBounds() async throws {
        let viewModel = TimerViewModel()
        viewModel.startSession(duration: 120, taskName: nil)
        
        // Let timer run for 5 minutes
        try await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
        
        let drift = abs(viewModel.elapsedSeconds - 300)
        #expect(drift <= 1, "Timer drift must be ≤ 1 second")
    }
    
    @Test func sessionPersistsOnBackground() throws {
        let viewModel = TimerViewModel()
        viewModel.startSession(duration: 50, taskName: "Test Task")
        
        // Simulate backgrounding
        viewModel.handleBackground()
        
        // Verify session saved
        let restored = TimerPersistence.restore()
        #expect(restored != nil)
        #expect(restored?.taskName == "Test Task")
    }
}
```

### UI Tests
Use XCTest for automation:

```swift
import XCTest

final class PokiPomoUITests: XCTestCase {
    func testCompleteFullSession() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Select duration
        app.buttons["20 min"].tap()
        
        // Start session
        app.buttons["Start Focus"].tap()
        
        // Wait for completion (in test, advance time)
        // Verify completion view appears
        XCTAssertTrue(app.staticTexts["Great focus!"].exists)
    }
}
```

### Critical Test Cases (Must Pass Before Launch)
- [ ] Timer drift ≤ 1s over 2 hours (real device test)
- [ ] Session survives incoming phone call
- [ ] Session survives app backgrounding < 3s (no Resume Wall)
- [ ] Session survives app backgrounding > 3s (Resume Wall appears)
- [ ] Session survives force quit and app restart
- [ ] Urge Hold requires full 10-second press
- [ ] Urge Hold cancels if finger lifts early
- [ ] Streak increments on consecutive days
- [ ] Streak resets after gap > 1 day
- [ ] Break bank awarded when urgeHoldAttempts = 0

## Performance Requirements

### Timer Reliability
- **Drift tolerance**: ≤ 1 second over 2 hours
- **Persistence frequency**: Every 60 seconds + all lifecycle events
- **Recovery time**: < 1 second after crash
- **Background survival**: Up to 3 minutes without termination

### UI Performance
- **60 FPS**: All animations and scrolling
- **Launch time**: < 2 seconds cold start
- **Memory footprint**: < 100MB during active session
- **Battery impact**: Minimal (optimize Timer.publish frequency)

### Asset Optimization
- **Images**: Use @2x and @3x assets, compress PNGs
- **Animations**: Keep GIF/sprite sheets < 2MB each
- **Scene backgrounds**: Loop seamlessly without visible seams

## Development Workflow

### Adding New Features
1. Start with model changes if needed
2. Update ViewModel with new state/logic
3. Create/modify views to reflect state
4. Add persistence if state needs to survive restarts
5. Write unit tests for logic
6. Write UI tests for critical flows
7. Test on physical device (especially timer features)

### Debugging Timer Issues
```swift
// Add debug logging to TimerViewModel
#if DEBUG
private func logTimerState() {
    print("Timer Debug:")
    print("  - Status: \(currentSession?.status ?? .notStarted)")
    print("  - Target: \(currentSession?.targetMinutes ?? 0) min")
    print("  - Elapsed: \(elapsedSeconds) seconds")
    print("  - Drift: \(calculatedDrift) seconds")
}
#endif
```

### Testing on Device
**Critical**: Timer tests MUST run on physical devices, not just simulator.
- Simulator doesn't accurately reflect backgrounding behavior
- Phone calls can only be tested on real devices
- Battery/performance characteristics differ

### Pre-Launch Checklist
- [ ] All acceptance tests pass on iPhone 13, 14, 15
- [ ] Timer tested with 2-hour real-time session
- [ ] Crash-free rate > 99% in TestFlight
- [ ] No force unwraps in production code
- [ ] All user-facing strings are clear and concise
- [ ] Privacy policy covers data collection
- [ ] App Store screenshots and metadata ready

## Common Tasks

### Adding a New Preset Duration
1. Update `HomeView.swift` with new button
2. No other changes needed (system is duration-agnostic)

### Adding a New Scene
1. Add assets to `Assets.xcassets/Scenes/`
2. Create `Scene` model instance in `SceneManager.swift`
3. Add scene type to `SceneType` enum
4. Update `SceneViewModel` to handle new type

### Modifying Enforcement Behavior
1. Update `EnforcementLevel` enum if adding new level
2. Modify `TimerViewModel.applyEnforcement()` method
3. Update UI in `SettingsView.swift` if user-configurable
4. Test all enforcement levels thoroughly

### Changing Persistence Schema
1. Update `TimerSession` model (add/remove/rename fields)
2. Bump schema version in `TimerPersistence`
3. Add migration logic in `restore()` method
4. Test migration from old version to new version

## Known Issues & Workarounds

### iOS Background Task Limitations
- Background execution time is limited (~30 seconds)
- Work around: Persist state frequently, use local notifications
- Accept: Timer may need Resume Wall on return if iOS terminates

### Scene Animation Performance
- Issue: Large GIFs can cause frame drops
- Workaround: Use sprite sheets with manual frame control
- Target: Keep scene assets < 2MB each

### Simulator vs Device Differences
- Issue: Timer behaves differently in simulator
- Solution: Always test timer features on real device
- Critical for: Backgrounding, phone calls, Focus Mode integration

## Resources

### Internal Documentation
- Product Requirements Doc: See project documentation
- Design System: See Joyce's Figma (linked in project notes)
- Roadmap: See project timeline

### External References
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [Background Tasks](https://developer.apple.com/documentation/backgroundtasks)
- [Focus Modes](https://developer.apple.com/documentation/appintents/focus-intents)

## Contact

- **Developer**: Ray (learning Swift as first programming language)
- **Designer**: Joyce (UI/UX, mascot art, market research)
- **Advisors**: Nick, Harrison (business strategy)
- **Target Launch**: February 2025
- **Budget**: AUD $750-950 (self-funded)