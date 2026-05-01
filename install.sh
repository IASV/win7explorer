#!/usr/bin/env bash
# Win7 Explorer — install script
# Builds the project and installs it as a registered file manager.
set -euo pipefail

INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
BUILD_DIR="$(pwd)/build"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"

# ── Dependency check ──────────────────────────────────────────────────────────
check_dep() {
    command -v "$1" &>/dev/null || { echo "ERROR: '$1' not found. Install it and retry."; exit 1; }
}
check_dep cmake
check_dep ninja || true   # optional but preferred
check_dep pkg-config

# Check Qt6 is available
if ! pkg-config --exists Qt6Core 2>/dev/null && ! cmake --find-package -DNAME=Qt6 -DCOMPILER_ID=GNU -DLANGUAGE=CXX -DMODE=EXIST &>/dev/null; then
    echo "WARNING: Qt6 not detected via pkg-config. Ensure Qt6 development packages are installed."
    echo "  Fedora/RHEL: sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtquickcontrols2-devel"
    echo "  Ubuntu/Debian: sudo apt install qt6-base-dev qt6-declarative-dev"
    echo "  Arch: sudo pacman -S qt6-base qt6-declarative"
fi

# MTP support check
if ! gio mount --help &>/dev/null; then
    echo "WARNING: 'gio' not found. MTP/phone support requires gvfs."
    echo "  Fedora/RHEL: sudo dnf install gvfs gvfs-mtp"
    echo "  Ubuntu/Debian: sudo apt install gvfs gvfs-backends"
    echo "  Arch: sudo pacman -S gvfs gvfs-mtp"
else
    if ! gio mount -li 2>/dev/null | grep -q "MTP"; then
        echo "NOTE: No MTP monitor detected. For Android phone support install gvfs-mtp:"
        echo "  Fedora/RHEL: sudo dnf install gvfs-mtp"
        echo "  Ubuntu/Debian: sudo apt install gvfs-backends"
        echo "  Arch: sudo pacman -S gvfs-mtp"
    fi
fi

# ── Build ─────────────────────────────────────────────────────────────────────
echo ""
echo "==> Configuring..."
cmake -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -G "Ninja" 2>/dev/null \
    || cmake -B "$BUILD_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"

echo "==> Building..."
cmake --build "$BUILD_DIR" -j"$(nproc)"

# ── Install ───────────────────────────────────────────────────────────────────
echo "==> Installing to $INSTALL_PREFIX (may ask for sudo)..."
sudo cmake --install "$BUILD_DIR"

# Desktop file — install to system applications dir
echo "==> Installing desktop file..."
sudo install -Dm644 "$SCRIPT_DIR/win7explorer.desktop" \
    /usr/share/applications/win7explorer.desktop

# Update desktop database so the file manager shows up in app menus
if command -v update-desktop-database &>/dev/null; then
    sudo update-desktop-database /usr/share/applications/
fi

# ── Register as default file manager (user-level) ─────────────────────────────
echo "==> Registering as default file manager..."
xdg-mime default win7explorer.desktop inode/directory 2>/dev/null || \
    echo "  (xdg-mime not available — set manually in system settings)"

# On KDE, also set via kfmclient / kwriteconfig
if command -v kwriteconfig5 &>/dev/null; then
    kwriteconfig5 --file kdeglobals --group General --key BrowserApplication win7explorer.desktop
elif command -v kwriteconfig6 &>/dev/null; then
    kwriteconfig6 --file kdeglobals --group General --key BrowserApplication win7explorer.desktop
fi

# On GNOME, set via gsettings
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.default-applications.file-manager win7explorer.desktop 2>/dev/null || true
fi

echo ""
echo "✓ Win7 Explorer installed successfully!"
echo "  Binary:  $INSTALL_PREFIX/bin/win7explorer"
echo "  Desktop: /usr/share/applications/win7explorer.desktop"
echo ""
echo "Run 'win7explorer' or launch it from your application menu."
echo ""
echo "Android/MTP phone support:"
echo "  1. Connect your phone via USB"
echo "  2. On the phone: set USB mode to 'File Transfer (MTP)'"
echo "  3. Unlock the phone — it must be unlocked for MTP access"
echo "  4. The app auto-mounts it (~1 second after detection)"
echo "  Note: On KDE, the app automatically stops the kiod6 daemon to free the MTP device."
echo "        kiod6 will restart automatically when needed by other KDE apps."
