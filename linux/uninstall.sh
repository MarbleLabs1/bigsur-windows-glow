#!/usr/bin/env bash
#
# Big Sur Glow - remocao
#
# Devolve o que o install.sh mudou, lendo o estado gravado em
# ~/.config/bigsur-theme/backup.env, e apaga os temas montados em ~/.themes.
#
# Autor: MarbleCeo

set -euo pipefail

STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bigsur-theme"
BACKUP="$STATE_DIR/backup.env"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
THEME_DIR="$HOME/.themes"

c_step() { printf '  \033[36m->\033[0m %s\n' "$1"; }
c_ok()   { printf '  \033[32mOK\033[0m %s\n' "$1"; }
c_warn() { printf '  \033[33m! \033[0m %s\n' "$1"; }

printf '\n  \033[35mBig Sur Glow - removendo\033[0m\n\n'

# Sem backup ainda da para limpar o que instalamos; so nao da para restaurar.
if [ ! -f "$BACKUP" ]; then
    c_warn "nenhum backup em $BACKUP - vou apenas remover os arquivos do tema"
    DE=""
else
    # shellcheck disable=SC1090
    . "$BACKUP"
    DE="${BIGSUR_DE:-}"
fi

# ------------------------------------------------------- restaurar ajustes -- #

unquote() { local s="$1"; s="${s%\'}"; s="${s#\'}"; echo "$s"; }

if [ -n "$DE" ]; then
    c_step "restaurando configuracoes de $DE"
    case "$DE" in
        gnome|cinnamon|mate|desconhecido)
            [ -n "${BIGSUR_GTK_THEME:-}" ] && \
                gsettings set org.gnome.desktop.interface gtk-theme "$(unquote "$BIGSUR_GTK_THEME")" 2>/dev/null || true
            [ -n "${BIGSUR_COLOR_SCHEME:-}" ] && \
                gsettings set org.gnome.desktop.interface color-scheme "$(unquote "$BIGSUR_COLOR_SCHEME")" 2>/dev/null || true
            [ -n "${BIGSUR_BUTTON_LAYOUT:-}" ] && \
                gsettings set org.gnome.desktop.wm.preferences button-layout "$(unquote "$BIGSUR_BUTTON_LAYOUT")" 2>/dev/null || true
            if [ -n "${BIGSUR_SCHEMA:-}" ] && [ -n "${BIGSUR_WALLPAPER:-}" ]; then
                gsettings set "$BIGSUR_SCHEMA" picture-uri "$(unquote "$BIGSUR_WALLPAPER")" 2>/dev/null || true
                [ -n "${BIGSUR_WALLPAPER_DARK:-}" ] && \
                    gsettings set "$BIGSUR_SCHEMA" picture-uri-dark "$(unquote "$BIGSUR_WALLPAPER_DARK")" 2>/dev/null || true
            fi
            ;;
        xfce)
            [ -n "${BIGSUR_GTK_THEME:-}" ] && \
                xfconf-query -c xsettings -p /Net/ThemeName -s "$(unquote "$BIGSUR_GTK_THEME")" 2>/dev/null || true
            [ -n "${BIGSUR_BUTTON_LAYOUT:-}" ] && \
                xfconf-query -c xfwm4 -p /general/button_layout -s "$(unquote "$BIGSUR_BUTTON_LAYOUT")" 2>/dev/null || true
            ;;
        kde)
            [ -n "${BIGSUR_GTK_THEME:-}" ] && \
                gsettings set org.gnome.desktop.interface gtk-theme "$(unquote "$BIGSUR_GTK_THEME")" 2>/dev/null || true
            c_warn "no KDE, o papel de parede volta pelo historico do Plasma"
            ;;
    esac
    c_ok "configuracoes restauradas"
fi

# ------------------------------------------------------------ folha GTK 4 --- #

c_step "removendo a folha GTK 4"
if [ "${BIGSUR_GTK4_USER_CSS:-0}" = "1" ] && [ -f "$STATE_DIR/gtk4-user.css.bak" ]; then
    mkdir -p "$CONFIG_DIR/gtk-4.0"
    mv "$STATE_DIR/gtk4-user.css.bak" "$CONFIG_DIR/gtk-4.0/gtk.css"
    c_ok "seu gtk.css anterior foi devolvido"
elif [ -f "$CONFIG_DIR/gtk-4.0/gtk.css" ] && grep -q "Big Sur Glow" "$CONFIG_DIR/gtk-4.0/gtk.css" 2>/dev/null; then
    rm -f "$CONFIG_DIR/gtk-4.0/gtk.css"
    c_ok "$CONFIG_DIR/gtk-4.0/gtk.css removido"
else
    c_warn "nada a remover em $CONFIG_DIR/gtk-4.0/gtk.css"
fi

# ------------------------------------------------------- temas em ~/.themes - #

c_step "removendo os temas montados"
removed=0
for name in BigSur-Glow-Light BigSur-Glow-Dark; do
    if [ -d "$THEME_DIR/$name" ]; then
        rm -rf "$THEME_DIR/$name"
        c_ok "$THEME_DIR/$name"
        removed=1
    fi
done
[ "$removed" -eq 0 ] && c_warn "nenhum tema encontrado em $THEME_DIR"
rm -f "$HOME/.gtkrc-2.0.bigsur"

# ------------------------------------------------------------- estado ------- #

if [ -f "$BACKUP" ]; then
    rm -f "$BACKUP"
    c_ok "backup consumido e apagado"
fi
rmdir "$STATE_DIR" 2>/dev/null || true

printf '\n  \033[32mRemovido.\033[0m\n'
printf '  \033[90mApps ja abertos precisam ser reiniciados para voltar ao normal.\033[0m\n\n'
