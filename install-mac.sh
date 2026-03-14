#!/usr/bin/env bash
#
# MedRecords AI - Installer (macOS)
# Productivity AI, LLC
#

set -e

echo ""
echo "  ================================================================"
echo "    MedRecords AI - One-Click Installer (macOS)"
echo "    HIPAA-Compliant Medical Record Summarization"
echo "  ================================================================"
echo ""

INSTALL_DIR="$HOME/MedRecordsAI"
ZIP_URL="https://aiproductivity.dev/dist/MedRecordsAI-DEMO-v2.2.39.zip"
ZIP_FILE="/tmp/MedRecordsAI-DEMO.zip"
REQUIRED_PY_MAJOR=3
REQUIRED_PY_MINOR=10

# ── Step 1: Check / Install Python ────────────────────────────────
echo "  [1/4] Checking for Python ${REQUIRED_PY_MAJOR}.${REQUIRED_PY_MINOR}+..."

PYTHON_CMD=""
for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
        PY_VER=$("$candidate" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "0.0")
        PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
        PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
        if [ "$PY_MAJOR" -ge "$REQUIRED_PY_MAJOR" ] && [ "$PY_MINOR" -ge "$REQUIRED_PY_MINOR" ]; then
            PYTHON_CMD="$candidate"
            break
        fi
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo ""
    echo "  Python ${REQUIRED_PY_MAJOR}.${REQUIRED_PY_MINOR}+ is required but was not found."
    echo ""

    # Try auto-install via Homebrew
    if command -v brew >/dev/null 2>&1; then
        echo "  Homebrew detected. Installing Python automatically..."
        echo ""
        brew install python@3.12
        # Homebrew Python location
        for candidate in python3 /opt/homebrew/bin/python3 /usr/local/bin/python3; do
            if command -v "$candidate" >/dev/null 2>&1; then
                PY_VER=$("$candidate" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "0.0")
                PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
                PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
                if [ "$PY_MAJOR" -ge "$REQUIRED_PY_MAJOR" ] && [ "$PY_MINOR" -ge "$REQUIRED_PY_MINOR" ]; then
                    PYTHON_CMD="$candidate"
                    break
                fi
            fi
        done
    fi

    # Try downloading the official macOS Python installer
    if [ -z "$PYTHON_CMD" ]; then
        echo "  Downloading Python 3.12 from python.org..."
        PY_PKG_URL="https://www.python.org/ftp/python/3.12.9/python-3.12.9-macos11.pkg"
        PY_PKG_FILE="/tmp/python-3.12.9-macos11.pkg"

        if command -v curl >/dev/null 2>&1; then
            curl -fSL --progress-bar "$PY_PKG_URL" -o "$PY_PKG_FILE"
        elif command -v wget >/dev/null 2>&1; then
            wget -q --show-progress "$PY_PKG_URL" -O "$PY_PKG_FILE"
        else
            echo "  [ERROR] Cannot download Python — neither curl nor wget found."
            echo "          Please install Python 3.10+ manually:"
            echo "          https://www.python.org/downloads/"
            exit 1
        fi

        if [ -f "$PY_PKG_FILE" ]; then
            echo ""
            echo "  Installing Python 3.12 (you may be prompted for your password)..."
            sudo installer -pkg "$PY_PKG_FILE" -target /
            rm -f "$PY_PKG_FILE"

            # Check again after install
            for candidate in python3 /Library/Frameworks/Python.framework/Versions/3.12/bin/python3; do
                if command -v "$candidate" >/dev/null 2>&1 || [ -x "$candidate" ]; then
                    PYTHON_CMD="$candidate"
                    break
                fi
            done
        fi
    fi

    if [ -z "$PYTHON_CMD" ]; then
        echo ""
        echo "  ----------------------------------------------------------------"
        echo "    Could not install Python automatically."
        echo "  ----------------------------------------------------------------"
        echo ""
        echo "  Please install Python ${REQUIRED_PY_MAJOR}.${REQUIRED_PY_MINOR}+ manually:"
        echo ""
        echo "    Homebrew:  brew install python@3.12"
        echo "    Website:   https://www.python.org/downloads/"
        echo ""
        echo "  After installing Python, run this installer again."
        echo ""
        exit 1
    fi

    echo "        Python installed successfully."
fi

PY_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
echo "        Python $PY_VERSION found."
echo ""

# ── Step 2: Download ──────────────────────────────────────────────
echo "  [2/4] Downloading MedRecords AI..."
echo "        This may take a minute depending on your connection."
echo ""

if command -v curl >/dev/null 2>&1; then
    curl -fSL --progress-bar "$ZIP_URL" -o "$ZIP_FILE"
elif command -v wget >/dev/null 2>&1; then
    wget -q --show-progress "$ZIP_URL" -O "$ZIP_FILE"
else
    echo "  [ERROR] Neither curl nor wget found. Please install curl:"
    echo "          brew install curl"
    exit 1
fi

if [ ! -f "$ZIP_FILE" ]; then
    echo ""
    echo "  [ERROR] Download failed. Please check your internet connection"
    echo "  and try again. If the problem persists, download manually from:"
    echo "  https://aiproductivity.dev"
    echo ""
    exit 1
fi

echo "        Download complete."
echo ""

# ── Step 3: Extract ───────────────────────────────────────────────
echo "  [3/4] Installing to $INSTALL_DIR..."

# Clean previous installation if exists
if [ -d "$INSTALL_DIR" ]; then
    echo "        Removing previous installation..."
    rm -rf "$INSTALL_DIR"
fi

mkdir -p "$INSTALL_DIR"
unzip -q "$ZIP_FILE" -d "$INSTALL_DIR"

# Handle ZIP with top-level folder
SUBDIRS=$(find "$INSTALL_DIR" -mindepth 1 -maxdepth 1 -type d)
SUBDIR_COUNT=$(echo "$SUBDIRS" | grep -c . || true)
if [ "$SUBDIR_COUNT" -eq 1 ] && [ -f "$SUBDIRS/install.sh" ]; then
    # Move contents up from the single subfolder
    mv "$SUBDIRS"/* "$INSTALL_DIR/" 2>/dev/null || true
    mv "$SUBDIRS"/.* "$INSTALL_DIR/" 2>/dev/null || true
    rmdir "$SUBDIRS" 2>/dev/null || true
fi

# Clean up temp ZIP
rm -f "$ZIP_FILE"

# Make scripts executable
chmod +x "$INSTALL_DIR"/*.sh 2>/dev/null || true

echo "        Installed successfully."
echo ""

# ── Step 4: Launch ────────────────────────────────────────────────
echo "  [4/4] Launching MedRecords AI setup..."
echo ""
echo "  ================================================================"
echo "    The setup wizard will guide you through installation."
echo "    A browser window will open automatically."
echo "  ================================================================"
echo ""

if [ -f "$INSTALL_DIR/install.sh" ]; then
    cd "$INSTALL_DIR"
    exec ./install.sh
else
    echo "  [ERROR] Installation files not found. Please try again."
    exit 1
fi
