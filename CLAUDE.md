# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter app for endocrinologists to manage patients, clinical exams, and lab results. Full spec in `spec/initial-requirements.md`.

## Development Commands

```bash
flutter run
flutter analyze
flutter test
flutter test test/<file>   # single test
flutter build web --pwa-strategy none
```

## Code Style

- Log with `log` from `dart:developer` — never `print` or `debugPrint`
- Small composable widgets, not large monolithic ones
- Flex values in Rows/Columns instead of hardcoded sizes
- Theme via `MaterialApp` `theme`/`darkTheme` — no hardcoded colors in widgets
- Dark mode is the default
- Must work on iPad, iPhone, Android, macOS, and Windows
