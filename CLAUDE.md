# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

QuickConnections is a SwiftUI application for iOS/macOS that allows users to input two-word phrases. The app uses SwiftData for persistence and includes input validation to restrict entries to two words maximum.

## Common Development Commands

### Building the project
```bash
# Build from command line
xcodebuild -project QuickConnections.xcodeproj -scheme QuickConnections -configuration Debug build

# Clean build
xcodebuild -project QuickConnections.xcodeproj -scheme QuickConnections clean build
```

### Running the app
The app is designed to be run through Xcode. Open QuickConnections.xcodeproj in Xcode and press Cmd+R to build and run.

### Testing
Currently no test targets are configured. To add tests, create a new test target in Xcode.

## Architecture

The app follows a standard SwiftUI + MVVM architecture with Apple's Foundation Models integration:

- **QuickConnectionsApp.swift**: Main app entry point that sets up the SwiftData ModelContainer for persistent storage
- **ContentView.swift**: Primary UI view containing:
  - Text input field with two-word validation
  - Generate button that triggers AI word generation
  - Scrollable grid of generated words in rounded rectangles
  - Progress indicators and empty states
- **GenerationViewModel.swift**: ObservableObject view model that:
  - Manages the LanguageModelSession with Foundation Models
  - Handles model availability checking
  - Generates 15-20 related words using on-device AI
  - Animates word appearance with staggered timing
- **Item.swift**: SwiftData model for storing timestamps of generation events
- **test.swift**: Contains a Swift Playground for testing LanguageModel capabilities

The app uses:
- SwiftUI for the user interface
- FoundationModels framework for on-device AI generation
- SwiftData for data persistence
- Swift 5.0 with upcoming feature flags enabled
- Targets iOS 26.0+ (beta)