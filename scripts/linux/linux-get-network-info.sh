#!/usr/bin/env bash
#
# linux-get-network-info.sh
#
# Collects network-related information into a text report.
# Default output: $HOME/jb/networkinfo-HOST-YYYYMMDD-HHMMSS.txt
#
# Repo: https://github.com/JBOrunon/toolbox

set -u
set -o pipefail

WORK_DIR="${HOME}/jb"
OUTPUT_PATH=""
TEST_TARGETS=("1.1.1.1" "8.8.8.8" "github.com")

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dir PATH] [--output FILE] [--targets host1,host2,...]

Options:
  -d, --dir PATH          Working directory (default: \$HOME/jb)
  -o, --output FILE       Explicit output file path
  -t, --targets LIST      Comma-separated list of connectivity test targets
  -h, --help              Show this help message and exit

Examples:
  # Default: writes under ~/jb
  $(basename "$0")

  # Custom targets
  $(basename "$0") --targets "8.8.8.8,1.1.1.1,github.com"

  # Explicit output file
  $(basename "$0") --output /tmp/networkinfo.txt
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
    -t|--targets)
      IFS=',' read -r -a TEST_TARGETS <<< "$2"
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
  OUTPUT_PATH="${WORK_DIR}/networkinfo-${HOST}-${TS}.txt"
else
  mkdir -p "$(dirname "$OUTPUT_PATH")"
fi

# --- Helper: safe ping ---
do_ping() {
  local target="$1"
  if command -v ping >/dev/null 2>&1; then
    echo "Ping to ${target}:"
    ping -c 3 -W 2 "$target" || echo "  (Ping failed or blocked)"
  else
    echo "ping command not found; skipping ping to ${target}."
  fi
  echo
}

# --- Start report ---
{
  echo "Linux Network Information Report"
  echo "Generated : $(date)"
  echo "Host      : $(hostname 2>/dev/null || echo unknown)"
  echo "User      : $(whoami 2>/dev/null || echo unknown)"
  echo

  echo "=================================================="
  echo "=== Interfaces / Addresses"
  echo "=================================================="
  echo
  if command -v ip >/dev/null 2>&1; then
    echo "ip addr show:"
    ip addr show || true
    echo
  elif command -v ifconfig >/dev/null 2>&1; then
    echo "ifconfig -a:"
    ifconfig -a || true
    echo
  else
    echo "No ip or ifconfig command available."
    echo
  fi

  echo "=================================================="
  echo "=== Routing Table"
  echo "=================================================="
  echo
  if command -v ip >/dev/null 2>&1; then
    echo "ip route:"
    ip route || true
    echo
  elif command -v netstat >/dev/null 2>&1; then
    echo "netstat -rn:"
    netstat -rn || true
    echo
  else
    echo "No ip or netstat command available."
    echo
  fi

  echo "=================================================="
  echo "=== DNS Configuration"
  echo "=================================================="
  echo
  if [[ -f /etc/resolv.conf ]]; then
    echo "/etc/resolv.conf:"
    cat /etc/resolv.conf || true
    echo
  else
    echo "/etc/resolv.conf not found."
    echo
  fi

  echo "=================================================="
  echo "=== Hosts File"
  echo "=================================================="
  echo
  if [[ -f /etc/hosts ]]; then
    echo "/etc/hosts:"
    cat /etc/hosts || true
    echo
  else
    echo "/etc/hosts not found."
    echo
  fi

  echo "=================================================="
  echo "=== Listening Sockets"
  echo "=================================================="
  echo
  if command -v ss >/dev/null 2>&1; then
    echo "ss -tulnp (requires sufficient permissions):"
    ss -tulnp || true
    echo
  elif command -v netstat >/dev/null 2>&1; then
    echo "netstat -tulnp (requires sufficient permissions):"
    netstat -tulnp || true
    echo
  else
    echo "No ss or netstat command available."
    echo
  fi

  echo "=================================================="
  echo "=== Connectivity Tests"
  echo "=================================================="
  echo
  for target in "${TEST_TARGETS[@]}"; do
    do_ping "$target"
  done
} > "$OUTPUT_PATH" 2>&1

echo "Network information report written to:"
echo "  ${OUTPUT_PATH}"
