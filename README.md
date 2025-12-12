# Next.js Security Patch Updater

A cross-platform bash script that automatically scans your projects and updates Next.js to patched versions addressing critical security vulnerabilities.

## 🚨 Security Context

This script helps you quickly update Next.js installations to patched versions that address security vulnerabilities. It's designed to work across multiple projects in your workspace simultaneously.

## ✨ Features

- 🔍 **Automatic Scanning**: Finds all `package.json` files in your workspace (up to 4 levels deep)
- 🔄 **Smart Version Detection**: Maps your current Next.js version to the appropriate patched version
- 📦 **Multi-Package Manager Support**: Works with npm, yarn, and pnpm
- 🖥️ **Cross-Platform**: Runs on Linux, macOS, and Windows (Git Bash/WSL)
- 🛡️ **Safe Updates**: Creates backups before modifying files
- 📊 **Detailed Reporting**: Provides comprehensive summary of all changes

## 🎯 Supported Next.js Versions

The script maps the following versions to their patched equivalents:

| Current Version | Patched Version |
| --------------- | --------------- |
| 13.x            | 14.2.35         |
| 14.x            | 14.2.35         |
| 15.0.x          | 15.0.7          |
| 15.1.x          | 15.1.11         |
| 15.2.x          | 15.2.8          |
| 15.3.x          | 15.3.8          |
| 15.4.x          | 15.4.10         |
| 15.5.x          | 15.5.9          |
| 16.x            | 16.0.10         |

## 📋 Prerequisites

- **Bash**: Git Bash (Windows), or native bash (Linux/macOS)
- **jq**: JSON processor for parsing package.json files
- **Package Manager**: npm, yarn, or pnpm installed

### Installing jq

**Ubuntu/Debian:**

```bash
sudo apt-get install jq
```

**macOS (Homebrew):**

```bash
brew install jq
```

**Windows (Git Bash):**
Download from [stedolan.github.io/jq](https://stedolan.github.io/jq/download/)

**Windows (WSL):**

```bash
sudo apt-get install jq
```

## 🚀 Usage

### Basic Usage

1. Navigate to your workspace root directory
2. Run the script:

```bash
./update-nextjs.sh
```

3. Choose your package manager when prompted (npm/yarn/pnpm)

### Options

```bash
./update-nextjs.sh [OPTIONS]
```

**Available Options:**

- `-f, --force` - Force package installation even without lockfiles
- `-h, --help` - Display help message

### Examples

**Standard update with yarn:**

```bash
./update-nextjs.sh
# When prompted, enter: yarn
```

**Force installation everywhere:**

```bash
./update-nextjs.sh --force
```

## 📁 What It Does

1. **Scans** your workspace for `package.json` files (excludes `node_modules` and `.next`)
2. **Identifies** Next.js versions in both `dependencies` and `devDependencies`
3. **Updates** package.json files to patched versions
4. **Installs** dependencies if lockfiles exist (or with `--force` flag)
5. **Reports** summary of all changes and any failures

## 🔒 Safety Features

- ✅ Creates `.backup` files before modifying package.json
- ✅ Validates JSON syntax before saving changes
- ✅ Restores backups if updates fail
- ✅ Continues processing even if individual installs fail
- ✅ Skips permission-denied directories gracefully

## 📊 Output Example

```
Scanning for package.json files...

✓ /project-a/package.json already has patched version 15.0.7
⏭ Skipping install in /project-a (no matching lockfile, use -f to force)

Updating /project-b/package.json: ^14.1.0 → 14.2.35
Running yarn install in /project-b
  Installing dependencies... ✓ Done

==================== Summary ====================
Total package.json scanned: 12
Packages updated: 3
Skipped due to errors/unknown version: 1
Failed installs: 0

Next.js upgraded in the following files:
 - /project-b/package.json
 - /project-c/package.json
 - /project-d/package.json
=================================================
```

## ⚠️ Known Limitations

- Only processes files up to 4 directory levels deep (configurable in script)
- Requires lockfile present for automatic installation (override with `-f`)
- Cannot process Next.js versions not in the mapping table
- Windows: May show "stdin is not a tty" warnings (these are filtered but harmless)

## 🐛 Troubleshooting

**"jq: command not found"**

- Install jq using the instructions in Prerequisites section

**"Permission denied" errors**

- Normal for system directories (e.g., "System Volume Information" on Windows)
- These are automatically skipped

**Package manager not found**

- Ensure npm/yarn/pnpm is installed and in your PATH
- Try running `which npm` or `which yarn` to verify

**Install failures**

- Check the error output for specific issues
- Try running the package manager manually in the failed directory
- Some projects may have lockfile conflicts or version constraints

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

### Adding New Version Mappings

To add support for new Next.js versions, edit the `patched_version_for()` function:

```bash
patched_version_for() {
    case "$1" in
        13) echo "14.2.35" ;;
        # Add new versions here
        17) echo "17.0.x" ;;
        *) echo "" ;;
    esac
}
```

## 📄 License

MIT License - feel free to use this script in your projects.

## ⚡ Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd nextjs-security-updater

# Make the script executable
chmod +x update-nextjs.sh

# Run it
./update-nextjs.sh
```

---

**Note**: Always review changes and test your applications after updating Next.js versions. While this script safely updates package.json files, breaking changes between versions may require code modifications.
