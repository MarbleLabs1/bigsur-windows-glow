#!/usr/bin/env bash
#
# Big Sur Glow - tema para Linux
#
# Monta e aplica o tema GTK 3 e GTK 4 na conta do usuario atual. Nao precisa
# de root e nao toca em nada fora do seu $HOME. Tudo o que e alterado fica
# salvo antes em ~/.config/bigsur-theme/backup.env, e o uninstall.sh devolve
# como estava.
#
# O tema e montado na hora: as cores da variante escolhida sao concatenadas
# com a folha de widgets, de modo que claro e escuro compartilham uma unica
# regra de estilo. Fonte das cores: shared/palette.json.
#
# Ambientes suportados: GNOME, Cinnamon, MATE, XFCE, KDE Plasma.
#
# Autor: MarbleCeo

set -euo pipefail

# Sob `curl ... | bash` o script chega pela entrada padrao: BASH_SOURCE fica
# vazio e, com set -u, isso aborta. O :- cobre esse caso; a busca da arvore
# vem logo abaixo.
SELF="${BASH_SOURCE[0]:-${0:-}}"
if [ -n "$SELF" ] && [ -f "$SELF" ]; then
    REPO_ROOT="$(cd "$(dirname "$SELF")/.." && pwd)"
else
    REPO_ROOT=""
fi

TARBALL="https://codeload.github.com/MarbleLabs1/bigsur-windows-glow/tar.gz/refs/heads/main"
BOOTSTRAP_DIR=""

STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bigsur-theme"
BACKUP="$STATE_DIR/backup.env"
THEME_DIR="$HOME/.themes"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

VARIANT="light"
SET_WALLPAPER=1
SET_GTK4=1
BUTTONS_LEFT=1

# ------------------------------------------------------------------ saida --- #

c_step()  { printf '  \033[36m->\033[0m %s\n' "$1"; }
c_ok()    { printf '  \033[32mOK\033[0m %s\n' "$1"; }
c_warn()  { printf '  \033[33m! \033[0m %s\n' "$1"; }
c_die()   { printf '  \033[31mERRO\033[0m %s\n' "$1" >&2; exit 1; }

# gsettings pode nao existir (sistema minimo, DE sem glib) ou recusar a chave.
# Sem este envelope, o set -e derruba a instalacao no meio e deixa o tema
# meio aplicado -- pior que nao aplicar.
APPLIED=0   # quantos ajustes de area de trabalho realmente pegaram

gset() {
    command -v gsettings >/dev/null 2>&1 || { c_warn "gsettings ausente; pulei: $*"; return 0; }
    if gsettings "$@" 2>/dev/null; then APPLIED=$((APPLIED + 1)); else c_warn "gsettings recusou: $*"; fi
    return 0
}
xfconf() {
    command -v xfconf-query >/dev/null 2>&1 || { c_warn "xfconf-query ausente; pulei"; return 0; }
    if xfconf-query "$@" 2>/dev/null; then APPLIED=$((APPLIED + 1)); else c_warn "xfconf-query recusou: $*"; fi
    return 0
}

usage() {
    cat <<'EOF'
Uso: ./install.sh [opcoes]

  --dark           aplica a variante escura (padrao: clara)
  --light          aplica a variante clara
  --no-wallpaper   mantem o papel de parede atual
  --no-gtk4        nao mexe em ~/.config/gtk-4.0 (deixa apps libadwaita
                   com a aparencia padrao)
  --buttons-right  mantem os botoes da janela a direita, no lugar do
                   semaforo a esquerda
  -h, --help       mostra esta ajuda

Exemplos:
  ./install.sh
  ./install.sh --dark
  ./install.sh --dark --no-wallpaper
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dark)          VARIANT="dark" ;;
        --light)         VARIANT="light" ;;
        --no-wallpaper)  SET_WALLPAPER=0 ;;
        --no-gtk4)       SET_GTK4=0 ;;
        --buttons-right) BUTTONS_LEFT=0 ;;
        -h|--help)       usage; exit 0 ;;
        *)               c_die "opcao desconhecida: $1 (use --help)" ;;
    esac
    shift
done

case "$VARIANT" in
    light) THEME_NAME="BigSur-Glow-Light" ;;
    dark)  THEME_NAME="BigSur-Glow-Dark" ;;
esac

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

# ------------------------------------------------------- arvore do tema ----- #
#
# O tema nao cabe num script: sao seis arquivos em gtk/ mais os papeis de
# parede. Quando o install.sh roda dentro do repositorio clonado, eles estao
# ao lado. Quando roda via `curl | bash`, nao ha arvore nenhuma -- entao ele
# baixa o tarball do proprio repositorio e trabalha de la.

need_tree() { [ -z "$REPO_ROOT" ] || [ ! -f "$REPO_ROOT/gtk/colors-light.css" ]; }

fetch_tree() {
    local dl
    if command -v curl >/dev/null 2>&1; then dl="curl -fsSL"
    elif command -v wget >/dev/null 2>&1; then dl="wget -qO-"
    else c_die "preciso de curl ou wget para baixar o tema"; fi
    command -v tar >/dev/null 2>&1 || c_die "preciso de tar para extrair o tema"

    c_step "sem arvore local; baixando o tema do GitHub"
    BOOTSTRAP_DIR="$(mktemp -d)"
    trap 'rm -rf "$BOOTSTRAP_DIR"' EXIT

    # Baixa para arquivo antes de extrair: assim um 404 vira uma mensagem
    # nossa em vez de um despejo de erro do gzip e do tar.
    local tgz="$BOOTSTRAP_DIR/tema.tar.gz"
    if ! $dl "$TARBALL" > "$tgz" 2>/dev/null || [ ! -s "$tgz" ]; then
        c_die "nao consegui baixar o tema. Se o repositorio for privado, clone com git em vez de usar curl."
    fi
    if ! tar xzf "$tgz" -C "$BOOTSTRAP_DIR" --strip-components=1 2>/dev/null; then
        c_die "o arquivo baixado nao e um tarball valido"
    fi
    rm -f "$tgz"
    REPO_ROOT="$BOOTSTRAP_DIR"
    [ -f "$REPO_ROOT/gtk/colors-light.css" ] || c_die "o tarball nao trouxe gtk/ - repositorio errado?"
    c_ok "tema baixado"
}

need_tree && fetch_tree

COLORS="$REPO_ROOT/gtk/colors-$VARIANT.css"
GTK3_SRC="$REPO_ROOT/gtk/widgets-gtk3.css"
GTK4_SRC="$REPO_ROOT/gtk/widgets-gtk4.css"
WALLPAPER="$REPO_ROOT/assets/wallpaper-$VARIANT.png"

GTK2_SRC="$REPO_ROOT/gtk/gtk2-$VARIANT.rc"

for f in "$COLORS" "$GTK3_SRC" "$GTK4_SRC" "$GTK2_SRC"; do
    [ -f "$f" ] || c_die "arquivo do tema nao encontrado: $f"
done
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
                echo "BIGSUR_BUTTON_LAYOUT=$(gsettings get org.gnome.desktop.wm.preferences button-layout 2>/dev/null || echo "''")"
                ;;
            xfce)
                echo "BIGSUR_GTK_THEME='$(xfconf-query -c xsettings -p /Net/ThemeName 2>/dev/null || true)'"
                echo "BIGSUR_BUTTON_LAYOUT='$(xfconf-query -c xfwm4 -p /general/button_layout 2>/dev/null || true)'"
                ;;
            kde)
                echo "# KDE: o Plasma guarda o proprio historico de papel de parede"
                echo "BIGSUR_GTK_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "''")"
                ;;
        esac
        # o gtk.css do usuario e sobrescrito pelo tema GTK 4; guardar o antigo
        if [ -f "$CONFIG_DIR/gtk-4.0/gtk.css" ]; then
            cp "$CONFIG_DIR/gtk-4.0/gtk.css" "$STATE_DIR/gtk4-user.css.bak"
            echo "BIGSUR_GTK4_USER_CSS='1'"
        else
            echo "BIGSUR_GTK4_USER_CSS='0'"
        fi
    } > "$BACKUP"
    c_ok "backup em $BACKUP"
}

save_backup

# --------------------------------------------------------- montar o tema ---- #
#
# O gtk.css final e a concatenacao de dois arquivos: o bloco @define-color da
# variante e a folha de widgets. Nenhum passo de build, nenhuma duplicacao.

build_theme() {
    local dest="$THEME_DIR/$THEME_NAME"

    rm -rf "$dest"
    mkdir -p "$dest/gtk-3.0" "$dest/gtk-4.0"

    {
        printf '/* Big Sur Glow (%s) - gerado por linux/install.sh em %s.\n' "$VARIANT" "$(date -Is)"
        printf '   Nao edite este arquivo: edite gtk/colors-%s.css ou gtk/widgets-gtk3.css. */\n\n' "$VARIANT"
        cat "$COLORS"
        printf '\n'
        cat "$GTK3_SRC"
    } > "$dest/gtk-3.0/gtk.css"

    {
        printf '/* Big Sur Glow (%s) - gerado por linux/install.sh em %s. */\n\n' "$VARIANT" "$(date -Is)"
        cat "$COLORS"
        printf '\n'
        cat "$GTK4_SRC"
    } > "$dest/gtk-4.0/gtk.css"

    # o GTK 3 procura gtk-dark.css quando o app pede a variante escura
    [ "$VARIANT" = "dark" ] && cp "$dest/gtk-3.0/gtk.css" "$dest/gtk-3.0/gtk-dark.css"

    # GTK 2 e outra linguagem: rc por estados, sem @define-color. Sem isto,
    # GIMP e Inkscape ficam com o tema padrao no meio do resto.
    mkdir -p "$dest/gtk-2.0"
    cp "$REPO_ROOT/gtk/gtk2-$VARIANT.rc" "$dest/gtk-2.0/gtkrc"

    local buttons="close,minimize,maximize:"
    [ "$BUTTONS_LEFT" -eq 0 ] && buttons=":minimize,maximize,close"

    cat > "$dest/index.theme" <<THEME
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=$THEME_NAME
Comment=Big Sur Glow - variante $VARIANT
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=$THEME_NAME
ButtonLayout=$buttons
THEME

    c_ok "tema montado em $dest"
}

c_step "montando o tema GTK"
build_theme

# ------------------------------------------------------ aplicar o tema ------ #

apply_gtk_theme() {
    case "$DE" in
        xfce)
            xfconf -c xsettings -p /Net/ThemeName -s "$THEME_NAME"
            ;;
        *)
            gset set org.gnome.desktop.interface gtk-theme "$THEME_NAME" 2>/dev/null || \
                c_warn "nao consegui setar gtk-theme via gsettings"
            ;;
    esac
    c_ok "tema GTK 3: $THEME_NAME"
}

c_step "aplicando o tema"
apply_gtk_theme

# O libadwaita ignora ~/.themes por completo: a unica porta de entrada e o
# gtk.css do usuario. Por isso copiamos a folha para la.
if [ "$SET_GTK4" -eq 1 ]; then
    c_step "aplicando a folha GTK 4 (libadwaita)"
    mkdir -p "$CONFIG_DIR/gtk-4.0"
    cp "$THEME_DIR/$THEME_NAME/gtk-4.0/gtk.css" "$CONFIG_DIR/gtk-4.0/gtk.css"
    c_ok "$CONFIG_DIR/gtk-4.0/gtk.css"
    c_warn "apps GTK 4 ja abertos precisam ser reiniciados"
fi

# --------------------------------------------------------- semaforo --------- #

if [ "$BUTTONS_LEFT" -eq 1 ]; then
    c_step "movendo os botoes da janela para a esquerda"
    case "$DE" in
        gnome|cinnamon|mate|desconhecido)
            gset set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
            ;;
        xfce)
            xfconf -c xfwm4 -p /general/button_layout -s "CMH|"
            ;;
        kde)
            c_warn "no KDE, mova os botoes em Configuracoes > Decoracao de Janelas"
            ;;
    esac
    c_ok "semaforo a esquerda"
fi

# --------------------------------------------------------- papel de parede -- #

apply_wallpaper() {
    local uri="file://$WALLPAPER"
    case "$DE" in
        gnome)
            gset set org.gnome.desktop.background picture-uri "$uri"
            gset set org.gnome.desktop.background picture-uri-dark "$uri"
            gset set org.gnome.desktop.background picture-options 'zoom'
            ;;
        cinnamon)
            gset set org.cinnamon.desktop.background picture-uri "$uri"
            gset set org.cinnamon.desktop.background picture-options 'zoom'
            ;;
        mate)
            gset set org.mate.background picture-filename "$WALLPAPER"
            gset set org.mate.background picture-options 'zoom'
            ;;
        xfce)
            xfconf -c xfce4-desktop -l 2>/dev/null \
                | grep -E 'last-image$' \
                | while read -r prop; do
                    xfconf -c xfce4-desktop -p "$prop" -s "$WALLPAPER"
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
            gset set org.gnome.desktop.background picture-uri "$uri" 2>/dev/null \
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
            gset set org.gnome.desktop.interface color-scheme "$pref"
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

# ---------------------------------------------------------------- fim ------- #

if [ "$APPLIED" -eq 0 ]; then
    printf '
  [33mTema montado, mas nao aplicado.[0m
'
    printf '  [90mNenhum ajuste pegou: gsettings e xfconf-query nao responderam.[0m
'
    printf '  [90mO tema esta em ~/.themes/%s - selecione a mao no ajustador[0m
' "$THEME_NAME"
    printf '  [90mde aparencia do seu ambiente.[0m

'
    exit 0
fi

printf '\n  \033[32mTema aplicado.\033[0m\n'
printf '  \033[90mIcones e cursores nao fazem parte deste tema - veja docs/optional-tools.md\033[0m\n'
printf '  \033[90mPara voltar ao que era antes:  ./uninstall.sh\033[0m\n\n'
