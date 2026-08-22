#!/usr/bin/env bash
#
# Big Sur Glow - remove o tema no Linux
#
# Le ~/.config/bigsur-theme/backup.env e devolve as configuracoes que estavam
# ali antes do install.sh rodar.
#
# Autor: MarbleCeo

set -euo pipefail

STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bigsur-theme"
BACKUP="$STATE_DIR/backup.env"
KEEP_BACKUP=0

c_step() { printf '  \033[36m->\033[0m %s\n' "$1"; }
c_ok()   { printf '  \033[32mOK\033[0m %s\n' "$1"; }
c_warn() { printf '  \033[33m! \033[0m %s\n' "$1"; }

while [ $# -gt 0 ]; do
    case "$1" in
        --keep) KEEP_BACKUP=1 ;;
        -h|--help)
            echo "Uso: ./uninstall.sh [--keep]"
            echo "  --keep   nao apaga o arquivo de backup depois de restaurar"
            exit 0
            ;;
        *) echo "opcao desconhecida: $1" >&2; exit 1 ;;
    esac
    shift
done

printf '\n  \033[35mBig Sur Glow - removendo o tema\033[0m\n\n'

if [ ! -f "$BACKUP" ]; then
    c_warn "nenhum backup em $BACKUP"
    c_warn "nada a restaurar - o tema provavelmente nunca foi aplicado nesta conta"
    echo
    exit 0
fi

# shellcheck source=/dev/null
source "$BACKUP"

DE="${BIGSUR_DE:-desconhecido}"
c_step "restaurando o ambiente $DE"

# Remove as aspas que o gsettings devolve nos valores.
unquote() { sed "s/^'//; s/'$//" <<<"$1"; }

case "$DE" in
    gnome|cinnamon|mate|desconhecido)
        schema="${BIGSUR_SCHEMA:-org.gnome.desktop.background}"

        if [ -n "${BIGSUR_WALLPAPER:-}" ] && [ "$BIGSUR_WALLPAPER" != "''" ]; then
            gsettings set "$schema" picture-uri "$(unquote "$BIGSUR_WALLPAPER")" 2>/dev/null || true
            c_ok "papel de parede restaurado"
        fi
        if [ -n "${BIGSUR_WALLPAPER_DARK:-}" ] && [ "$BIGSUR_WALLPAPER_DARK" != "''" ]; then
            gsettings set "$schema" picture-uri-dark "$(unquote "$BIGSUR_WALLPAPER_DARK")" 2>/dev/null || true
        fi
        if [ -n "${BIGSUR_GTK_THEME:-}" ] && [ "$BIGSUR_GTK_THEME" != "''" ]; then
            gsettings set org.gnome.desktop.interface gtk-theme "$(unquote "$BIGSUR_GTK_THEME")" 2>/dev/null || true
            c_ok "tema GTK restaurado"
        fi
        if [ -n "${BIGSUR_COLOR_SCHEME:-}" ] && [ "$BIGSUR_COLOR_SCHEME" != "''" ]; then
            gsettings set org.gnome.desktop.interface color-scheme "$(unquote "$BIGSUR_COLOR_SCHEME")" 2>/dev/null || true
            c_ok "modo claro/escuro restaurado"
        fi
        ;;
    xfce)
        if [ -n "${BIGSUR_GTK_THEME:-}" ]; then
            xfconf-query -c xsettings -p /Net/ThemeName -s "$BIGSUR_GTK_THEME" 2>/dev/null || true
            c_ok "tema GTK restaurado"
        fi
        c_warn "no XFCE o papel de parede anterior precisa ser escolhido pela interface"
        ;;
    kde)
        c_warn "no KDE use Configuracoes do Sistema > Papel de parede para voltar ao anterior"
        ;;
esac

[ "$KEEP_BACKUP" -eq 0 ] && rm -f "$BACKUP"

printf '\n  \033[32mTema removido.\033[0m\n\n'
