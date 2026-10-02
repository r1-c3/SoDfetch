#!/bin/sh
# SoDfetch - replaces the distro logo with a colorful Star of David
# Usage: sh SoDfetch.sh [--quiet] [--uninstall]
set -e

CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
ICONS="$DATA/icons/hicolor/scalable/apps"
ICON_NAMES="start-here start-here-kde start-here-symbolic distributor-logo distributor-logo-symbolic archlinux ubuntu-logo-icon"
START="# >>> SoDfetch >>>"
END="# <<< SoDfetch <<<"

QUIET=0
UNINSTALL=0
for a in "$@"; do
  case "$a" in
    --quiet) QUIET=1 ;;
    --uninstall) UNINSTALL=1 ;;
  esac
done

say() { if [ "$QUIET" = 0 ]; then echo "$1"; fi; }

strip_block() {
  [ -f "$1" ] || return 0
  grep -q "$START" "$1" || return 0
  sed "/$START/,/$END/d" "$1" > "$1.sodtmp"
  cat "$1.sodtmp" > "$1"
  rm -f "$1.sodtmp"
}

add_block() {
  grep -q "$START" "$1" 2>/dev/null && return 0
  {
    echo "$START"
    cat <<'EOF'
fastfetch() { command fastfetch --logo-type file-raw --logo "$HOME/.config/fastfetch/star.txt" --logo-padding-right 3 "$@"; }
neofetch() { command neofetch --source "$HOME/.config/neofetch/star.txt" --ascii_colors 4 "$@"; }
EOF
    echo "$END"
  } >> "$1"
}

gen_star() {
  awk -v C="$1" 'BEGIN {
    W = 29; H = 16; c = 14; s = 1.155
    split("21 27 33 39", U, " ")
    split("45 51 87 123", D, " ")
    for (r = 1; r <= H; r++) {
      line = ""; last = "x"
      for (x = 0; x < W; x++) {
        dx = x - c; if (dx < 0) dx = -dx
        up = (r <= 12 && dx <= s * (r - 0.5))
        dn = (r >= 5 && dx <= s * (16.5 - r))
        i = int((r - 1) / 4) + 1
        if (up && dn)  { col = 255;  ch = ((x + r) % 2) ? "▒" : "░" }
        else if (up)   { col = U[i]; ch = "█" }
        else if (dn)   { col = D[i]; ch = "█" }
        else           { col = "";   ch = " " }
        if (C == 1 && col != last) {
          line = line (col == "" ? "\033[0m" : "\033[38;5;" col "m")
          last = col
        }
        line = line ch
      }
      if (C == 1) line = line "\033[0m"
      print line
    }
  }'
}

# ---------- uninstall ----------
if [ "$UNINSTALL" = 1 ]; then
  strip_block "$HOME/.bashrc"
  strip_block "$HOME/.zshrc"
  rm -f "$CFG/fish/conf.d/sodfetch.fish"
  rm -f "$CFG/fastfetch/star.txt" "$CFG/neofetch/star.txt"
  for f in "$CFG/fastfetch/config.jsonc" "$CFG/neofetch/config.conf"; do
    if [ -f "$f" ] && grep -q "SoDfetch" "$f"; then rm -f "$f"; fi
  done
  for n in $ICON_NAMES; do rm -f "$ICONS/$n.svg"; done
  say "SoDfetch removed. Restart your terminal."
  exit 0
fi

# ---------- logos ----------
mkdir -p "$CFG/fastfetch" "$CFG/neofetch" "$ICONS"
gen_star 1 > "$CFG/fastfetch/star.txt"
gen_star 0 > "$CFG/neofetch/star.txt"

# ---------- shell integration (bash / zsh / fish) ----------
found=0
for f in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$f" ]; then add_block "$f"; found=1; fi
done
if [ "$found" = 0 ]; then
  touch "$HOME/.bashrc"
  add_block "$HOME/.bashrc"
fi
if [ -d "$CFG/fish" ] || command -v fish >/dev/null 2>&1; then
  mkdir -p "$CFG/fish/conf.d"
  cat > "$CFG/fish/conf.d/sodfetch.fish" <<'EOF'
function fastfetch
    command fastfetch --logo-type file-raw --logo $HOME/.config/fastfetch/star.txt --logo-padding-right 3 $argv
end
function neofetch
    command neofetch --source $HOME/.config/neofetch/star.txt --ascii_colors 4 $argv
end
EOF
fi

# ---------- menu / distributor icon ----------
cat > "$ICONS/distributor-logo.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <defs>
    <linearGradient id="a" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#7dd3fc"/>
      <stop offset="1" stop-color="#1d4ed8"/>
    </linearGradient>
    <linearGradient id="b" x1="0" y1="1" x2="0" y2="0">
      <stop offset="0" stop-color="#67e8f9"/>
      <stop offset="1" stop-color="#0038b8"/>
    </linearGradient>
  </defs>
<polygon points="50,6 88.1,72 11.9,72" fill="url(#a)" fill-opacity="0.85" stroke="#ffffff" stroke-width="2" stroke-linejoin="round"/>
  <polygon points="50,94 11.9,28 88.1,28" fill="url(#b)" fill-opacity="0.6" stroke="#ffffff" stroke-width="2" stroke-linejoin="round"/>
</svg>
EOF
for n in $ICON_NAMES; do
  if [ "$n" != "distributor-logo" ]; then cp "$ICONS/distributor-logo.svg" "$ICONS/$n.svg"; fi
done
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "$DATA/icons/hicolor" 2>/dev/null || true
fi

say "Done. Open a new terminal and run fastfetch. Log out/in to refresh icons."