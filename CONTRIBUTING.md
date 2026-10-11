# Contributing to Music Player

Thank you for your interest in contributing! This document outlines the process for contributing to this project.

## How to Contribute

### Reporting Bugs
- Check existing issues first to avoid duplicates
- Use the bug report template when creating a new issue
- Include steps to reproduce, expected vs actual behavior, device info, and logs if applicable

### Suggesting Features
- Use the feature request template
- Explain the use case and why it would benefit users
- Be open to discussion and iteration

### Pull Requests
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes following the code style guidelines below
4. Run tests and ensure they pass: `flutter test`
5. Run analysis: `flutter analyze`
6. Format code: `dart format .`
7. Commit with clear, descriptive messages
8. Push to your fork and open a PR against `main`

## Code Style Guidelines

### Dart/Flutter
- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter_lints` rules (enforced by `flutter analyze`)
- Run `dart format .` before committing
- Prefer `const` constructors where possible
- Avoid `print()` statements; use the `app_logger` service instead

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
- `feat: add YouTube search filters`
- `fix: resolve download queue crash on Android 14`
- `docs: update README with new features`
- `refactor: simplify audio handler initialization`
- `test: add unit tests for download queue`

### Project Structure
Follow the feature-first architecture:
```
lib/
├── app/              # App shell, theme, DI bindings
├── core/             # Services, utils, shared widgets
└── features/
    ├── library/      # Local library: scan, cache, home UI
    ├── player/       # Audio handler + player UI
    ├── youtube/      # Search, downloads, conversion queue
    └── permissions/  # Permission check flow
```

Each feature owns its `controller/`, `data/`, and `presentation/` layers.

## Testing
- Write unit tests for business logic (controllers, services, repositories)
- Write widget tests for UI components
- Aim for meaningful coverage over arbitrary percentages
- Run `flutter test` before submitting PR

## Legal Disclaimer
By contributing, you agree that your contributions will be licensed under the same MIT License that covers the project. Ensure you have the right to contribute the code.

## Questions?
Open a discussion or issue if you need clarification on any of these guidelines.