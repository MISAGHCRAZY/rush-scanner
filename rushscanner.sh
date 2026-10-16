#!/usr/bin/env bash
set -u
umask 077

VERSION="0.1.0"

# Set this to: your-github-username/your-repository
GITHUB_REPO="MISAGHCRAZY/rush-scanner"
BRANCH="main"
SCRIPT_NAME="rush-scanner.sh"
UPDATE_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/${BRANCH}/${SCRIPT_NAME}"

APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/rush-scanner"
STATE_DIR="$APP_DIR/state"
SCRIPT_PATH="$APP_DIR/$SCRIPT_NAME"

mkdir -p "$STATE_DIR"

print_header() {
  clear 2>/dev/null || true
  printf '\033[38;5;141m'
  cat <<'EOF'
██████╗  ██╗   ██╗ ██████╗ ██╗  ██╗
██╔══██╗ ██║   ██║ ██╔═══╝ ██║  ██║
██████╔╝ ██║   ██║ ███████╗███████║
██╔══██╗ ██║   ██║ ╚════██║██╔══██║
██║  ██║ ╚██████╔╝ ███████║██║  ██║
╚═╝  ╚═╝  ╚═════╝  ╚══════╝╚═╝  ╚═╝

 ██████╗  ██████╗  █████╗  ███╗   ██╗ ███╗   ██╗ ███████╗ ██████╗
██╔════╝ ██╔════╝ ██╔══██╗ ████╗  ██║ ████╗  ██║ ██╔════╝ ██╔══██╗
███████╗ ██║      ███████║ ██╔██╗ ██║ ██╔██╗ ██║ █████╗   ██████╔╝
╚════██║ ██║      ██╔══██║ ██║╚██╗██║ ██║╚██╗██║ ██╔══╝   ██╔══██╗
███████║ ╚██████╗ ██║  ██║ ██║ ╚████║ ██║ ╚████║ ███████╗ ██║  ██║
╚══════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═╝  ╚═══╝ ╚═╝  ╚═══╝ ╚══════╝ ╚═╝  ╚═╝
EOF
  printf '\033[0m\n'
}

random_hex() {
  od -An -N "$1" -tx1 /dev/urandom 2>/dev/null | tr -d ' \n'
}

ensure_panel_state() {
  [[ -s "$STATE_DIR/token" ]] || random_hex 24 > "$STATE_DIR/token"
  [[ -s "$STATE_DIR/port" ]] || printf '%s' "$((20000 + RANDOM % 40000))" > "$STATE_DIR/port"
  [[ -s "$STATE_DIR/path" ]] || printf '/%s' "$(random_hex 8)" > "$STATE_DIR/path"

  chmod 600 "$STATE_DIR/token" "$STATE_DIR/port" "$STATE_DIR/path"
}

back_prompt() {
  echo
  echo "0) Back"

  while true; do
    read -r -p ".enter your choise(0 is back): " choice
    if [[ "$choice" == "0" ]]; then
      return
    fi
    echo "Invalid choice."
  done
}

show_version() {
  print_header
  echo "RUSH SCANNER version: $VERSION"
  back_prompt
}

check_update() {
  print_header
  echo "Checking for updates..."

  if [[ "$GITHUB_REPO" == "YOUR_GITHUB_USER/YOUR_REPO" ]]; then
    echo "Set GITHUB_REPO in the script before using update."
    back_prompt
    return
  fi

  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required for updates."
    back_prompt
    return
  fi

  local tmp remote_version newest
  tmp="$(mktemp "$APP_DIR/.update.XXXXXX")" || {
    echo "Could not create a temporary update file."
    back_prompt
    return
  }

  if ! curl -fsSL --connect-timeout 10 --max-time 60 "$UPDATE_URL" -o "$tmp"; then
    rm -f "$tmp"
    echo "Could not download the latest version."
    back_prompt
    return
  fi

  if ! grep -q '^#!/usr/bin/env bash' "$tmp"; then
    rm -f "$tmp"
    echo "Downloaded file is not a valid RUSH SCANNER script."
    back_prompt
    return
  fi

  remote_version="$(grep -m1 '^VERSION=' "$tmp" | cut -d '"' -f2)"

  if [[ ! "$remote_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    rm -f "$tmp"
    echo "Could not read a valid version number from GitHub."
    back_prompt
    return
  fi

  if [[ "$remote_version" == "$VERSION" ]]; then
    rm -f "$tmp"
    echo "RUSH SCANNER is up to date"
    back_prompt
    return
  fi

  newest="$(printf '%s\n%s\n' "$VERSION" "$remote_version" | sort -V | tail -n1)"

  if [[ "$newest" != "$remote_version" ]]; then
    rm -f "$tmp"
    echo "Installed version is newer than the GitHub version."
    back_prompt
    return
  fi

  chmod 700 "$tmp"
  mv -f "$tmp" "$SCRIPT_PATH"
  echo "Updated to version $remote_version. Restarting..."
  exec "$SCRIPT_PATH"
}

show_panel_menu() {
  ensure_panel_state

  local server_ip port panel_path token
  server_ip="${RUSH_SERVER_IP:-$(hostname -I 2>/dev/null | awk '{print $1}')}"
  [[ -n "$server_ip" ]] || server_ip="127.0.0.1"

  while true; do
    print_header
    port="$(cat "$STATE_DIR/port")"
    panel_path="$(cat "$STATE_DIR/path")"
    token="$(cat "$STATE_DIR/token")"

    echo "Address: http://${server_ip}:${port}${panel_path}"
    echo "Token:   ${token}"
    echo
    echo "Panel status: Not installed yet"
    echo
    echo "1) Change token"
    echo "0) Back"

    read -r -p ".enter your choise(0 is back): " choice
    case "$choice" in
      1)
        random_hex 24 > "$STATE_DIR/token"
        chmod 600 "$STATE_DIR/token"
        echo
        echo "New token: $(cat "$STATE_DIR/token")"
        read -r -p "Press Enter to continue..."
        ;;
      0)
        return
        ;;
      *)
        echo "Invalid choice."
        sleep 1
        ;;
    esac
  done
}

uninstall() {
  print_header
  rm -rf -- "$APP_DIR"
  echo "goodbye"
  exit 0
}

while true; do
  print_header
  echo "1) Version"
  echo "2) Update"
  echo "3) Web panel"
  echo "4) Uninstall"
  echo "0) Exit"
  echo

  read -r -p ".enter your choise: " choice
  case "$choice" in
    1) show_version ;;
    2) check_update ;;
    3) show_panel_menu ;;
    4) uninstall ;;
    0) exit 0 ;;
    *) echo "Invalid choice."; sleep 1 ;;
  esac
done