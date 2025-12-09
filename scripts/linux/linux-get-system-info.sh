#!/usr/bin/env bash
#
# linux-get-system-info.sh
#
# Collects general system information into a text report.
# Default output: $HOME/jb/systeminfo-HOST-YYYYMMDD-HHMMSS.txt
#
# Repo: https://github.com/JBOrunon/toolbox

set -u
set -o pipefail

WORK_DIR="${HOME}/jb"
OUTPUT_PATH=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dir PATH] [--output FILE]

Options:
  -d, --dir PATH      Working directory (default: \$HOME/jb)
  -o, --output FILE   Explicit output file path
  -h, --help          Show this help message and exit

Examples:
  # Default: writes under ~/jb
  $(basename "$0")

  # Specify output file
  $(basename "$0") --output /tmp/systeminfo.txt

  # Custom working directory (used only if --output is not given)
  $(basename "$0") --dir /tmp/jb
EOF
}

# --- Argument parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dir)
      WORK_DIR="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT_PATH="$2"
      shift 2
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

# --- Determine output path ---
if [[ -z "${OUTPUT_PATH}" ]]; then
  mkdir -p "$WORK_DIR"
  TS="$(date +%Y%m%d-%H%M%S)"
  HOST="$(hostname 2>/dev/null || echo unknown-host)"
  OUTPUT_PATH="${WORK_DIR}/systeminfo-${HOST}-${TS}.txt"
else
  mkdir -p "$(dirname "$OUTPUT_PATH")"
fi

# --- Start report ---
{
  echo "Linux System Information Report"
  echo "Generated : $(date)"
  echo "Host      : $(hostname 2>/dev/null || echo unknown)"
  echo "User      : $(whoami 2>/dev/null || echo unknown)"
  echo

  echo "=================================================="
  echo "=== OS / Kernel"
  echo "=================================================="
  echo
  if command -v uname >/dev/null 2>&1; then
    echo "uname -a:"
    uname -a
    echo
  fi
  if [[ -f /etc/os-release ]]; then
    echo "/etc/os-release:"
    cat /etc/os-release
    echo
  elif command -v lsb_release >/dev/null 2>&1; then
    echo "lsb_release -a:"
    lsb_release -a || true
    echo
  fi

  echo "=================================================="
  echo "=== CPU"
  echo "=================================================="
  echo
  if command -v lscpu >/dev/null 2>&1; then
    lscpu || true
  elif [[ -f /proc/cpuinfo ]]; then
    echo "/proc/cpuinfo (first 20 lines):"
    sed -n '1,20p' /proc/cpuinfo || true
  else
    echo "No CPU info available."
  fi
  echo

  echo "=================================================="
  echo "=== Memory"
  echo "=================================================="
  echo
  if command -v free >/dev/null 2>&1; then
    free -h || true
  elif [[ -f /proc/meminfo ]]; then
    echo "/proc/meminfo (top lines):"
    head -n 20 /proc/meminfo || true
  else
    echo "No memory info available."
  fi
  echo

  echo "=================================================="
  echo "=== Disks / Filesystems"
  echo "=================================================="
  echo
  if command -v lsblk >/dev/null 2>&1; then
    echo "lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT:"
    lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT || true
    echo
  fi
  echo "df -h:"
  df -h || true
  echo

  echo "=================================================="
  echo "=== Uptime / Load"
  echo "=================================================="
  echo
  if command -v uptime >/dev/null 2>&1; then
    echo "uptime:"
    uptime || true
    echo
  fi
  if command -v who >/dev/null 2>&1; then
    echo "who -b (last boot):"
    who -b || true
    echo
  fi

  echo "=================================================="
  echo "=== Basic Network (summary)"
  echo "=================================================="
  echo
  if command -v ip >/dev/null 2>&1; then
    echo "ip -4 addr show (IPv4 only, brief):"
    ip -4 addr show || true
    echo
  fi
} > "$OUTPUT_PATH" 2>&1

echo "System information report written to:"
echo "  ${OUTPUT_PATH}"
