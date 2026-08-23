#!/usr/bin/env python3
"""
Valida as folhas de gtk/ contra o que o GTK realmente aceita.

O CSS do GTK e um subconjunto do CSS da web, e o parser dele e implacavel:
propriedade desconhecida faz ele descartar a declaracao e logar erro, e
pseudo-classe desconhecida invalida o seletor inteiro em silencio. Como nao
da para rodar o GTK aqui, este script cobre os erros que passariam batido.

Uso:
    python tools/check-gtk-css.py

Sai com codigo 1 se achar problema, para poder entrar em CI.

Autor: MarbleCeo
"""

import io
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GTK = os.path.join(os.path.dirname(HERE), "gtk")

# ---------------------------------------------------------------- propriedades

# O que o GTK aceita. Prefixos -gtk- e -Gtk...- sao liberados a parte.
ALLOWED = {
    "color", "opacity", "caret-color",
    "background", "background-color", "background-image", "background-position",
    "background-repeat", "background-size", "background-clip", "background-origin",
    "border", "border-width", "border-style", "border-color", "border-radius",
    "border-top", "border-right", "border-bottom", "border-left",
    "border-top-width", "border-right-width", "border-bottom-width", "border-left-width",
    "border-top-style", "border-right-style", "border-bottom-style", "border-left-style",
    "border-top-color", "border-right-color", "border-bottom-color", "border-left-color",
    "border-top-left-radius", "border-top-right-radius",
    "border-bottom-left-radius", "border-bottom-right-radius",
    "border-image", "border-image-source", "border-image-slice",
    "border-image-width", "border-image-repeat",
    "box-shadow", "outline", "outline-color", "outline-style",
    "outline-width", "outline-offset",
    "margin", "margin-top", "margin-right", "margin-bottom", "margin-left",
    "padding", "padding-top", "padding-right", "padding-bottom", "padding-left",
    "min-width", "min-height",
    "font", "font-family", "font-size", "font-style", "font-weight",
    "font-variant", "font-stretch", "font-feature-settings",
    "text-shadow", "text-decoration", "text-decoration-line",
    "text-decoration-color", "text-decoration-style", "letter-spacing",
    "text-transform", "transform", "transform-origin", "filter",
    "transition", "transition-property", "transition-duration",
    "transition-timing-function", "transition-delay",
    "animation", "animation-name", "animation-duration", "animation-timing-function",
    "animation-iteration-count", "animation-direction", "animation-play-state",
    "animation-delay", "animation-fill-mode",
    "icon-shadow", "icon-size",
}

# Propriedades que a gente escreve no automatico e o GTK simplesmente ignora.
FORBIDDEN = {
    "width": "use min-width",
    "height": "use min-height",
    "display": "GTK nao tem display; o layout vem do widget",
    "position": "GTK nao tem posicionamento CSS",
    "top": "GTK nao tem posicionamento CSS",
    "right": "GTK nao tem posicionamento CSS",
    "bottom": "GTK nao tem posicionamento CSS",
    "left": "GTK nao tem posicionamento CSS",
    "z-index": "nao existe no GTK",
    "overflow": "nao existe no GTK",
    "cursor": "nao existe no GTK",
    "content": "nao existe no GTK",
    "visibility": "nao existe no GTK",
    "float": "nao existe no GTK",
    "flex": "nao existe no GTK",
    "gap": "nao existe no GTK",
    "grid-template-columns": "nao existe no GTK",
    "line-height": "nao existe no GTK; ajuste padding",
    "text-align": "nao existe no GTK; e propriedade do widget",
    "vertical-align": "nao existe no GTK",
    "white-space": "nao existe no GTK",
    "backdrop-filter": "nao existe no GTK",
    "aspect-ratio": "nao existe no GTK",
    "text-wrap": "nao existe no GTK",
}

# ------------------------------------------------------------- pseudo-classes

COMMON_PSEUDO = {
    "hover", "active", "checked", "selected", "disabled", "backdrop", "focus",
    "indeterminate", "first-child", "last-child", "only-child", "nth-child",
    "dir", "not", "link", "visited", "drop", "selection", "insensitive",
}
GTK4_ONLY_PSEUDO = {"focus-visible", "focus-within"}

# Funcoes de cor do GTK. color-mix/hsl da web nao existem aqui.
COLOR_FN = {"rgb", "rgba", "alpha", "shade", "mix", "lighter", "darker",
            "linear-gradient", "radial-gradient", "url", "image",
            "cubic-bezier", "steps", "translate", "translatex", "translatey",
            "scale", "rotate"}
GTK_FN_PREFIX = ("-gtk-",)

COMMENT = re.compile(r"/\*.*?\*/", re.S)
DECL = re.compile(r"([-A-Za-z][-A-Za-z0-9]*)\s*:\s*([^;{}]*);")
PSEUDO = re.compile(r":([a-zA-Z][a-zA-Z-]*)")
FUNC = re.compile(r"([-A-Za-z][-A-Za-z0-9]*)\s*\(")


def line_of(text, idx):
    return text.count("\n", 0, idx) + 1


def check(path, is_gtk4):
    raw = io.open(path, encoding="utf-8").read()
    src = COMMENT.sub(lambda m: "\n" * m.group(0).count("\n"), raw)
    name = os.path.basename(path)
    problems = []

    # conta no texto sem comentario: chave dentro de /* */ nao conta
    if src.count("{") != src.count("}"):
        problems.append((0, "chaves desbalanceadas: %d abre, %d fecha"
                         % (src.count("{"), src.count("}"))))

    # declaracoes
    for m in DECL.finditer(src):
        prop, value = m.group(1), m.group(2).strip()
        ln = line_of(src, m.start())
        low = prop.lower()
        if low.startswith("-gtk") or prop.startswith("-Gtk"):
            continue
        if low in FORBIDDEN:
            problems.append((ln, "propriedade '%s' nao existe no GTK (%s)"
                             % (prop, FORBIDDEN[low])))
        elif low not in ALLOWED:
            problems.append((ln, "propriedade desconhecida para o GTK: '%s'" % prop))
        if not value:
            problems.append((ln, "'%s' sem valor" % prop))

    # seletores: tudo que vem antes de '{' e nao e declaracao
    for m in re.finditer(r"([^{}]+)\{", src):
        sel = m.group(1)
        ln = line_of(src, m.start())
        for pm in PSEUDO.finditer(sel):
            pc = pm.group(1)
            if pc in GTK4_ONLY_PSEUDO and not is_gtk4:
                problems.append((ln, ":%s so existe no GTK4; no GTK3 use :focus" % pc))
            elif pc not in COMMON_PSEUDO and pc not in GTK4_ONLY_PSEUDO:
                problems.append((ln, "pseudo-classe suspeita: ':%s'" % pc))

    # funcoes. Cuidado: :not(...) e :dir(...) sao pseudo-classes com
    # argumento, nao funcoes -- reconhece pelo ':' logo antes do nome.
    for m in FUNC.finditer(src):
        fn = m.group(1).lower()
        if m.start() > 0 and src[m.start() - 1] == ":":
            continue
        if fn.startswith(GTK_FN_PREFIX) or fn in COLOR_FN:
            continue
        problems.append((line_of(src, m.start()), "funcao desconhecida: '%s()'" % fn))

    return name, problems


def main():
    files = [
        ("widgets-gtk3.css", False),
        ("widgets-gtk4.css", True),
        ("colors-light.css", False),
        ("colors-dark.css", False),
    ]
    total = 0
    for fname, is4 in files:
        path = os.path.join(GTK, fname)
        if not os.path.exists(path):
            print("FALTA  %s" % fname)
            total += 1
            continue
        name, problems = check(path, is4)
        if problems:
            print("RUIM   %s" % name)
            for ln, msg in problems:
                print("       linha %-4s %s" % (ln, msg))
            total += len(problems)
        else:
            print("OK     %s" % name)

    print()
    if total:
        print("%d problema(s)." % total)
        return 1
    print("Nenhum problema.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
