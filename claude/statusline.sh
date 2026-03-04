#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "unknown"')
USED=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
LIMIT=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Format token counts (e.g., 130000 -> 130k)
format_tokens() {
  local n=$1
  if [ "$n" -ge 1000 ]; then
    echo "$((n / 1000))k"
  else
    echo "$n"
  fi
}

USED_FMT=$(format_tokens "$USED")
LIMIT_FMT=$(format_tokens "$LIMIT")

# Build progress bar (width=20)
BAR_WIDTH=20
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
[ "$FILLED" -lt 0 ] && FILLED=0
[ "$EMPTY" -lt 0 ] && EMPTY=0

BAR=""
[ "$FILLED" -gt 0 ] && BAR=$(printf "%${FILLED}s" | tr ' ' '█')
[ "$EMPTY" -gt 0 ] && BAR="${BAR}$(printf "%${EMPTY}s" | tr ' ' '░')"

# Color based on usage
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
RESET='\033[0m'

if [ "$PCT" -ge 90 ]; then
  COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then
  COLOR="$YELLOW"
else
  COLOR="$GREEN"
fi

echo -e "${MODEL}  ${COLOR}${BAR}${RESET} ${PCT}%  ${USED_FMT}/${LIMIT_FMT}"
