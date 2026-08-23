# Big Sur Glow

[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078D6.svg)](#windows)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-FCC624.svg)](#linux)
[![License](https://img.shields.io/badge/License-All%20rights%20reserved-lightgrey.svg)](LICENSE)

**Desenvolvido por [MarbleCeo](https://github.com/MarbleCeo)**

Tema de area de trabalho inspirado no macOS Big Sur, para **Windows 10/11 e
Linux**. Paleta lavanda, transparencia, papeis de parede em gradiente e barra
de tarefas no estilo dock.

Projeto irmao do [macos-theme-for-linux](https://github.com/MarbleCeo/macos-theme-for-linux).

---

## O que ele faz

**No Linux — um tema GTK proprio**, escrito neste repositorio. Nao depende de
WhiteSur nem de nenhum outro tema de terceiros:

- **GTK 3 e GTK 4/libadwaita**, claro e escuro, montados a partir da mesma
  folha de regras
- **Semaforo**: os tres circulos coloridos a esquerda da barra de titulo, com
  os glifos aparecendo so quando o ponteiro entra na barra
- Cantos de janela arredondados e sombra difusa
- Botoes, campos, interruptores, caixas, radios e deslizantes redesenhados
- Popovers e menus com canto de 12px e item em pilula
- Abas no desenho do *segmented control*
- Barra lateral e listas com linha selecionada arredondada
- Barra de rolagem fina e flutuante, que engorda com o ponteiro perto

**No Windows** — ajustes de aparencia da conta: modo claro/escuro, cor de
destaque, transparencia, papel de parede e barra de tarefas.

**Nos dois** — papel de parede em gradiente (arte original, gerada por codigo).

## O que ele **nao** faz

Este instalador altera **somente configuracoes de aparencia da sua conta de
usuario**. Ele nao pede administrador, nao baixa nada da internet e nao toca em
arquivo de sistema.

**Icones e cursores nao fazem parte deste tema.** Sao milhares de SVGs e um
pipeline de xcursor — trabalho de outra ordem de grandeza, e ha conjuntos
prontos e bons. Dock e pacotes de icones estao listados em
[docs/optional-tools.md](docs/optional-tools.md).

**No Windows nao ha tema de janela.** A aparencia das bordas vem de um arquivo
`.msstyles`, que e recurso binario compilado — nao da para escrever em texto, e
exige um patcher para aceitar estilo nao assinado. O que esta aqui e um
configurador honesto, nao um tema de janela.

---

## Instalacao

### Windows

```powershell
git clone https://github.com/MarbleLabs1/bigsur-windows-glow.git
cd bigsur-windows-glow\windows
.\install.ps1
```

Se o PowerShell recusar o script, libere a execucao apenas para esta sessao:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Opcoes:

| Opcao | Efeito |
|---|---|
| `-Dark` | Variante escura (o padrao e a clara) |
| `-NoWallpaper` | Mantem o seu papel de parede atual |
| `-NoTaskbar` | Nao mexe na barra de tarefas |

Para desfazer:

```powershell
.\uninstall.ps1
```

### Linux

```bash
git clone https://github.com/MarbleLabs1/bigsur-windows-glow.git
cd bigsur-windows-glow/linux
./install.sh
```

Opcoes:

| Opcao | Efeito |
|---|---|
| `--dark` | Variante escura |
| `--no-wallpaper` | Mantem o papel de parede atual |
| `--no-gtk4` | Nao mexe em `~/.config/gtk-4.0` |
| `--buttons-right` | Mantem os botoes a direita, sem o semaforo |

Para desfazer:

```bash
./uninstall.sh
```

Ambientes suportados: GNOME, Cinnamon, MATE, XFCE e KDE Plasma.

#### Como o tema e montado

Nao ha passo de build e nao ha CSS duplicado. O `install.sh` concatena o bloco
de cores da variante escolhida com a folha de widgets:

```
gtk/colors-dark.css  +  gtk/widgets-gtk3.css  ->  ~/.themes/BigSur-Glow-Dark/gtk-3.0/gtk.css
gtk/colors-dark.css  +  gtk/widgets-gtk4.css  ->  ~/.themes/BigSur-Glow-Dark/gtk-4.0/gtk.css
```

A folha de widgets nao contem **nenhuma cor literal** — so referencias a
`@define-color`. Trocar a paleta e trocar um arquivo de 120 linhas; as 191
regras do GTK 3 e as 84 do GTK 4 continuam iguais.

O libadwaita ignora `~/.themes` por completo, entao a folha do GTK 4 tambem e
copiada para `~/.config/gtk-4.0/gtk.css`. O `uninstall.sh` devolve o arquivo
anterior se voce ja tinha um.

#### Validando o CSS

O CSS do GTK e um subconjunto do CSS da web, e o parser dele descarta em
silencio o que nao entende: `width`, `line-height`, `calc()`, `color-mix()` e
`:focus-visible` no GTK 3 sao os tropecos classicos. Antes de mexer nas
folhas, rode:

```bash
python tools/check-gtk-css.py
```

Ele confere chaves, propriedades, pseudo-classes e funcoes contra o que o GTK
aceita de fato, e sai com codigo 1 se achar problema.

---

## Sempre da pra voltar atras

Antes de mudar qualquer coisa, o instalador grava o estado anterior:

| Sistema | Onde fica o backup |
|---|---|
| Windows | `%LOCALAPPDATA%\bigsur-theme\backup.json` |
| Linux | `~/.config/bigsur-theme/backup.env` |

O desinstalador le esse arquivo e devolve cada valor como estava. Configuracoes
que nao existiam antes sao **removidas**, e nao zeradas, para o sistema voltar
ao comportamento padrao de verdade.

---

## A paleta

| Cor | Hex | Uso |
|---|---|---|
| Lavender | `#D6BCFA` | Destaque no modo escuro |
| Iris | `#9b87f5` | Destaque no modo claro |
| Violet | `#7E69AB` | Sombras e bordas |
| Indigo | `#6E59A5` | Topo do gradiente |
| Ink | `#221F26` | Texto no modo claro |
| Slate | `#403E43` | Texto secundario |
| Mist | `#E5DEFF` | Texto no modo escuro |
| Sky | `#D3E4FD` | Texto secundario no escuro |

Fonte unica da verdade: [`shared/palette.json`](shared/palette.json). Os
instaladores dos dois sistemas leem dali — mude o hex uma vez e vale para
Windows e Linux.

---

## Pagina de vitrine

O repositorio inclui uma pagina estatica que mostra a paleta, os papeis de
parede e os comandos de instalacao. Sem build e sem dependencias: abra o
arquivo direto no navegador.

```bash
start index.html      # Windows
xdg-open index.html   # Linux
```

Ela e apenas vitrine. O tema em si sao os scripts em `windows/` e `linux/`.

---

## Estrutura

```
bigsur-windows-glow/
├── gtk/                    # o tema em si
│   ├── colors-light.css    #   so @define-color, variante clara
│   ├── colors-dark.css     #   so @define-color, variante escura
│   ├── widgets-gtk3.css    #   191 regras, nenhuma cor literal
│   └── widgets-gtk4.css    #   84 regras + cores nomeadas do libadwaita
├── shared/palette.json     # paleta compartilhada pelos dois sistemas
├── assets/                 # papeis de parede (gradientes gerados por codigo)
├── windows/
│   ├── install.ps1
│   └── uninstall.ps1
├── linux/
│   ├── install.sh          # monta o tema e aplica
│   └── uninstall.sh
├── tools/check-gtk-css.py  # valida as folhas contra o parser do GTK
├── docs/optional-tools.md  # dock, icones, cursores
└── index.html              # pagina de vitrine (HTML estatico, sem build)
```

---

## Licenca

Copyright (c) 2026 MarbleCeo. **Todos os direitos reservados.** Veja
[LICENSE](LICENSE).

Os papeis de parede sao gradientes gerados pelo codigo deste repositorio — arte
original. Nenhum material da Apple e redistribuido aqui.
