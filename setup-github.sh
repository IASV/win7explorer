#!/bin/bash
# ═══════════════════════════════════════════════════
# setup-github.sh
# Crea un repositorio privado en GitHub y sube el proyecto
# ═══════════════════════════════════════════════════

set -e

REPO_NAME="win7explorer"
DESCRIPTION="Réplica del Explorador de Windows 7 para Linux (Qt6 QML + C++)"

echo "═══════════════════════════════════════════════"
echo "  Win7Explorer - Configuración de GitHub"
echo "═══════════════════════════════════════════════"
echo ""

# Verificar que gh (GitHub CLI) esté instalado
if ! command -v gh &> /dev/null; then
    echo "⚠  GitHub CLI (gh) no está instalado."
    echo ""
    echo "Instálalo con:"
    echo "  Fedora:  sudo dnf install gh"
    echo "  Arch:    sudo pacman -S github-cli"
    echo ""
    echo "Después ejecuta:  gh auth login"
    exit 1
fi

# Verificar autenticación
if ! gh auth status &> /dev/null 2>&1; then
    echo "⚠  No estás autenticado en GitHub CLI."
    echo "Ejecuta:  gh auth login"
    exit 1
fi

GITHUB_USER=$(gh api user --jq '.login')
echo "✓ Autenticado como: $GITHUB_USER"
echo ""

# Verificar si el repo ya existe
if gh repo view "$GITHUB_USER/$REPO_NAME" &> /dev/null 2>&1; then
    echo "⚠  El repositorio $GITHUB_USER/$REPO_NAME ya existe."
    read -p "¿Quieres hacer push de todas formas? (s/N): " CONFIRM
    if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]]; then
        echo "Cancelado."
        exit 0
    fi
else
    # Crear repositorio privado
    echo "→ Creando repositorio privado: $GITHUB_USER/$REPO_NAME"
    gh repo create "$REPO_NAME" --private --description "$DESCRIPTION"
    echo "✓ Repositorio creado"
fi

echo ""

# Inicializar git si no está inicializado
if [ ! -d ".git" ]; then
    echo "→ Inicializando repositorio git local..."
    git init
    git branch -M main
fi

# Configurar remote
REMOTE_URL="https://github.com/$GITHUB_USER/$REPO_NAME.git"
if git remote get-url origin &> /dev/null 2>&1; then
    git remote set-url origin "$REMOTE_URL"
else
    git remote add origin "$REMOTE_URL"
fi

# Agregar archivos y hacer commit
echo "→ Preparando commit inicial..."
git add -A
git commit -m "feat: Fase 1 - Layout visual del Explorador de Windows 7

- Estructura del proyecto Qt6 QML + C++
- Backend C++ para operaciones del sistema de archivos
- Barra de navegación con botones Aero (Atrás/Adelante/Arriba)
- Barra de direcciones con breadcrumbs navegables
- Barra de comandos contextual
- Panel de navegación (Favoritos, Bibliotecas, Equipo, Red)
- Área de contenido con vista de iconos y vista de detalles
- Panel de detalles del archivo seleccionado
- Barra de estado con contador de elementos
- Tema visual Win7 Aero (colores, gradientes, fuentes)
- Iconos SVG base
- README con instrucciones de compilación" 2>/dev/null || echo "(commit ya existe o sin cambios)"

# Push
echo "→ Subiendo a GitHub..."
git push -u origin main

echo ""
echo "═══════════════════════════════════════════════"
echo "  ✓ ¡Listo!"
echo ""
echo "  Repositorio: https://github.com/$GITHUB_USER/$REPO_NAME"
echo "  (Privado)"
echo ""
echo "  Para compilar:"
echo "    mkdir build && cd build"
echo "    cmake .."
echo "    make -j\$(nproc)"
echo "    ./win7explorer"
echo "═══════════════════════════════════════════════"
