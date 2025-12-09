git push#!/usr/bin/env bash
#
# linux-prep-toolbox.sh
#
# Prepares a working directory for Linux toolbox scripts.
# - Default work dir: $HOME/jb
# - Writes a README.txt into the work dir
# - Optionally downloads linux-get-system-info.sh and linux-get-network-info.sh
#
# Repo: https://github.com/JBOrunon/toolbox

set -u
set -o pipefail

WORK_DIR="${HOME}/jb"
DOWNLOAD_TOOLS=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dir PATH] [--download-tools]

Options:
  -d, --dir PATH         Working directory (default: \$HOME/jb)
      --download-tools   Download Linux toolbox scripts into the working dir
  -h, --help             Show this help message and exit

Examples:
  # Basic: just create ~/jb and README.txt
  $(basename "$0")

  # Create custom dir and download tools
  $(basename "$0") --dir /tmp/jb --download-tools
EOF
}

# --- Argument parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dir)
      WORK_DIR="$2"
      shift 2
      ;;
    --download-tools)
      DOWNLOAD_TOOLS=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

echo "Preparing Linux toolbox working directory..."
echo "Target directory: ${WORK_DIR}"
echo

# --- Ensure working directory exists ---
if [[ -e "$WORK_DIR" && ! -d "$WORK_DIR" ]]; then
  echo "ERROR: '$WORK_DIR' exists but is not a directory." >&2
  exit 1
fi

mkdir -p "$WORK_DIR"

# --- Write README.txt ---
README_PATH="${WORK_DIR}/README.txt"

cat > "$README_PATH" <<'EOF'
Linux Toolbox Working Directory
===============================

This folder was prepared by linux-prep-toolbox.sh.

Default location:
  $HOME/jb

Purpose:
- Provide a central location for temporary troubleshooting scripts and reports.
- All scripts are sourced from:
    https://github.com/JBOrunon/toolbox

Notes:
- This folder is safe to delete once troubleshooting is complete.
- Scripts are designed to be read-only (collecting information, not changing config)
  unless explicitly documented otherwise.

Common scripts (Linux):
- linux-get-system-info.sh
- linux-get-network-info.sh

Recommended usage pattern:
- Download a script into this folder.
- Review the script in a text editor.
- Then run it using:
    bash ./script-name.sh

Default report locations:
- linux-get-system-info.sh writes reports under this folder (e.g., ~/jb/systeminfo-...).
- linux-get-network-info.sh writes reports under this folder (e.g., ~/jb/networkinfo-...).
EOF

echo "Wrote README: ${README_PATH}"

# --- Helper: download file using curl or wget ---
download_file() {
  local url="$1"
  local dest="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    echo "ERROR: Neither curl nor wget is available for downloads." >&2
    return 1
  fi
}

# --- Optional: download toolbox scripts ---
if $DOWNLOAD_TOOLS; then
  echo
  echo "DownloadTools requested. Downloading Linux toolbox scripts into: ${WORK_DIR}"
  echo

  BASE_URL="https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/linux"
  FILES=(
    "linux-get-system-info.sh"
    "linux-get-network-info.sh"
  )

  for name in "${FILES[@]}"; do
    SRC_URL="${BASE_URL}/${name}"
    DEST_PATH="${WORK_DIR}/${name}"

    echo "  -> ${name}"
    echo "     Source: ${SRC_URL}"
    echo "     Dest:   ${DEST_PATH}"

    if download_file "$SRC_URL" "$DEST_PATH"; then
      chmod +x "$DEST_PATH" || true
      echo "     Downloaded OK"
    else
      echo "     FAILED to download ${name}" >&2
    fi

    echo
  done
fi

echo
echo "Preparation complete."
echo "Working directory: ${WORK_DIR}"
echo "You can safely delete this folder when troubleshooting is done."
