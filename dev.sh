#!/usr/bin/env bash
# Win7 Explorer — development menu
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APPDIR="$SCRIPT_DIR/AppDir"
BINARY="$BUILD_DIR/win7explorer"
LINUXDEPLOY="$HOME/linuxdeploy-x86_64.AppImage"
LINUXDEPLOY_QT="$HOME/linuxdeploy-plugin-qt-x86_64.AppImage"
APPIMAGETOOL="$HOME/appimagetool-x86_64.AppImage"

cd "$SCRIPT_DIR"

# ── Colors ────────────────────────────────────────────────────────────────────
C_TITLE='\033[1;36m'; C_OPT='\033[1;33m'; C_OK='\033[0;32m'
C_ERR='\033[0;31m'; C_RST='\033[0m'

print_menu() {
    clear
    echo -e "${C_TITLE}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║        Win7 Explorer — Dev Menu      ║"
    echo "  ╚══════════════════════════════════════╝${C_RST}"
    echo ""
    echo -e "  ${C_OPT}1)${C_RST} Compilar (Debug)"
    echo -e "  ${C_OPT}2)${C_RST} Compilar (Release)"
    echo -e "  ${C_OPT}3)${C_RST} Ejecutar"
    echo -e "  ${C_OPT}4)${C_RST} Compilar y ejecutar"
    echo -e "  ${C_OPT}5)${C_RST} Instalar en el sistema"
    echo -e "  ${C_OPT}6)${C_RST} Generar AppImage (Release)"
    echo -e "  ${C_OPT}7)${C_RST} Limpiar build"
    echo -e "  ${C_OPT}8)${C_RST} Limpiar build + AppDir"
    echo -e "  ${C_OPT}0)${C_RST} Salir"
    echo ""
    echo -n "  Opción: "
}

build() {
    local TYPE="$1"
    echo -e "\n${C_OK}==> Configurando ($TYPE)...${C_RST}"
    cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$TYPE" -DCMAKE_INSTALL_PREFIX=/usr \
        -G Ninja 2>/dev/null || cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$TYPE" -DCMAKE_INSTALL_PREFIX=/usr
    echo -e "${C_OK}==> Compilando...${C_RST}"
    cmake --build "$BUILD_DIR" -j"$(nproc)"
    echo -e "${C_OK}✓ Compilado: $BINARY${C_RST}"
}

run() {
    if [[ ! -f "$BINARY" ]]; then
        echo -e "${C_ERR}No hay binario. Compila primero.${C_RST}"; return
    fi
    "$BINARY"
}

install_system() {
    bash "$SCRIPT_DIR/install.sh"
}

generate_appimage() {
    if [[ ! -f "$LINUXDEPLOY" ]]; then
        echo -e "${C_ERR}No se encontró linuxdeploy en $LINUXDEPLOY${C_RST}"
        echo "  Descárgalo con:"
        echo "  wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage -O $LINUXDEPLOY"
        echo "  chmod +x $LINUXDEPLOY"
        return
    fi
    if [[ ! -f "$LINUXDEPLOY_QT" ]]; then
        echo -e "${C_ERR}No se encontró linuxdeploy-plugin-qt en $LINUXDEPLOY_QT${C_RST}"
        echo "  Descárgalo con:"
        echo "  wget https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage -O $LINUXDEPLOY_QT"
        echo "  chmod +x $LINUXDEPLOY_QT"
        return
    fi

    # Descargar appimagetool si no existe
    if [[ ! -f "$APPIMAGETOOL" ]]; then
        echo -e "${C_OK}==> Descargando appimagetool...${C_RST}"
        wget -q --show-progress "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" -O "$APPIMAGETOOL"
        chmod +x "$APPIMAGETOOL"
    fi

    echo -e "\n${C_OK}==> Compilando Release para AppImage...${C_RST}"
    cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
        -G Ninja 2>/dev/null || cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
    cmake --build "$BUILD_DIR" -j"$(nproc)"

    echo -e "${C_OK}==> Instalando en AppDir...${C_RST}"
    rm -rf "$APPDIR"
    DESTDIR="$APPDIR" cmake --install "$BUILD_DIR"

    echo -e "${C_OK}==> Creando .desktop e icono...${C_RST}"
    mkdir -p "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"
    cp "$SCRIPT_DIR/icons/folder-closed.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/win7explorer.png"
    cat > "$APPDIR/usr/share/applications/win7explorer.desktop" <<DESKTOP
[Desktop Entry]
Name=Win7 Explorer
Exec=win7explorer
Icon=win7explorer
Type=Application
Categories=System;FileManager;
DESKTOP

    export QML_SOURCES_PATHS="$SCRIPT_DIR/qml"
    export NO_STRIP=1
    export QMAKE
    QMAKE="$(command -v qmake6 2>/dev/null || command -v qmake-qt6 2>/dev/null || command -v qmake 2>/dev/null)"

    echo -e "${C_OK}==> Desplegando dependencias Qt...${C_RST}"
    "$LINUXDEPLOY" \
        --appdir "$APPDIR" \
        --plugin qt \
        "--desktop-file=$APPDIR/usr/share/applications/win7explorer.desktop" \
        "--icon-file=$APPDIR/usr/share/icons/hicolor/256x256/apps/win7explorer.png"

    # Fedora 43 compila TODAS las libs con .relr.dyn — crashean en _dl_init dentro del AppImage.
    # Eliminamos todos los .so del bundle; el AppImage sigue siendo útil por sus plugins Qt.
    echo -e "${C_OK}==> Eliminando libs bundleadas (Fedora 43 requiere las del sistema)...${C_RST}"
    rm -f "$APPDIR"/usr/lib/*.so*

    echo -e "${C_OK}==> Empaquetando con appimagetool...${C_RST}"
    OUTPUT="$SCRIPT_DIR/Win7_Explorer-x86_64.AppImage"
    rm -f "$OUTPUT"
    "$APPIMAGETOOL" "$APPDIR" "$OUTPUT"

    if [[ -f "$OUTPUT" ]]; then
        echo -e "${C_OK}✓ AppImage generado: $OUTPUT${C_RST}"
    else
        echo -e "${C_ERR}Error: no se generó el AppImage${C_RST}"
    fi
}

clean_build() {
    echo -e "\n${C_OK}==> Limpiando build...${C_RST}"
    rm -rf "$BUILD_DIR"
    echo -e "${C_OK}✓ Listo${C_RST}"
}

clean_all() {
    echo -e "\n${C_OK}==> Limpiando build y AppDir...${C_RST}"
    rm -rf "$BUILD_DIR" "$APPDIR"
    rm -f "$SCRIPT_DIR"/Win7_Explorer*.AppImage
    echo -e "${C_OK}✓ Listo${C_RST}"
}

# ── Main loop ─────────────────────────────────────────────────────────────────
while true; do
    print_menu
    read -r OPT
    case "$OPT" in
        1) build Debug     ; read -rp $'\nEnter para continuar...' ;;
        2) build Release   ; read -rp $'\nEnter para continuar...' ;;
        3) run             ;;
        4) build Debug && run ;;
        5) install_system  ; read -rp $'\nEnter para continuar...' ;;
        6) generate_appimage ; read -rp $'\nEnter para continuar...' ;;
        7) clean_build     ; read -rp $'\nEnter para continuar...' ;;
        8) clean_all       ; read -rp $'\nEnter para continuar...' ;;
        0) echo ""; exit 0 ;;
        *) echo -e "${C_ERR}Opción no válida${C_RST}"; sleep 1 ;;
    esac
done
