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

LINE1="🤖 ${MODEL} | ${CTX_COLOR}${CTX_BAR}${RESET} ${PCT}%"

if [ "$ADDED" -gt 0 ] || [ "$REMOVED" -gt 0 ]; then
  LINE1="${LINE1} | ${GREEN}+${ADDED}${RESET}/${RED}-${REMOVED}${RESET}"
fi

echo -e "$LINE1"

DIR_NAME=$(basename "$PROJECT_DIR")
LINE2="📁 ${DIR_NAME}"

BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)
if [ -n "$BRANCH" ]; then
  LINE2="${LINE2} | 🌿 ${CYAN}${BRANCH}${RESET}"
fi

echo -e "$LINE2"

# ==============================
# Lines 2-3: Rate limit (from stdin JSON)
# ==============================
FIVE_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
FIVE_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null)

if [ -n "$FIVE_PCT" ]; then
  FIVE_BAR=$(make_bar "$FIVE_PCT")
  FIVE_COLOR=$(color_for_pct "$FIVE_PCT")

  FIVE_RESET_FMT=""
  if [ -n "$FIVE_RESET" ]; then
    FIVE_RESET_FMT=$(TZ=Asia/Tokyo date -r "$FIVE_RESET" "+%-I%p" 2>/dev/null)
    [ -n "$FIVE_RESET_FMT" ] && FIVE_RESET_FMT="Resets ${FIVE_RESET_FMT} (Asia/Tokyo)"
  fi

  echo -e "🕐 5h  ${FIVE_COLOR}${FIVE_BAR}${RESET} ${FIVE_PCT}%  ${FIVE_RESET_FMT}"
fi

SEVEN_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null)
SEVEN_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty' 2>/dev/null)

if [ -n "$SEVEN_PCT" ]; then
  SEVEN_BAR=$(make_bar "$SEVEN_PCT")
  SEVEN_COLOR=$(color_for_pct "$SEVEN_PCT")

  SEVEN_RESET_FMT=""
  if [ -n "$SEVEN_RESET" ]; then
    SEVEN_RESET_FMT=$(TZ=Asia/Tokyo date -r "$SEVEN_RESET" "+%b %-d at %-I%p" 2>/dev/null)
    [ -n "$SEVEN_RESET_FMT" ] && SEVEN_RESET_FMT="Resets ${SEVEN_RESET_FMT} (Asia/Tokyo)"
  fi

  echo -e "📅 7d  ${SEVEN_COLOR}${SEVEN_BAR}${RESET} ${SEVEN_PCT}%  ${SEVEN_RESET_FMT}"
fi
