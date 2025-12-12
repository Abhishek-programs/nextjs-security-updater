# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-12

### Added

- Initial release of Next.js Security Patch Updater
- Cross-platform support (Linux, macOS, Windows Git Bash/WSL)
- Multi-package manager support (npm, yarn, pnpm)
- Automatic scanning for package.json files (up to 4 levels deep)
- Smart version mapping for Next.js 13.x through 16.x
- Backup creation before modifying files
- Force install option (`-f` flag)
- Help documentation (`-h` flag)
- Detailed summary reporting
- Progress indicators for installations
- Error handling and recovery
- Support for patched versions:
  - 13.x, 14.x → 14.2.35
  - 15.0.x → 15.0.7
  - 15.1.x → 15.1.11
  - 15.2.x → 15.2.8
  - 15.3.x → 15.3.8
  - 15.4.x → 15.4.10
  - 15.5.x → 15.5.9
  - 16.x → 16.0.10

### Fixed

- "stdin is not a tty" warnings on Windows Git Bash
- Permission denied errors on system directories
- JSON parsing errors handled gracefully
- Script continues even if individual installs fail

### Security

- Addresses critical Next.js security vulnerabilities through automated patching

## [Unreleased]

### Planned

- Support for Next.js 17.x versions (when released)
- Interactive mode for selective updates
- Dry-run mode to preview changes
- Configuration file support (.nextjs-updater.json)
- Parallel installation option for faster processing
- Git commit automation after successful updates
- Rollback functionality

---

## Version Format

- **MAJOR**: Incompatible API changes or major feature overhauls
- **MINOR**: New features added in a backwards compatible manner
- **PATCH**: Backwards compatible bug fixes and minor improvements

## How to Update

When new Next.js security patches are released:

1. Update the `patched_version_for()` function in `update-nextjs.sh`
2. Update the version table in README.md
3. Add entry to this CHANGELOG.md
4. Commit and tag the release

Example:

```bash
git add update-nextjs.sh README.md CHANGELOG.md
git commit -m "feat: add support for Next.js 17.x patched versions"
git tag -a v1.1.0 -m "Version 1.1.0 - Next.js 17.x support"
git push origin main --tags
```
