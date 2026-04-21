#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# TITLE:    LX-InstallObsidian
# AUTHOR:   JBOrunon
# WRITTEN:  2025-12-09
# MODIFIED: 2026-04-21 — renamed to LX- convention, updated header
# LLM:      Claude Sonnet 4.6
# ------------------------------------------------------------------------------
#
# SYNOPSIS
#   Downloads and installs the latest Obsidian AppImage for the current architecture.
#
# DESCRIPTION
#   Fetches the latest Obsidian release from the GitHub API, downloads the
#   correct AppImage (x86_64 or arm64), extracts the icon using unsquashfs
#   (no FUSE required), and creates a .desktop entry. Cleans up stale AppImages
#   from previous versions. Safe to re-run — skips download if already current.
#
# REQUIRES
#   bash 4+, curl, jq, unsquashfs (auto-installed via apt/dnf if missing)
#
# REPO
#   https://github.com/JBOrunon/toolbox
#
# ------------------------------------------------------------------------------

set -euo pipefail

# ---------------------------------------------------------------------------
# Config — edit these if needed
# ---------------------------------------------------------------------------
APP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"
DESKTOP_FILE="$APP_DIR/obsidian.desktop"
GITHUB_API="https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest"

# ---------------------------------------------------------------------------
# 1. Check dependencies
# ---------------------------------------------------------------------------
for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: '$cmd' is required but not installed."
        echo "       Install it with: sudo apt install $cmd"
        exit 1
    fi
done

mkdir -p "$APP_DIR" "$ICON_DIR"

# ---------------------------------------------------------------------------
# 2. Detect architecture and pick the right AppImage asset
# ---------------------------------------------------------------------------
ARCH="$(uname -m)"  # x86_64 or aarch64

echo "==> Detected architecture: $ARCH"
echo "==> Fetching latest Obsidian release info from GitHub ..."

RELEASE_JSON=$(curl -fsSL "$GITHUB_API")
VERSION=$(echo "$RELEASE_JSON" | jq -r '.tag_name' | sed 's/^v//')

if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    # ARM: pick the AppImage that contains "arm64"
    DOWNLOAD_URL=$(echo "$RELEASE_JSON" | jq -r \
        '.assets[] | select(.name | test("AppImage")) | select(.name | test("arm64")) | .browser_download_url' \
        | head -1)
else
    # x86_64: pick the AppImage that does NOT contain "arm64"
    DOWNLOAD_URL=$(echo "$RELEASE_JSON" | jq -r \
        '.assets[] | select(.name | test("AppImage")) | select(.name | test("arm64") | not) | .browser_download_url' \
        | head -1)
fi

if [[ -z "$DOWNLOAD_URL" ]]; then
    echo "ERROR: Could not find an AppImage asset for arch '$ARCH' in the latest release."
    echo "       Check https://github.com/obsidianmd/obsidian-releases/releases"
    exit 1
fi

APPIMAGE_NAME="Obsidian-${VERSION}-${ARCH}.AppImage"
APPIMAGE_PATH="$APP_DIR/$APPIMAGE_NAME"

echo "    Latest version : $VERSION"
echo "    Download URL   : $DOWNLOAD_URL"

# ---------------------------------------------------------------------------
# 3. Download the AppImage (atomic: write to .tmp, then rename)
# ---------------------------------------------------------------------------
# Remove any stale AppImages from previous versions or wrong arch
shopt -s nullglob
for stale in "$APP_DIR"/Obsidian*.AppImage; do
    if [[ "$stale" != "$APPIMAGE_PATH" ]]; then
        echo "    Removing stale AppImage: $stale"
        rm -f "$stale"
    fi
done
shopt -u nullglob

if [[ -f "$APPIMAGE_PATH" ]]; then
    echo "==> AppImage already up to date at $APPIMAGE_PATH — skipping download."
else
    echo "==> Downloading $APPIMAGE_NAME ..."
    TMP_PATH="${APPIMAGE_PATH}.tmp"
    curl -L --progress-bar "$DOWNLOAD_URL" -o "$TMP_PATH"
    mv "$TMP_PATH" "$APPIMAGE_PATH"
    echo "    Saved to: $APPIMAGE_PATH"
fi

# ---------------------------------------------------------------------------
# 4. Make the AppImage executable
# ---------------------------------------------------------------------------
echo "==> Setting executable permission ..."
chmod +x "$APPIMAGE_PATH"
echo "    Done."

# ---------------------------------------------------------------------------
# 5. Extract the icon using unsquashfs (no FUSE needed)
# ---------------------------------------------------------------------------
echo "==> Extracting icon from AppImage ..."

EXTRACT_DIR="$(mktemp -d)"
trap 'rm -rf "$EXTRACT_DIR"' EXIT

ICON_DEST="obsidian"  # fallback: system icon name

if ! command -v unsquashfs &>/dev/null; then
    echo "    'unsquashfs' not found — installing squashfs-tools ..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y squashfs-tools
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y squashfs-tools
    else
        echo "    ERROR: Cannot auto-install squashfs-tools. Please run: sudo apt install squashfs-tools"
        exit 1
    fi
fi

# AppImages embed a squashfs payload after an ELF runtime header.
# Find the byte offset of the squashfs magic before passing to unsquashfs.
SQUASHFS_OFFSET=$(grep -obam1 $'sqsh\|hsqs' "$APPIMAGE_PATH" | head -1 | cut -d: -f1)

if [[ -z "$SQUASHFS_OFFSET" ]]; then
    echo "    WARNING: Could not locate squashfs payload in AppImage — skipping icon extraction."
else
    echo "    squashfs offset: $SQUASHFS_OFFSET"

    # Try the known icon path first (fast)
    unsquashfs -q -f -offset "$SQUASHFS_OFFSET" -d "$EXTRACT_DIR/squashfs-root" \
        "$APPIMAGE_PATH" \
        "usr/share/icons/hicolor/512x512/apps/obsidian.png" 2>&1 || true

    ICON_SRC="$EXTRACT_DIR/squashfs-root/usr/share/icons/hicolor/512x512/apps/obsidian.png"

    # Broader fallback if not found at the known path
    if [[ ! -f "$ICON_SRC" ]]; then
        unsquashfs -q -f -offset "$SQUASHFS_OFFSET" -d "$EXTRACT_DIR/squashfs-root" \
            "$APPIMAGE_PATH" "usr/share/icons/*" 2>&1 || true
        ICON_SRC=$(find "$EXTRACT_DIR" \( -iname "obsidian.png" -o -iname "obsidian.svg" \) | head -1 || true)
    fi

    if [[ -n "$ICON_SRC" && -f "$ICON_SRC" ]]; then
        ICON_EXT="${ICON_SRC##*.}"
        ICON_DEST="$ICON_DIR/obsidian.$ICON_EXT"
        cp "$ICON_SRC" "$ICON_DEST"
        echo "    Icon saved to: $ICON_DEST"
    else
        echo "    WARNING: Could not extract icon. Falling back to system icon name 'obsidian'."
    fi
fi

# Refresh icon cache
gtk-update-icon-cache -f -t "$ICON_DIR" 2>/dev/null || true
if command -v kbuildsycoca6 &>/dev/null; then
    kbuildsycoca6 2>/dev/null || true
elif command -v kbuildsycoca5 &>/dev/null; then
    kbuildsycoca5 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 6. Create the .desktop entry
# ---------------------------------------------------------------------------
echo "==> Writing .desktop file to $DESKTOP_FILE ..."

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Obsidian
Comment=A powerful knowledge base that works on local Markdown files
Exec="$APPIMAGE_PATH" --no-sandbox %u
Icon=$ICON_DEST
Terminal=false
Type=Application
Categories=Office;TextEditor;
MimeType=x-scheme-handler/obsidian;
StartupWMClass=obsidian
EOF

chmod +x "$DESKTOP_FILE"

if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$APP_DIR" 2>/dev/null || true
fi
echo "    Done."

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "============================================================"
echo " Obsidian installation complete!"
echo "   AppImage : $APPIMAGE_PATH"
echo "   Icon     : $ICON_DEST"
echo "   .desktop : $DESKTOP_FILE"
echo "============================================================"
echo " Launch Obsidian from your application menu, or run:"
echo "   $APPIMAGE_PATH --no-sandbox"
