# Changelog

All notable changes to Skein are recorded here. Skein follows Semantic Versioning; the bump rules and approval gate are defined in [`docs/release-guide.md`](docs/release-guide.md).

## [Unreleased]

## [1.2.2] - 2026-08-28

### Fixed

- Closed memory leak in `ScreenCapture.captureWindows` by ensuring allocated unsafe buffer pointer is deallocated on scope exit.
- Fixed premature loop termination in menu bar item spacing manager so non-matching apps continue instead of aborting the restart loop.
- Clamped CGS window list array slice bounds across private bridging helpers to eliminate out-of-bounds crash risks under high window churn.
- Updated repository URL in the About settings pane to point to the renamed `bavanchun/ariadnev-skein` repository.

### Changed

- Updated application `AccentColor` to warm rope orange (`#E86A33`) to align with the new app icon identity.

## [1.2.1] - 2026-08-28

### Changed

- Skein has its own app icon: a rope tied into an infinity loop on a warm orange field, drawn in Icon Composer so macOS 26 renders it with the system's own material, lighting, and dark and tinted variants. The About tab and search panel mark are redrawn from the same figure. This replaces the last artwork inherited from Ice.

### Added

- `Scripts/make-dmg.sh` builds a disk image for the website download, staging the app beside an `/Applications` shortcut. Sparkle continues to update from the ZIP, so the update feed is unchanged.

## [1.2.0] - 2026-08-23

### Changed

- The app is now **Skein**, part of the Ariadnev ecosystem. Everything visible was renamed: app name, Xcode project and scheme, source folder, Swift symbols, menu titles, and documentation.
- The bundle identifier moved to `com.ariadnev.Skein`. Settings, the menu bar layout, and hotkeys are imported automatically on first launch, so nothing needs to be rebuilt by hand.
- Update checks now resolve through `skein.ariadnev.com` rather than a GitHub repository URL. The feed address is baked into every build, so routing it through an address the project controls means a future move cannot cut off updates again.
- The project left GitHub's fork network and lives at [`bavanchun/ariadnev-skein`](https://github.com/bavanchun/ariadnev-skein). It remains GPL-3.0 and derived from [Ice](https://github.com/jordanbaird/Ice); Jordan Baird's copyright is unchanged.

### Upgrade notes

macOS ties Accessibility and Screen Recording to an app's bundle identifier, so both permissions must be granted again in System Settings → Privacy & Security. Frost can be removed once Skein is running.

## [1.1.0] - 2026-07-28

### Added

- Documented development workflow in [`docs/DEVELOPMENT_WORKFLOW.md`](docs/DEVELOPMENT_WORKFLOW.md): trunk-based branching, pull requests into `main`, Conventional Commits, and the upstream synchronization policy.
- Documented the upstream Ice relationship and sync state in [`docs/UPSTREAM.md`](docs/UPSTREAM.md).

### Changed

- The menu bar icon formerly listed as "Ice Cube" is now **Snowflake**, drawn from SF Symbols. Anyone who had selected the old icon is moved to Snowflake automatically on first launch; nothing needs to be done by hand.
- Release tags are now SSH-signed. `main` is protected: changes reach it through pull requests only.

### Removed

- The Ice Cube image assets, the last Ice-branded artwork outside the app icon.

## [1.0.1] - 2026-07-28

### Fixed

- Removed Sparkle's update-permission prompt, which appeared on first launch with buttons that could not be clicked. As a menu bar accessory app, Frost cannot bring that dialog to the front. Automatic update checks are now on by default and both settings remain available in Settings → About.

### Changed

- Completed the rebrand in files the initial sweep missed: SwiftLint configuration, funding metadata, issue templates, and the code of conduct now refer to Frost and route to this fork.

## [1.0.0] - 2026-07-28

### Changed

- Renamed the application from Ice to Frost across every visible layer: app name, Xcode project and scheme, source folder, Swift symbols, menu titles, and documentation.
- Changed the bundle identifier to `com.vchun.Frost`.

### Upgrade notes

- macOS treats the new bundle identifier as a different application. **Accessibility and Screen Recording permissions must be granted again**, and settings from the previous build are not carried over.
- Remove any older `Ice.app` build to avoid two menu bar icons competing for the same items.

## [0.11.12] - 2026-07-27

### Added

- First personal build of the fork: own bundle identifier, signing identity, copyright, and Sparkle update feed, so it no longer shares preferences or update channel with upstream Ice.

---

Releases before this fork are documented in [jordanbaird/Ice](https://github.com/jordanbaird/Ice/releases).

[Unreleased]: https://github.com/bavanchun/ariadnev-skein/compare/v1.2.2...HEAD
[1.2.2]: https://github.com/bavanchun/ariadnev-skein/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/bavanchun/ariadnev-skein/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/bavanchun/ariadnev-skein/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/bavanchun/ariadnev-skein/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/bavanchun/ariadnev-skein/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/bavanchun/ariadnev-skein/compare/v0.11.12...v1.0.0
[0.11.12]: https://github.com/bavanchun/ariadnev-skein/releases/tag/v0.11.12
