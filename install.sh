#!/usr/bin/env bash
# Mac Dock installer.
#   Install / update:  bash install.sh            (or the curl one-liner in the README)
#   Uninstall:         bash install.sh --uninstall
set -euo pipefail

REPO_URL="https://github.com/sidneicjr28/mac-dock.git"
INSTALL_DIR="${MAC_DOCK_DIR:-$HOME/.local/share/mac-dock}"
AUTOSTART="$HOME/.config/autostart/mac-dock.desktop"
PACKAGES=(quickshell python-pywayland python-dbus python-gobject git)
GLASS_AUR="kwin-effects-glass-git"

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
info() { printf '  %s\n' "$*"; }
fail() { printf '\n\033[31mError:\033[0m %s\n' "$*" >&2; exit 1; }

# Prompts read the terminal, so they work when the script is piped from curl.
ask() {
    local reply
    [[ -r /dev/tty ]] || return 1
    read -rp "  $1 [Y/n] " reply < /dev/tty
    [[ -z $reply || $reply =~ ^[Yy] ]]
}

check_system() {
    [[ ${XDG_SESSION_TYPE:-} == wayland ]] || fail "Mac Dock needs a KDE Plasma Wayland session (current: ${XDG_SESSION_TYPE:-unknown})."
    [[ ${XDG_CURRENT_DESKTOP:-} == *KDE* ]] || fail "Mac Dock needs KDE Plasma (current desktop: ${XDG_CURRENT_DESKTOP:-unknown})."
}

install_packages() {
    bold "1/5  Installing required packages"
    if command -v pacman >/dev/null; then
        local missing=()
        for p in "${PACKAGES[@]}"; do pacman -Qq "$p" &>/dev/null || missing+=("$p"); done
        if ((${#missing[@]})); then
            info "Your password is needed to install: ${missing[*]}"
            sudo pacman -S --needed --noconfirm "${missing[@]}"
        else
            info "Everything is already installed."
        fi
    else
        info "Automatic package install is only supported on Arch-based systems."
        command -v qs >/dev/null || fail "Please install Quickshell first: https://quickshell.org/docs/guide/install-setup/"
        python3 -c "import pywayland, dbus, gi" 2>/dev/null ||
            fail "Please install the Python packages pywayland, dbus-python and PyGObject with your package manager."
        info "Required programs found."
    fi
}

fetch_dock() {
    bold "2/5  Downloading Mac Dock"
    if [[ -n $LOCAL_COPY ]]; then
        info "Using this folder: $INSTALL_DIR"
    elif [[ -d $INSTALL_DIR/.git ]]; then
        git -C "$INSTALL_DIR" pull --ff-only --quiet
        info "Updated $INSTALL_DIR"
    else
        git clone --quiet "$REPO_URL" "$INSTALL_DIR"
        info "Installed to $INSTALL_DIR"
    fi
}

# Without Glass the dock falls back to KWin's own Blur effect; the user's choice to enable it is kept.
native_blur_note() {
    if [[ $(kreadconfig6 --file kwinrc --group Plugins --key blurEnabled --default true) == true ]]; then
        info "Using KDE's built-in Blur effect instead."
    else
        info "For a blurred dock, turn on Blur in System Settings → Desktop Effects."
    fi
}

setup_blur() {
    bold "3/5  Glass blur (optional)"
    if [[ ! -e /usr/lib/qt6/plugins/kwin/effects/plugins/glass.so ]]; then
        local aur=""
        for h in yay paru; do command -v "$h" >/dev/null && aur="$h" && break; done
        if [[ -z $aur ]]; then
            info "Skipped: the Glass effect is not installed and no AUR helper (yay/paru) was found."
            native_blur_note
            return
        fi
        ask "Install the Glass blur effect ($GLASS_AUR, takes a few minutes)?" || { info "Skipped."; native_blur_note; return; }
        "$aur" -S --needed --noconfirm "$GLASS_AUR"
    fi
    # Glass replaces KWin's own Blur; the dock's blur window carries the effect (see README).
    kwriteconfig6 --file kwinrc --group Plugins --key glassEnabled true
    kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled false
    kwriteconfig6 --file kwinrc --group Effect-blurplus --key WindowClasses quickshell
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect glass >/dev/null 2>&1 || true
    qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.reconfigureEffect glass >/dev/null 2>&1 || true
    info "Glass blur enabled."
}

setup_autostart() {
    bold "4/5  Starting Mac Dock when you log in"
    mkdir -p "$(dirname "$AUTOSTART")"
    cat > "$AUTOSTART" <<EOF
[Desktop Entry]
Type=Application
Name=Mac Dock
Comment=macOS-style dock
Exec=qs -n -p $INSTALL_DIR
Icon=user-desktop
X-KDE-autostart-phase=2
EOF
    info "Created $AUTOSTART"
}

start_dock() {
    bold "5/5  Starting Mac Dock"
    qs kill -p "$INSTALL_DIR" >/dev/null 2>&1 || true
    qs -n -p "$INSTALL_DIR" -d >/dev/null 2>&1
    info "The dock is running."
}

restore_plasma_shortcuts() {
    python3 - <<'EOF' 2>/dev/null || true
import dbus
accel = dbus.Interface(dbus.SessionBus().get_object("org.kde.kglobalaccel", "/kglobalaccel"), "org.kde.KGlobalAccel")
for n in range(1, 10):
    accel.unregister("mac-dock", f"activate-{n}")
    key = dbus.Array([dbus.Struct([dbus.Array([0x10000030 + n], signature="i")], signature="ai")], signature="(ai)")
    accel.setForeignShortcutKeys(["plasmashell", f"activate task manager entry {n}", "", ""], key)
EOF
}

uninstall() {
    bold "Uninstalling Mac Dock"
    qs kill -p "$INSTALL_DIR" >/dev/null 2>&1 || true
    rm -f "$AUTOSTART"
    restore_plasma_shortcuts
    info "Stopped the dock, removed autostart and gave Super+1…9 back to Plasma."
    if [[ -z $LOCAL_COPY && -d $INSTALL_DIR ]] && ask "Delete $INSTALL_DIR (including your dock settings)?"; then
        rm -rf "$INSTALL_DIR"
        info "Deleted."
    fi
    info "Installed packages were left in place."
}

main() {
    # Run from inside a downloaded copy: use it in place instead of cloning another.
    local here
    here="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd)"
    LOCAL_COPY=""
    if [[ -f $here/shell.qml && -f $here/install.sh ]]; then LOCAL_COPY=1; INSTALL_DIR="$here"; fi

    if [[ ${1:-} == --uninstall ]]; then uninstall; exit; fi
    check_system
    install_packages
    fetch_dock
    setup_blur
    setup_autostart
    start_dock
    bold "Done! 🎉"
    info "Right-click the dock to open its settings."
    info "Super+1…9 open the first nine apps on the dock."
    info "Tip: remove or auto-hide the Plasma panel (right-click it → Show Panel Configuration)."
}

main "$@"
