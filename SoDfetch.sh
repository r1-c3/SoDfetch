#!/bin/sh
# SoDfetch - replaces the distro logo with a Star of David
# Usage: sh SoDfetch.sh [--uninstall]
set -e

CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
ICONS="$DATA/icons/hicolor/scalable/apps"
ICON_NAMES="start-here start-here-kde start-here-symbolic distributor-logo distributor-logo-symbolic archlinux ubuntu-logo-icon"

if [ "$1" = "--uninstall" ]; then
  rm -f "$CFG/fastfetch/star.txt" "$CFG/neofetch/star.txt"
  for f in "$CFG/fastfetch/config.jsonc" "$CFG/neofetch/config.conf"; do
    [ -f "$f" ] && grep -q "SoDfetch" "$f" && rm -f "$f"
  done
  for n in $ICON_NAMES; do rm -f "$ICONS/$n.svg"; done
  echo "SoDfetch removed."
  exit 0
fi

ASCII='       /\       
      /  \      
-----/----\-----
 \  /      \  / 
  \/        \/  
  /\        /\  
 /  \      /  \ 
-----\----/-----
      \  /      
       \/       '

# ---------- fastfetch ----------
mkdir -p "$CFG/fastfetch"
printf '\033[34m%s\033[0m\n' "$ASCII" > "$CFG/fastfetch/star.txt"
if [ ! -f "$CFG/fastfetch/config.jsonc" ]; then
  cat > "$CFG/fastfetch/config.jsonc" <<'EOF'
// SoDfetch
{ "logo": { "type": "file-raw", "source": "~/.config/fastfetch/star.txt" } }
EOF
fi

# ---------- neofetch ----------
mkdir -p "$CFG/neofetch"
printf '%s\n' "$ASCII" > "$CFG/neofetch/star.txt"
if [ ! -f "$CFG/neofetch/config.conf" ]; then
  cat > "$CFG/neofetch/config.conf" <<'EOF'
# SoDfetch
image_backend="ascii"
image_source="$HOME/.config/neofetch/star.txt"
ascii_colors=(4)
EOF
fi

# ---------- menu / distributor icon ----------
mkdir -p "$ICONS"
cat > "$ICONS/distributor-logo.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <g fill="none" stroke="#0038b8" stroke-width="6" stroke-linejoin="round">
    <polygon points="50,7 89,74.5 11,74.5"/>
    <polygon points="50,97 11,29.5 89,29.5"/>
  </g>
</svg>
EOF
for n in $ICON_NAMES; do
  [ "$n" = "distributor-logo" ] || cp "$ICONS/distributor-logo.svg" "$ICONS/$n.svg"
done

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "$DATA/icons/hicolor" 2>/dev/null || true
fi

echo "Done. Restart fastfetch/neofetch and log out/in to refresh icons."