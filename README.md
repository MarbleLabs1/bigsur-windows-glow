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

- Modo claro e escuro, com uma paleta lavanda propria
- Cor de destaque do sistema aplicada em janelas, botoes e selecao
- Transparencia das janelas ligada
- Papel de parede em gradiente (arte original, gerada por codigo)
- Barra de tarefas centralizada, sem widgets e sem caixa de busca (Windows 11)
- No Linux, integra com o tema GTK WhiteSur quando ele estiver instalado

## O que ele **nao** faz

Este instalador altera **somente configuracoes de aparencia da sua conta de
usuario**. Ele nao pede administrador, nao baixa nada da internet e nao toca em
arquivo de sistema.

Cantos arredondados, dock e pacotes de icones dependem de programas de
terceiros, listados em [docs/optional-tools.md](docs/optional-tools.md) para
voce instalar por conta propria, se quiser.

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

Para desfazer:

```bash
./uninstall.sh
```

Ambientes suportados: GNOME, Cinnamon, MATE, XFCE e KDE Plasma.

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

## Pagina de demonstracao

O repositorio inclui uma pagina web (Vite + React + Tailwind) que mostra a
paleta e os comandos de instalacao:

```bash
npm install
npm run dev
```

Ela e apenas vitrine. O tema em si sao os scripts em `windows/` e `linux/`.

---

## Estrutura

```
bigsur-windows-glow/
├── shared/palette.json     # paleta compartilhada pelos dois sistemas
├── assets/                 # papeis de parede (gradientes gerados por codigo)
├── windows/
│   ├── install.ps1
│   └── uninstall.ps1
├── linux/
│   ├── install.sh
│   └── uninstall.sh
├── docs/optional-tools.md  # dock, icones, cantos arredondados
└── src/                    # pagina de demonstracao (Vite + React)
```

---

## Licenca

Copyright (c) 2026 MarbleCeo. **Todos os direitos reservados.** Veja
[LICENSE](LICENSE).

Os papeis de parede sao gradientes gerados pelo codigo deste repositorio — arte
original. Nenhum material da Apple e redistribuido aqui.
