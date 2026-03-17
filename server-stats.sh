#!/bin/bash
#
# server-stats.sh - Analyse basic server performance stats on Linux
# Usage: ./server-stats.sh
#

set -e

# Colors for output (optional; disable if not a TTY)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  RED= GREEN= YELLOW= BLUE= BOLD= NC=
fi

section() {
  echo ""
  echo -e "${BOLD}${BLUE}═══ $1 ${NC}"
  echo ""
}

# --- Required: Total CPU usage ---
# Samples /proc/stat twice to compute usage over 1 second
cpu_usage() {
  section "Total CPU usage"
  if [ ! -r /proc/stat ]; then
    echo "Cannot read /proc/stat (not Linux?). Skipping CPU."
    return
  fi
  read -r _ user1 nice1 system1 idle1 iowait1 irq1 softirq1 steal1 _ _ < /proc/stat
  total1=$((user1 + nice1 + system1 + idle1 + iowait1 + irq1 + softirq1 + steal1))
  sleep 1
  read -r _ user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 _ _ < /proc/stat
  total2=$((user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2 + steal2))
  idle2=$idle2
  total_diff=$((total2 - total1))
  idle_diff=$((idle2 - idle1))
  if [ "$total_diff" -gt 0 ]; then
    used=$((total_diff - idle_diff))
    pct=$((100 * used / total_diff))
    echo -e "  CPU usage: ${GREEN}${pct}%${NC}"
  else
    echo "  CPU usage: N/A (could not sample)"
  fi
}

# --- Required: Memory (Free vs Used with percentage) ---
memory_usage() {
  section "Total memory usage"
  if [ ! -r /proc/meminfo ]; then
    echo "Cannot read /proc/meminfo. Skipping memory."
    return
  fi
  total_kb=$(awk '/^MemTotal:/ { print $2 }' /proc/meminfo)
  avail_kb=$(awk '/^MemAvailable:/ { print $2 }' /proc/meminfo)
  if [ -z "$avail_kb" ]; then
    avail_kb=$(awk '/^MemFree:/ { print $2 }' /proc/meminfo)
  fi
  used_kb=$((total_kb - avail_kb))
  total_mb=$((total_kb / 1024))
  used_mb=$((used_kb / 1024))
  free_mb=$((avail_kb / 1024))
  if [ "$total_kb" -gt 0 ]; then
    pct=$((100 * used_kb / total_kb))
    echo -e "  Total: ${total_mb} MB  |  Used: ${GREEN}${used_mb} MB${NC}  |  Free: ${free_mb} MB  |  Used: ${GREEN}${pct}%${NC}"
  else
    echo "  Could not read memory info."
  fi
}

# --- Required: Disk (Free vs Used with percentage) ---
disk_usage() {
  section "Total disk usage"
  if ! command -v df &>/dev/null; then
    echo "df not found. Skipping disk."
    return
  fi
  df -h / 2>/dev/null | tail -n 1 | awk '{
    total=$2; used=$3; avail=$4; pct=$5
    sub(/%/,"",pct)
    printf "  Root (/): Total %s  Used %s  Free %s  Usage %s\n", total, used, avail, pct"%"
  }'
}

# --- Required: Top 5 processes by CPU ---
top5_cpu() {
  section "Top 5 processes by CPU usage"
  if [ ! -r /proc/stat ]; then
    echo "Not Linux. Skipping."
    return
  fi
  if command -v ps &>/dev/null; then
    echo "  %CPU  PID  COMMAND"
    ps -eo pcpu,pid,comm --sort=-pcpu 2>/dev/null | head -6 | tail -5 | while read -r line; do
      echo "  $line"
    done
  else
    echo "  ps not found."
  fi
}

# --- Required: Top 5 processes by memory ---
top5_mem() {
  section "Top 5 processes by memory usage"
  if [ ! -r /proc/meminfo ]; then
    echo "Not Linux. Skipping."
    return
  fi
  if command -v ps &>/dev/null; then
    echo "  %MEM  PID  COMMAND"
    ps -eo pmem,pid,comm --sort=-pmem 2>/dev/null | head -6 | tail -5 | while read -r line; do
      echo "  $line"
    done
  else
    echo "  ps not found."
  fi
}

# --- Stretch: OS version ---
os_version() {
  section "OS version"
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    echo -e "  ${PRETTY_NAME:-$NAME $VERSION}"
  else
    echo "  $(uname -s) $(uname -r)"
  fi
}

# --- Stretch: Uptime & load average ---
uptime_load() {
  section "Uptime & load average"
  if [ -r /proc/uptime ]; then
    read -r up _ < /proc/uptime
    days=$((up / 86400))
    hrs=$(( (up % 86400) / 3600 ))
    min=$(( (up % 3600) / 60 ))
    echo -e "  Uptime: ${days}d ${hrs}h ${min}m"
  fi
  if [ -r /proc/loadavg ]; then
    read -r one five fifteen _ < /proc/loadavg
    echo -e "  Load average: 1m ${one}, 5m ${five}, 15m ${fifteen}"
  fi
}

# --- Stretch: Logged-in users ---
logged_in_users() {
  section "Logged-in users"
  if command -v who &>/dev/null; then
    who
  else
    echo "  who not found."
  fi
}

# --- Stretch: Failed login attempts ---
failed_logins() {
  section "Failed login attempts (recent)"
  for log in /var/log/auth.log /var/log/secure; do
    if [ -r "$log" ]; then
      count=$(grep -c "Failed password\|authentication failure\|FAILED LOGIN" "$log" 2>/dev/null) || count=0
      echo "  $log: $count failed attempts"
      # Show last 5 lines if any
      grep "Failed password\|authentication failure\|FAILED LOGIN" "$log" 2>/dev/null | tail -5 | sed 's/^/    /'
      return
    fi
  done
  if command -v lastb &>/dev/null; then
    echo "  Last bad logins (lastb):"
    lastb 2>/dev/null | head -6 | sed 's/^/    /'
  else
    echo "  No readable auth log or lastb; run as root for full access."
  fi
}

# --- Main ---
main() {
  echo -e "${BOLD}Server performance stats — $(date)${NC}"
  cpu_usage
  memory_usage
  disk_usage
  top5_cpu
  top5_mem
  os_version
  uptime_load
  logged_in_users
  failed_logins
  echo ""
}

main "$@"
