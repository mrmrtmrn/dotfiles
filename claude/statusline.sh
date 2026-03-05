#!/bin/bash
input=$(cat)

# --- Colors ---
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
DIM='\033[2m'
RESET='\033[0m'

# --- Helpers ---
make_bar() {
  local pct=$1 width=${2:-20}
  local filled=$((pct * width / 100))
  local empty=$((width - filled))
  [ "$filled" -lt 0 ] && filled=0
  [ "$empty" -lt 0 ] && empty=0
  local bar=""
  [ "$filled" -gt 0 ] && bar=$(printf "%${filled}s" | tr ' ' '▪')
  [ "$empty" -gt 0 ] && bar="${bar}$(printf "%${empty}s" | tr ' ' '·')"
  echo "$bar"
}

color_for_pct() {
  local pct=$1
  if [ "$pct" -ge 90 ]; then echo "$RED"
  elif [ "$pct" -ge 70 ]; then echo "$YELLOW"
  else echo "$GREEN"
  fi
}

# ==============================
# Line 1: Session info
# ==============================
MODEL=$(echo "$input" | jq -r '.model.display_name // "unknown"')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir // "."')

CTX_BAR=$(make_bar "$PCT")
CTX_COLOR=$(color_for_pct "$PCT")

LINE1="${MODEL} | ${CTX_COLOR}${CTX_BAR}${RESET} ${PCT}%"

if [ "$ADDED" -gt 0 ] || [ "$REMOVED" -gt 0 ]; then
  LINE1="${LINE1} | ${GREEN}+${ADDED}${RESET}/${RED}-${REMOVED}${RESET}"
fi

BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)
if [ -n "$BRANCH" ]; then
  LINE1="${LINE1} | ${CYAN}${BRANCH}${RESET}"
fi

echo -e "$LINE1"

# ==============================
# Lines 2-3: Rate limit (cached)
# ==============================
CACHE_FILE="/tmp/claude-statusline-usage.json"
CACHE_TTL=360

fetch_usage() {
  local token
  token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
  [ -z "$token" ] && return 1

  local access_token
  access_token=$(echo "$token" | jq -r '.claudeAiOauth.accessToken // empty')
  [ -z "$access_token" ] && return 1

  local resp
  resp=$(curl -s --max-time 5 \
    -H "Authorization: Bearer $access_token" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "Accept: application/json" \
    https://api.anthropic.com/api/oauth/usage 2>/dev/null)

  # Check for errors
  if echo "$resp" | jq -e '.error' >/dev/null 2>&1; then
    return 1
  fi

  echo "$resp" > "$CACHE_FILE"
  return 0
}

# Use cache if fresh, otherwise fetch in background
need_fetch=false
if [ -f "$CACHE_FILE" ]; then
  cache_age=$(( $(date +%s) - $(stat -f%m "$CACHE_FILE" 2>/dev/null || echo 0) ))
  if [ "$cache_age" -ge "$CACHE_TTL" ]; then
    need_fetch=true
  fi
else
  need_fetch=true
fi

if [ "$need_fetch" = true ]; then
  # Fetch in background to avoid blocking statusline
  ( fetch_usage ) &
fi

# Display from cache if available
if [ -f "$CACHE_FILE" ]; then
  USAGE=$(cat "$CACHE_FILE")

  # 5-hour rate limit (utilization is already a percentage, e.g. 28.0 = 28%)
  FIVE_UTIL=$(echo "$USAGE" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
  FIVE_RESET=$(echo "$USAGE" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)

  # 7-day rate limit
  SEVEN_UTIL=$(echo "$USAGE" | jq -r '.seven_day.utilization // empty' 2>/dev/null)
  SEVEN_RESET=$(echo "$USAGE" | jq -r '.seven_day.resets_at // empty' 2>/dev/null)

  format_reset_time() {
    local iso_time=$1 fmt=$2
    # Strip fractional seconds, convert +HH:MM to +HHMM for macOS date
    local cleaned
    cleaned=$(echo "$iso_time" | sed 's/\.[0-9]*//' | sed 's/\([+-][0-9][0-9]\):\([0-9][0-9]\)$/\1\2/')
    local epoch
    epoch=$(date -jf "%Y-%m-%dT%H:%M:%S%z" "$cleaned" "+%s" 2>/dev/null)
    if [ -n "$epoch" ]; then
      TZ=Asia/Tokyo date -r "$epoch" "+$fmt" 2>/dev/null
    else
      echo ""
    fi
  }

  if [ -n "$FIVE_UTIL" ]; then
    FIVE_PCT=$(printf "%.0f" "$FIVE_UTIL" 2>/dev/null)
    [ -z "$FIVE_PCT" ] && FIVE_PCT=0
    FIVE_BAR=$(make_bar "$FIVE_PCT")
    FIVE_COLOR=$(color_for_pct "$FIVE_PCT")

    FIVE_RESET_FMT=""
    if [ -n "$FIVE_RESET" ]; then
      FIVE_RESET_FMT=$(format_reset_time "$FIVE_RESET" "%-I%p")
      [ -n "$FIVE_RESET_FMT" ] && FIVE_RESET_FMT="Resets ${FIVE_RESET_FMT} (Asia/Tokyo)"
    fi

    echo -e "⏱ 5h  ${FIVE_COLOR}${FIVE_BAR}${RESET} ${FIVE_PCT}%  ${FIVE_RESET_FMT}"
  fi

  if [ -n "$SEVEN_UTIL" ]; then
    SEVEN_PCT=$(printf "%.0f" "$SEVEN_UTIL" 2>/dev/null)
    [ -z "$SEVEN_PCT" ] && SEVEN_PCT=0
    SEVEN_BAR=$(make_bar "$SEVEN_PCT")
    SEVEN_COLOR=$(color_for_pct "$SEVEN_PCT")

    SEVEN_RESET_FMT=""
    if [ -n "$SEVEN_RESET" ]; then
      SEVEN_RESET_FMT=$(format_reset_time "$SEVEN_RESET" "%b %-d at %-I%p")
      [ -n "$SEVEN_RESET_FMT" ] && SEVEN_RESET_FMT="Resets ${SEVEN_RESET_FMT} (Asia/Tokyo)"
    fi

    echo -e "📅 7d  ${SEVEN_COLOR}${SEVEN_BAR}${RESET} ${SEVEN_PCT}%  ${SEVEN_RESET_FMT}"
  fi
fi
