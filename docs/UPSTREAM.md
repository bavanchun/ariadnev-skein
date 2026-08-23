# Provenance

Skein derives from [jordanbaird/Ice](https://github.com/jordanbaird/Ice), licensed under GPL-3.0. The overwhelming majority of the source code originates from that project, and Jordan Baird's copyright is preserved verbatim in [`LICENSE`](../LICENSE).

Skein is **not a maintained fork**. It left GitHub's fork network in August 2026 and is developed independently, with its own name, release channel, and direction. What that changes is repository metadata and product identity — not licensing. Skein stays GPL-3.0, and any distribution carries the same obligations it always did.

## Origin

- Upstream repository: https://github.com/jordanbaird/Ice
- Tracking branch: `upstream/main`
- Last synchronized revision: `11edd39115f3f43a83ae114b5348df6a0e1741cf` ("Update issue templates", 2025-09-20)
- Last synchronized release: none — the divergence point is ahead of upstream's most recent tagged release (`0.11.12`, 2024-10-29)

Skein's history contains every upstream `main` commit up to that revision; all divergence since is Skein-side. The upstream remote is still worth keeping so security fixes can be cherry-picked:

```bash
git remote add upstream https://github.com/jordanbaird/Ice.git
git fetch upstream
git log --oneline main..upstream/main   # what upstream has that Skein does not
```

## Lineage

The project has carried three names. Both renames were complete sweeps across code, identifiers, and documentation:

| Name | Bundle identifier | Period |
|---|---|---|
| Ice | `com.jordanbaird.Ice` | upstream |
| Frost | `com.vchun.Frost` | 1.0.0 – 1.1.0 |
| Skein | `com.ariadnev.Skein` | 2.0.0 onward |

`MigrationManager.migrate2_0_0` imports the Frost defaults domain on first launch, which is why it is the one place in the source that still names `com.vchun.Frost` and the old defaults keys. Those references are load-bearing; do not sweep them.

## Skein-specific changes

- Product identity: app name, `AppIcon` usage, and every user-facing string
- Bundle identifier `com.ariadnev.Skein` and `DEVELOPMENT_TEAM`, replacing upstream's `com.jordanbaird.Ice`
- Xcode project, target, scheme, and source folder renamed from `Ice` to `Skein`
- Swift symbols and filenames renamed from `Ice*` to `Skein*`
- Menu bar icon options: upstream's "Ice Cube" entry is a Snowflake SF Symbol here, the `IceCube` image assets are gone, and the surviving stroke image is `SkeinMarkStroke` at the asset catalog root
- Sparkle update configuration: `SUFeedURL` resolves through `https://ariadnev.com/skein/appcast.xml` rather than a repository URL, `SUPublicEDKey` is this project's key, and `SUEnableAutomaticChecks` suppresses the permission prompt that an accessory app cannot make clickable
- Settings migration across both bundle identifier changes
- Release infrastructure: unsigned build plus manual inside-out `codesign`, documented in [`release-guide.md`](release-guide.md)
- Documentation: README, `FREQUENT_ISSUES.md`, [`DEVELOPMENT_WORKFLOW.md`](DEVELOPMENT_WORKFLOW.md), and this file

## Integration policy

Security and critical fixes are prioritized. Features are evaluated individually. All upstream integrations use a dedicated `upstream/ice-vX.Y.Z` branch and a pull request, per [`DEVELOPMENT_WORKFLOW.md`](DEVELOPMENT_WORKFLOW.md) § 20.

Upstream is never merged directly into `main`.

## Known conflict areas

Every item under "Skein-specific changes" is a conflict candidate. The renames make conflicts unavoidable rather than occasional: upstream still calls the project `Ice` at the project-file, symbol, filename, and string level, so any upstream commit touching those layers will conflict.

The highest-risk areas, in order:

- `Skein.xcodeproj/project.pbxproj` — upstream's `Ice.xcodeproj` has no shared path with it
- Swift files renamed from `Ice*.swift`, where Git may not detect the rename
- `Skein/Info.plist` — Sparkle keys diverge completely
- User-facing strings and menu titles
- `README.md`, `LICENSE`, and release documentation

After every upstream merge, verify the identity is intact before opening the pull request:

```bash
grep -rn "\bIce\b" Skein/ --include="*.swift" --include="*.plist"
grep -rn "Frost" Skein/ | grep -v MigrationManager.swift    # must be empty
grep -E "PRODUCT_BUNDLE_IDENTIFIER|MARKETING_VERSION" Skein.xcodeproj/project.pbxproj | sort -u
```

Update this file after every upstream synchronization.
