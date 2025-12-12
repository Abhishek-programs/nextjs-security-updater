#!/usr/bin/env bash

# -------------------------------
# Cross-platform compatibility
# -------------------------------
# Don't exit on error - we want to process all packages
set -o pipefail  # Catch errors in pipes

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "Linux";;
        Darwin*)    echo "Mac";;
        CYGWIN*)    echo "Windows";;
        MINGW*)     echo "Windows";;
        MSYS*)      echo "Windows";;
        *)          echo "Unknown";;
    esac
}

OS_TYPE=$(detect_os)

# Check for required commands
check_dependencies() {
    local missing=()
    
    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Error: Missing required dependencies: ${missing[*]}"
        echo ""
        echo "Please install them:"
        case $OS_TYPE in
            Linux)
                echo "  Ubuntu/Debian: sudo apt-get install jq"
                echo "  Fedora/RHEL: sudo dnf install jq"
                echo "  Arch: sudo pacman -S jq"
                ;;
            Mac)
                echo "  Homebrew: brew install jq"
                ;;
            Windows)
                echo "  Git Bash: Download from https://stedolan.github.io/jq/download/"
                echo "  WSL: sudo apt-get install jq"
                ;;
        esac
        exit 1
    fi
}

check_dependencies

# -------------------------------
# Options and counters
# -------------------------------
FORCE=false
SCANNED=0
UPDATED=0
SKIPPED=0
FAILED_INSTALL=0
UPGRADED_FILES=()

while [[ "$1" != "" ]]; do
    case $1 in
        -f|--force ) FORCE=true ;;
        -h|--help )
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -f, --force    Force package install even without lockfile"
            echo "  -h, --help     Show this help message"
            exit 0
            ;;
        * ) echo "Unknown option: $1"; echo "Use -h for help"; exit 1 ;;
    esac
    shift
done

# -------------------------------
# Ask user for package manager
# -------------------------------
echo "Which package manager do you want to use?"
read -p "(npm/yarn/pnpm): " PKG_MANAGER
PKG_MANAGER=$(echo "$PKG_MANAGER" | tr '[:upper:]' '[:lower:]' | xargs)

if [[ "$PKG_MANAGER" != "npm" && "$PKG_MANAGER" != "yarn" && "$PKG_MANAGER" != "pnpm" ]]; then
    echo "Invalid package manager: $PKG_MANAGER"
    exit 1
fi

# Verify package manager is installed
if ! command -v "$PKG_MANAGER" &> /dev/null; then
    echo "Error: $PKG_MANAGER is not installed or not in PATH"
    exit 1
fi

# -------------------------------
# Patched Next.js versions
# -------------------------------
patched_version_for() {
    case "$1" in
        13) echo "14.2.35" ;;
        14) echo "14.2.35" ;;
        15.0) echo "15.0.7" ;;
        15.1) echo "15.1.11" ;;
        15.2) echo "15.2.8" ;;
        15.3) echo "15.3.8" ;;
        15.4) echo "15.4.10" ;;
        15.5) echo "15.5.9" ;;
        16) echo "16.0.10" ;;
        *) echo "" ;;
    esac
}

# -------------------------------
# Find package.json files
# -------------------------------
echo ""
echo "Scanning for package.json files..."
echo ""

# Use process substitution with proper null-byte handling for paths with spaces
while IFS= read -r -d '' file; do
    SCANNED=$((SCANNED+1))
    dir=$(dirname "$file")

    # Read declared Next.js version
    declared=$(jq -r '.dependencies.next // .devDependencies.next // empty' "$file" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "⚠ Failed to parse $file, skipping"
        SKIPPED=$((SKIPPED+1))
        continue
    fi
    
    [ -z "$declared" ] && continue

    # Clean version (remove ^, ~, etc.)
    clean_version=$(echo "$declared" | sed 's/^[\^~>=<]*//' | sed 's/[[:space:]]//g')
    major=$(echo "$clean_version" | cut -d. -f1)
    minor=$(echo "$clean_version" | cut -d. -f2)
    
    # Handle edge cases
    if [[ ! "$major" =~ ^[0-9]+$ ]]; then
        echo "⚠ Invalid version format in $file (version: $declared), skipping"
        SKIPPED=$((SKIPPED+1))
        continue
    fi
    
    major_minor="$major.$minor"

    # Determine patched version
    patched_version=$(patched_version_for "$major_minor")
    [ -z "$patched_version" ] && patched_version=$(patched_version_for "$major")

    if [ -z "$patched_version" ]; then
        echo "⚠ Cannot determine patched version for $file (version: $declared), skipping"
        SKIPPED=$((SKIPPED+1))
        continue
    fi

    # Update package.json if needed
    if [ "$clean_version" != "$patched_version" ]; then
        echo "Updating $file: $declared → $patched_version"
        
        # Create backup
        cp "$file" "$file.backup"
        
        # Update with jq - handle both dependencies and devDependencies
        jq --arg v "$patched_version" '
            if .dependencies.next then .dependencies.next = $v else . end |
            if .devDependencies.next then .devDependencies.next = $v else . end
        ' "$file" > "$file.tmp"
        
        if [ $? -eq 0 ] && [ -s "$file.tmp" ]; then
            mv "$file.tmp" "$file"
            rm -f "$file.backup"
            UPDATED=$((UPDATED+1))
            UPGRADED_FILES+=("$file")
        else
            echo "⚠ Failed to update $file, restoring backup"
            mv "$file.backup" "$file"
            rm -f "$file.tmp"
            SKIPPED=$((SKIPPED+1))
            continue
        fi
    else
        echo "✓ $file already has patched version $patched_version"
    fi

    # Decide whether to run install
    RUN_INSTALL=false
    if [ "$FORCE" = true ]; then
        RUN_INSTALL=true
    else
        case $PKG_MANAGER in
            npm) [ -f "$dir/package-lock.json" ] && RUN_INSTALL=true ;;
            yarn) [ -f "$dir/yarn.lock" ] && RUN_INSTALL=true ;;
            pnpm) [ -f "$dir/pnpm-lock.yaml" ] && RUN_INSTALL=true ;;
        esac
    fi

    # Run the package manager
    if [ "$RUN_INSTALL" = true ]; then
        echo "Running $PKG_MANAGER install in $dir"
        
        # Change directory safely
        if ! cd "$dir" 2>/dev/null; then
            echo "⚠ Cannot access directory $dir"
            FAILED_INSTALL=$((FAILED_INSTALL+1))
            continue
        fi
        
        # Run package manager with proper error handling
        install_success=false
        install_output=""
        
        case "$PKG_MANAGER" in
            yarn)
                # Run yarn and capture output, filtering TTY warning
                # Using --prefer-offline to speed up installs
                echo -n "  Installing dependencies... "
                install_output=$(FORCE_COLOR=0 CI=true yarn install --non-interactive --frozen-lockfile=false --prefer-offline 2>&1 || true)
                install_exit_code=$?
                
                # Filter out the TTY warning
                filtered_output=$(echo "$install_output" | grep -v "stdin is not a tty" || true)
                
                # Check exit code (0 = success)
                if [ $install_exit_code -eq 0 ]; then
                    install_success=true
                    echo "✓ Done"
                    # Show summary if available
                    echo "$filtered_output" | grep -E "(Done in|Already up-to-date)" | head -1 || true
                else
                    echo "✗ Failed (exit code: $install_exit_code)"
                    if [ -n "$filtered_output" ]; then
                        echo "--- Error output ---"
                        echo "$filtered_output"
                        echo "--- End error ---"
                    fi
                fi
                ;;
            npm)
                echo -n "  Installing dependencies... "
                install_output=$(npm install --no-progress --no-audit 2>&1 || true)
                install_exit_code=$?
                if [ $install_exit_code -eq 0 ]; then
                    install_success=true
                    echo "✓ Done"
                else
                    echo "✗ Failed (exit code: $install_exit_code)"
                    [ -n "$install_output" ] && echo "$install_output"
                fi
                ;;
            pnpm)
                echo -n "  Installing dependencies... "
                install_output=$(pnpm install --no-frozen-lockfile 2>&1 || true)
                install_exit_code=$?
                if [ $install_exit_code -eq 0 ]; then
                    install_success=true
                    echo "✓ Done"
                else
                    echo "✗ Failed (exit code: $install_exit_code)"
                    [ -n "$install_output" ] && echo "$install_output"
                fi
                ;;
        esac
        
        if [ "$install_success" = false ]; then
            echo "⚠ $PKG_MANAGER install failed in $dir"
            FAILED_INSTALL=$((FAILED_INSTALL+1))
        else
            echo "✓ Successfully installed dependencies in $dir"
        fi
        
        # Return to previous directory
        cd - > /dev/null 2>&1 || true
    else
        echo "⏭ Skipping install in $dir (no matching lockfile, use -f to force)"
    fi
    
    echo ""

done < <(find "$(pwd)" -maxdepth 4 -name "package.json" -type f ! -path "*/node_modules/*" ! -path "*/.next/*" -print0 2>/dev/null)

# -------------------------------
# Summary
# -------------------------------
echo ""
echo "==================== Summary ===================="
echo "Total package.json scanned: $SCANNED"
echo "Packages updated: $UPDATED"
echo "Skipped due to errors/unknown version: $SKIPPED"
echo "Failed installs: $FAILED_INSTALL"

if [ $UPDATED -gt 0 ]; then
    echo ""
    echo "Next.js upgraded in the following files:"
    for f in "${UPGRADED_FILES[@]}"; do
        echo " - $f"
    done
fi

if [ $FAILED_INSTALL -gt 0 ]; then
    echo ""
    echo "⚠ Warning: Some installations failed. Please check the output above."
fi

echo "================================================="

exit 0