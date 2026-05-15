#!/usr/bin/env bash
# Win7 Explorer — install script
# Compiles the project and installs the resulting binary as a registered file manager.
set -euo pipefail

INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
BIN_DIR="$INSTALL_PREFIX/bin"
BUILD_DIR="$(pwd)/build"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="$BUILD_DIR/win7explorer"
INSTALLED_BIN="$BIN_DIR/win7explorer"
DESKTOP_DEST="/usr/share/applications/win7explorer.desktop"

cd "$SCRIPT_DIR"

# ── Dependency check ──────────────────────────────────────────────────────────
check_dep() {
    command -v "$1" &>/dev/null || { echo "ERROR: '$1' not found. Install it and retry."; exit 1; }
}
check_dep cmake

if ! pkg-config --exists Qt6Core 2>/dev/null; then
    echo "WARNING: Qt6 not detected. Ensure Qt6 development packages are installed:"
    echo "  Fedora/RHEL: sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtquickcontrols2-devel"
    echo "  Ubuntu/Debian: sudo apt install qt6-base-dev qt6-declarative-dev"
    echo "  Arch: sudo pacman -S qt6-base qt6-declarative"
fi

if ! command -v gio &>/dev/null; then
    echo "WARNING: 'gio' not found. MTP/phone support requires gvfs:"
    echo "  Fedora/RHEL: sudo dnf install gvfs gvfs-mtp"
    echo "  Ubuntu/Debian: sudo apt install gvfs gvfs-backends"
    echo "  Arch: sudo pacman -S gvfs gvfs-mtp"
fi

# ── Build ─────────────────────────────────────────────────────────────────────
echo ""
echo "==> Configuring..."
cmake -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -G "Ninja" 2>/dev/null \
    || cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release

echo "==> Building..."
cmake --build "$BUILD_DIR" -j"$(nproc)"

# Confirm the binary was produced
if [[ ! -f "$BINARY" ]]; then
    echo "ERROR: Build succeeded but binary not found at $BINARY"
    exit 1
fi
echo "    Built: $BINARY"

# ── Install binary ─────────────────────────────────────────────────────────────
echo "==> Installing binary to $INSTALLED_BIN ..."
sudo install -Dm755 "$BINARY" "$INSTALLED_BIN"
# Strip debug/symbol tables to shrink the installed binary (faster cold-load)
if command -v strip &>/dev/null; then
    sudo strip --strip-unneeded "$INSTALLED_BIN" 2>/dev/null || true
fi

# ── Write .desktop with the exact installed path ──────────────────────────────
echo "==> Writing desktop file to $DESKTOP_DEST ..."
sudo tee "$DESKTOP_DEST" > /dev/null <<DESKTOP
[Desktop Entry]
Name=Win7 Explorer
Name[es]=Win7 Explorador
Comment=Explorador de archivos estilo Windows 7
Comment[es]=Explorador de archivos estilo Windows 7
Exec=$INSTALLED_BIN %u
Icon=system-file-manager
Terminal=false
Type=Application
Categories=System;FileManager;Qt;
MimeType=inode/directory;application/x-gnome-saved-search;
StartupNotify=true
X-KDE-StartupNotify=true
DESKTOP

# Also keep a local copy next to the source for reference
cat > "$SCRIPT_DIR/win7explorer.desktop" <<DESKTOP
[Desktop Entry]
Name=Win7 Explorer
Name[es]=Win7 Explorador
Comment=Explorador de archivos estilo Windows 7
Comment[es]=Explorador de archivos estilo Windows 7
Exec=$INSTALLED_BIN %u
Icon=system-file-manager
Terminal=false
Type=Application
Categories=System;FileManager;Qt;
MimeType=inode/directory;application/x-gnome-saved-search;
StartupNotify=true
X-KDE-StartupNotify=true
DESKTOP

# Update desktop database
if command -v update-desktop-database &>/dev/null; then
    sudo update-desktop-database /usr/share/applications/
fi

# ── Register as default file manager ─────────────────────────────────────────
echo "==> Registering as default file manager..."

xdg-mime default win7explorer.desktop inode/directory 2>/dev/null || true

if command -v kwriteconfig6 &>/dev/null; then
    kwriteconfig6 --file kdeglobals --group General --key BrowserApplication win7explorer.desktop
elif command -v kwriteconfig5 &>/dev/null; then
    kwriteconfig5 --file kdeglobals --group General --key BrowserApplication win7explorer.desktop
fi

if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.default-applications.file-manager win7explorer.desktop 2>/dev/null || true
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "✓ Win7 Explorer installed successfully!"
echo "  Binary:  $INSTALLED_BIN"
echo "  Desktop: $DESKTOP_DEST"
echo "  Exec:    $INSTALLED_BIN %u"
echo ""
echo "Run 'win7explorer' or launch it from your application menu."
echo ""
echo "Android/MTP phone support:"
echo "  1. Connect your phone via USB"
echo "  2. On the phone: set USB mode to 'File Transfer (MTP)'"
echo "  3. Unlock the phone — it must be unlocked for MTP access"
echo "  4. The app auto-mounts it (~1-2 seconds after detection)"
echo "  Note: On KDE, the app stops the kiod6 daemon briefly to free the MTP device."
echo "        kiod6 restarts automatically when needed by other KDE apps."
