#!/usr/bin/env bash
#
# Big Sur Glow - tema para Linux
#
# Aplica a variante clara ou escura no ambiente de trabalho do usuario atual.
# Nao precisa de root e nao toca em nada fora do seu $HOME. Tudo o que e
# alterado e salvo antes em ~/.config/bigsur-theme/backup.env, e o
# uninstall.sh devolve como estava.
#
# Ambientes suportados: GNOME, Cinnamon, MATE, XFCE, KDE Plasma.
#
# Autor: MarbleCeo

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bigsur-theme"
BACKUP="$STATE_DIR/backup.env"

VARIANT="light"
SET_WALLPAPER=1

# ------------------------------------------------------------------ saida --- #

c_step()  { printf '  \033[36m->\033[0m %s\n' "$1"; }
c_ok()    { printf '  \033[32mOK\033[0m %s\n' "$1"; }
c_warn()  { printf '  \033[33m! \033[0m %s\n' "$1"; }
c_die()   { printf '  \033[31mERRO\033[0m %s\n' "$1" >&2; exit 1; }

usage() {
    cat <<'EOF'
Uso: ./install.sh [opcoes]

  --dark           aplica a variante escura (padrao: clara)
  --light          aplica a variante clara
  --no-wallpaper   mantem o papel de parede atual
  -h, --help       mostra esta ajuda

Exemplos:
  ./install.sh
  ./install.sh --dark
  ./install.sh --dark --no-wallpaper
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dark)         VARIANT="dark" ;;
        --light)        VARIANT="light" ;;
        --no-wallpaper) SET_WALLPAPER=0 ;;
        -h|--help)      usage; exit 0 ;;
        *)              c_die "opcao desconhecida: $1 (use --help)" ;;
    esac
    shift
done

# ----------------------------------------------------------- ambiente ------- #

detect_de() {
    local de="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"
    case "${de,,}" in
        *gnome*)    echo "gnome" ;;
        *cinnamon*) echo "cinnamon" ;;
        *mate*)     echo "mate" ;;
        *xfce*)     echo "xfce" ;;
        *kde*|*plasma*) echo "kde" ;;
        *)          echo "desconhecido" ;;
    esac
}

DE="$(detect_de)"

printf '\n  \033[35mBig Sur Glow - tema para Linux\033[0m\n'
printf '  \033[90mvariante: %s | ambiente: %s\033[0m\n\n' "$VARIANT" "$DE"

[ "$DE" = "desconhecido" ] && c_warn "ambiente nao reconhecido; vou tentar o caminho do GNOME"

WALLPAPER="$REPO_ROOT/assets/wallpaper-$VARIANT.png"
[ -f "$WALLPAPER" ] || c_die "papel de parede nao encontrado: $WALLPAPER"

# ------------------------------------------------------------- backup ------- #

mkdir -p "$STATE_DIR"

save_backup() {
    if [ -f "$BACKUP" ]; then
        c_warn "backup anterior mantido em $BACKUP"
        return
    fi
    c_step "salvando suas configuracoes atuais"
    {
        echo "# Big Sur Glow - estado anterior, gravado em $(date -Is)"
        echo "BIGSUR_DE='$DE'"
        case "$DE" in
            gnome|cinnamon|mate)
                local schema="org.gnome.desktop.background"
                [ "$DE" = "cinnamon" ] && schema="org.cinnamon.desktop.background"
                [ "$DE" = "mate" ] && schema="org.mate.background"
                echo "BIGSUR_SCHEMA='$schema'"
                echo "BIGSUR_WALLPAPER=$(gsettings get "$schema" picture-uri 2>/dev/null || echo "''")"
                echo "BIGSUR_WALLPAPER_DARK=$(gsettings get "$schema" picture-uri-dark 2>/dev/null || echo "''")"
                echo "BIGSUR_GTK_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "''")"
                echo "BIGSUR_COLOR_SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "''")"
                ;;
            xfce)
                echo "BIGSUR_GTK_THEME='$(xfconf-query -c xsettings -p /Net/ThemeName 2>/dev/null || true)'"
                ;;
            kde)
                echo "# KDE: o Plasma guarda o proprio historico de papel de parede"
                ;;
        esac
    } > "$BACKUP"
    c_ok "backup em $BACKUP"
}

save_backup

# --------------------------------------------------------- papel de parede -- #

apply_wallpaper() {
    local uri="file://$WALLPAPER"
    case "$DE" in
        gnome)
            gsettings set org.gnome.desktop.background picture-uri "$uri"
            gsettings set org.gnome.desktop.background picture-uri-dark "$uri"
            gsettings set org.gnome.desktop.background picture-options 'zoom'
            ;;
        cinnamon)
            gsettings set org.cinnamon.desktop.background picture-uri "$uri"
            gsettings set org.cinnamon.desktop.background picture-options 'zoom'
            ;;
        mate)
            gsettings set org.mate.background picture-filename "$WALLPAPER"
            gsettings set org.mate.background picture-options 'zoom'
            ;;
        xfce)
            # aplica em todos os monitores e areas de trabalho
            xfconf-query -c xfce4-desktop -l 2>/dev/null \
                | grep -E 'last-image$' \
                | while read -r prop; do
                    xfconf-query -c xfce4-desktop -p "$prop" -s "$WALLPAPER"
                  done
            ;;
        kde)
            if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
                plasma-apply-wallpaperimage "$WALLPAPER"
            else
                c_warn "plasma-apply-wallpaperimage nao encontrado; defina o papel de parede pela interface"
                return
            fi
            ;;
        *)
            gsettings set org.gnome.desktop.background picture-uri "$uri" 2>/dev/null \
                || { c_warn "nao consegui aplicar o papel de parede neste ambiente"; return; }
            ;;
    esac
    c_ok "papel de parede: $(basename "$WALLPAPER")"
}

if [ "$SET_WALLPAPER" -eq 1 ]; then
    c_step "aplicando papel de parede"
    apply_wallpaper
fi

# ------------------------------------------------------------- claro/escuro - #

apply_color_scheme() {
    local pref="prefer-light"
    [ "$VARIANT" = "dark" ] && pref="prefer-dark"
    case "$DE" in
        gnome|cinnamon|mate|desconhecido)
            gsettings set org.gnome.desktop.interface color-scheme "$pref" 2>/dev/null || true
            ;;
        kde)
            if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
                local scheme="BreezeLight"
                [ "$VARIANT" = "dark" ] && scheme="BreezeDark"
                plasma-apply-colorscheme "$scheme" >/dev/null 2>&1 || true
            fi
            ;;
    esac
    c_ok "modo $VARIANT"
}

c_step "aplicando modo $VARIANT"
apply_color_scheme

# ----------------------------------------------------------- tema GTK ------- #

find_whitesur() {
    local suffix="Light"
    [ "$VARIANT" = "dark" ] && suffix="Dark"
    local dir
    for dir in "$HOME/.themes" "$HOME/.local/share/themes" /usr/share/themes; do
        [ -d "$dir" ] || continue
        local hit
        hit="$(find "$dir" -maxdepth 1 -type d -name "WhiteSur-$suffix*" -printf '%f\n' 2>/dev/null | head -n1)"
        [ -n "$hit" ] && { echo "$hit"; return 0; }
    done
    return 1
}

c_step "procurando o tema GTK WhiteSur"
if theme="$(find_whitesur)"; then
    case "$DE" in
        xfce) xfconf-query -c xsettings -p /Net/ThemeName -s "$theme" ;;
        *)    gsettings set org.gnome.desktop.interface gtk-theme "$theme" 2>/dev/null || true ;;
    esac
    c_ok "tema GTK: $theme"
else
    c_warn "WhiteSur nao esta instalado - as cores foram aplicadas, mas sem os widgets do macOS"
    c_warn "instale o pacote completo com: https://github.com/MarbleCeo/macos-theme-for-linux"
fi

printf '\n  \033[32mTema aplicado.\033[0m\n'
printf '  \033[90mPara voltar ao que era antes:  ./uninstall.sh\033[0m\n\n'
