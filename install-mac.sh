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
ZIP_URL="https://aiproductivity.dev/dist/MedRecordsAI-DEMO-v2.2.0.zip"
ZIP_FILE="/tmp/MedRecordsAI-DEMO.zip"

# ── Step 1: Check Python ──────────────────────────────────────────────
echo "  [1/4] Checking for Python..."

PYTHON_CMD=""
if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
    PY_VER=$(python -c "import sys; print(sys.version_info.major)" 2>/dev/null || echo "0")
    if [ "$PY_VER" -ge 3 ]; then
        PYTHON_CMD="python"
    fi
fi

if [ -z "$PYTHON_CMD" ]; then
    echo ""
    echo "  ----------------------------------------------------------------"
    echo "    Python 3 is required but was not found on this computer."
    echo "  ----------------------------------------------------------------"
    echo ""
    echo "  Install Python using one of these methods:"
    echo ""
    echo "    Homebrew:  brew install python3"
    echo "    Website:   https://www.python.org/downloads/"
    echo ""
    echo "  After installing Python, run this installer again."
    echo ""
    exit 1
fi

PY_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
echo "        Python $PY_VERSION found."
echo ""

# ── Step 2: Download ──────────────────────────────────────────────────
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

# ── Step 3: Extract ───────────────────────────────────────────────────
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

# ── Step 4: Launch ────────────────────────────────────────────────────
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
