#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET_USER="${SUDO_USER:-${USER}}"
TARGET_HOME="${HOME}"
INSTALL_PACKAGES=0
ASSUME_YES=0
HYPRLOCK_BACKGROUND="${HYPRLOCK_BACKGROUND:-}"
HYPRLOCK_PROFILE_IMAGE="${HYPRLOCK_PROFILE_IMAGE:-}"

BACKUP_DIR=""

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --user USERNAME              Install for this user.
  --home PATH                  Install into this home directory.
  --install-packages           Install packages from deps.txt.
  --hyprlock-background PATH   Override the Hyprlock background image path.
  --hyprlock-profile PATH      Override the Hyprlock profile image path.
  --yes                        Do not prompt before overwriting existing files.
  --help                       Show this message.
EOF
}

log() {
  printf '[install] %s\n' "$*"
}

warn() {
  printf '[warn] %s\n' "$*" >&2
}

die() {
  printf '[error] %s\n' "$*" >&2
  exit 1
}

confirm() {
  local prompt="$1"

  if [[ "$ASSUME_YES" -eq 1 ]]; then
    return 0
  fi

  read -r -p "$prompt [y/N] " reply
  [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

ensure_backup_dir() {
  if [[ -z "$BACKUP_DIR" ]]; then
    BACKUP_DIR="$TARGET_HOME/.dotfiles-backups/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
  fi
}

backup_path() {
  local target="$1"
  local rel
  local backup_target

  [[ -e "$target" || -L "$target" ]] || return 0

  ensure_backup_dir
  rel="${target#/}"
  backup_target="$BACKUP_DIR/$rel"
  mkdir -p "$(dirname "$backup_target")"

  if [[ ! -e "$backup_target" && ! -L "$backup_target" ]]; then
    mv "$target" "$backup_target"
    log "Backed up $target -> $backup_target"
  fi
}

install_binary_file() {
  local source="$1"
  local target="$2"
  local mode="0644"

  if [[ -x "$source" ]]; then
    mode="0755"
  fi

  mkdir -p "$(dirname "$target")"
  backup_path "$target"
  install -m "$mode" "$source" "$target"
  log "Installed $target"
}

render_text_file() {
  local source="$1"
  local target="$2"
  local tmp
  local background_path="$HYPRLOCK_BACKGROUND"
  local profile_path="$HYPRLOCK_PROFILE_IMAGE"

  mkdir -p "$(dirname "$target")"
  backup_path "$target"

  if [[ -z "$background_path" && "$source" == "$REPO_ROOT/.config/hypr/hyprlock.conf" ]]; then
    if [[ -f "$TARGET_HOME/Pictures/lockscreen.jpg" ]]; then
      background_path="$TARGET_HOME/Pictures/lockscreen.jpg"
    else
      background_path="$TARGET_HOME/.config/wallpapers/background.jpg"
    fi
  fi

  if [[ -z "$profile_path" && "$source" == "$REPO_ROOT/.config/hypr/hyprlock.conf" ]]; then
    if [[ -f "$TARGET_HOME/Pictures/profile.jpg" ]]; then
      profile_path="$TARGET_HOME/Pictures/profile.jpg"
    elif [[ -f "$TARGET_HOME/.face" ]]; then
      profile_path="$TARGET_HOME/.face"
    elif [[ -f "$TARGET_HOME/.face.icon" ]]; then
      profile_path="$TARGET_HOME/.face.icon"
    else
      profile_path="$TARGET_HOME/.config/wallpapers/astronaut.jpg"
    fi
  fi

  tmp="$(mktemp)"

  TARGET_USER="$TARGET_USER" \
  TARGET_HOME="$TARGET_HOME" \
  HYPRLOCK_BACKGROUND="$background_path" \
  HYPRLOCK_PROFILE_IMAGE="$profile_path" \
  perl -0pe '
    s{/home/aayush}{$ENV{TARGET_HOME}}g;
    s{\baayush\b}{$ENV{TARGET_USER}}g;

    if ($ARGV eq q{'$REPO_ROOT'/.config/hypr/hyprlock.conf}) {
      s{^  path=.*lockscreen\.jpg$}{  path=$ENV{HYPRLOCK_BACKGROUND}}m;
      s{^  path=.*profile\.jpg$}{  path=$ENV{HYPRLOCK_PROFILE_IMAGE}}m;
    }
  ' "$source" >"$tmp"

  if [[ -x "$source" ]]; then
    install -m 0755 "$tmp" "$target"
  else
    install -m 0644 "$tmp" "$target"
  fi

  rm -f "$tmp"
  log "Installed $target"
}

install_repo_file() {
  local source="$1"
  local target="$2"
  local rel="${source#$REPO_ROOT/}"

  case "$rel" in
    .config/fish/fish_variables)
      warn "Skipping $rel because it contains machine-specific fish state"
      return 0
      ;;
  esac

  if grep -Iq . "$source" && grep -Eq '/home/aayush|\baayush\b' "$source"; then
    render_text_file "$source" "$target"
  else
    install_binary_file "$source" "$target"
  fi
}

install_tree() {
  local source_root="$1"
  local target_root="$2"
  local path
  local rel
  local target

  [[ -d "$source_root" ]] || die "Missing directory: $source_root"

  while IFS= read -r -d '' path; do
    rel="${path#$source_root/}"
    target="$target_root/$rel"

    if [[ -d "$path" ]]; then
      mkdir -p "$target"
      continue
    fi

    install_repo_file "$path" "$target"
  done < <(find "$source_root" -mindepth 1 -print0 | sort -z)
}

load_packages() {
  awk 'NF && $1 !~ /^#/' "$REPO_ROOT/deps.txt"
}

install_packages() {
  local helper=""
  local package

  [[ "$INSTALL_PACKAGES" -eq 1 ]] || return 0

  if command -v paru >/dev/null 2>&1; then
    helper="paru"
  elif command -v yay >/dev/null 2>&1; then
    helper="yay"
  elif command -v pacman >/dev/null 2>&1; then
    helper="pacman"
  else
    warn "Skipping package installation because no supported package manager was found"
    return 0
  fi

  log "Installing packages with $helper"

  if [[ "$helper" == "paru" || "$helper" == "yay" ]]; then
    mapfile -t packages < <(load_packages)
    "$helper" -S --needed "${packages[@]}"
    return 0
  fi

  while IFS= read -r package; do
    if ! pacman -S --needed --noconfirm "$package"; then
      warn "Package not installed with pacman: $package"
    fi
  done < <(load_packages)
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --user)
        TARGET_USER="$2"
        shift 2
        ;;
      --home)
        TARGET_HOME="$2"
        shift 2
        ;;
      --install-packages)
        INSTALL_PACKAGES=1
        shift
        ;;
      --hyprlock-background)
        HYPRLOCK_BACKGROUND="$2"
        shift 2
        ;;
      --hyprlock-profile)
        HYPRLOCK_PROFILE_IMAGE="$2"
        shift 2
        ;;
      --yes)
        ASSUME_YES=1
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done
}

normalize_target_home() {
  if [[ -n "${TARGET_HOME:-}" && "$TARGET_HOME" != "$HOME" ]]; then
    return 0
  fi

  if command -v getent >/dev/null 2>&1; then
    TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  fi

  [[ -n "$TARGET_HOME" ]] || TARGET_HOME="$HOME"
}

main() {
  require_command find
  require_command install
  require_command perl

  parse_args "$@"
  normalize_target_home

  [[ -d "$TARGET_HOME" ]] || die "Target home does not exist: $TARGET_HOME"

  log "Repo: $REPO_ROOT"
  log "Target user: $TARGET_USER"
  log "Target home: $TARGET_HOME"

  if ! confirm "Install dotfiles into $TARGET_HOME?"; then
    log "Cancelled"
    exit 0
  fi

  install_packages
  install_tree "$REPO_ROOT/.config" "$TARGET_HOME/.config"

  if [[ -f "$REPO_ROOT/.codex" ]]; then
    install_repo_file "$REPO_ROOT/.codex" "$TARGET_HOME/.codex"
  fi

  log "Finished"
  if [[ -n "$BACKUP_DIR" ]]; then
    log "Backups: $BACKUP_DIR"
  fi
}

main "$@"
