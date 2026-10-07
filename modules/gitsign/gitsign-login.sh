#!/usr/bin/env bash
# gitsign-login.sh
#
# Runs gitsign-credential-cache in this terminal and signals when it waits for
# a login: it rings the terminal bell and opens the login URL through the
# $BROWSER helper that VS Code sets in its terminals.
#
# Overrides:
#   GITSIGN_CACHE_BIN      path to gitsign-credential-cache
#   GITSIGN_OPEN_BROWSER   0 = do not open the login URL (default 1)
#   GITSIGN_BELL_REPEAT    seconds between bells while waiting, 0 = ring once (default 3)
DAEMON="${GITSIGN_CACHE_BIN:-$(command -v gitsign-credential-cache || echo "$HOME/.local/bin/gitsign-credential-cache")}"
OPEN="${GITSIGN_OPEN_BROWSER:-1}"
REPEAT="${GITSIGN_BELL_REPEAT:-3}"
MAX_BELLS=20

notify() {  # $1 = login URL
  printf '\a'
  if [ "$OPEN" = 1 ] && [ -n "${BROWSER:-}" ]; then
    "$BROWSER" "$1" >/dev/null 2>&1 &
  fi
}

# The daemon keeps the terminal as stdin, so it can still read the code.
"$DAEMON" 2>&1 | {
  buf="" waiting=0 ticks=0 bells=0
  while :; do
    chunk=""
    IFS= read -r -t 0.2 -N 1024 chunk; rc=$?
    if [ -n "$chunk" ]; then
      printf '%s' "$chunk"
      buf+="$chunk"; waiting=0
      if [[ $buf =~ (https://[^[:space:]]+)[[:space:]]+Enter\ verification\ code: ]] ||
         [[ $buf =~ in\ your\ browser\ at:\ (https://[^[:space:]]+)[[:space:]] ]]; then
        notify "${BASH_REMATCH[1]}"
        buf="" waiting=1 ticks=0 bells=1
      fi
      (( ${#buf} > 8192 )) && buf="${buf: -8192}"
    elif (( waiting && REPEAT > 0 && bells < MAX_BELLS )); then
      (( ++ticks >= REPEAT * 5 )) && { printf '\a'; ticks=0; bells=$((bells + 1)); }
    fi
    # 0 = full chunk, >128 = timeout: keep reading. Anything else is end of input.
    (( rc == 0 || rc > 128 )) || break
  done
}
