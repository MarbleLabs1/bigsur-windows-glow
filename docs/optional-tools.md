# Ferramentas opcionais

O instalador deste repositorio mexe **somente** em configuracoes de aparencia
da sua conta de usuario. Ele nao baixa nada, nao pede administrador e nao
altera arquivo de sistema nenhum. Por isso ele e 100% reversivel.

O resto do visual do Big Sur — cantos arredondados, dock, icones, barra
translucida — depende de programas de terceiros. Esta pagina lista quais sao,
o que cada um faz e o que voce esta aceitando ao instalar.

**Baixe cada um do site oficial do proprio projeto e instale voce mesmo.** Este
repositorio nao redistribui binario de ninguem.

---

## Windows

### Sem risco — sao apenas aplicativos

| Ferramenta | O que faz | Onde conseguir |
|---|---|---|
| **TranslucentTB** | Deixa a barra de tarefas translucida ou totalmente transparente. | Microsoft Store, ou `winget install TranslucentTB` |
| **RoundedTB** | Arredonda os cantos da barra de tarefas e cria margens, deixando ela flutuante como o dock do macOS. | Microsoft Store |
| **Nexus Dock** / **RocketDock** | Dock na base da tela, com efeito de ampliacao. | Site do fabricante |
| **MacType** | Renderizacao de fontes parecida com a da Apple. | GitHub do projeto |

Essas quatro sao aplicativos comuns: instalam, rodam, desinstalam. Se nao
gostar, remova pelo Painel de Controle e nada fica para tras.

### Exige atencao — mexe no sistema

| Ferramenta | O que faz | O que voce precisa saber |
|---|---|---|
| **SecureUxTheme** | Permite que o Windows aceite arquivos `.msstyles` nao assinados pela Microsoft, que e o que os temas visuais de verdade usam. | Trabalha na memoria, sem alterar a `uxtheme.dll` no disco. E a opcao mais segura da categoria, mas ainda assim contorna uma verificacao de assinatura do sistema. |
| **UltraUXThemePatcher** | Mesma finalidade, mas fazendo patch permanente nos arquivos do sistema. | Altera DLLs no disco. Uma atualizacao do Windows pode desfazer o patch e, em casos raros, deixar o sistema sem interface grafica. **Faca um ponto de restauracao antes.** |

Este projeto nao automatiza nem recomenda essas duas. Se voce optar por elas, a
decisao e sua e o risco tambem — leia a documentacao de cada uma antes.

### Icones e cursores

Pacotes de icones e cursores no estilo macOS circulam em sites como o
DeviantArt. Verifique a licenca de cada pacote antes de usar: boa parte deriva
de arte da Apple e nao pode ser redistribuida.

---

## Linux

No Linux o caminho e bem mais simples, porque o proprio sistema suporta temas
sem gambiarra.

| Componente | Para que serve |
|---|---|
| **WhiteSur GTK Theme** | Os widgets no estilo macOS. E o que o `linux/install.sh` procura. |
| **WhiteSur Icon Theme** | Conjunto de icones. |
| **Capitaine Cursors** | Cursores no estilo macOS. |
| **Plank** | Dock. |

O jeito mais rapido de instalar todos de uma vez e usar o projeto irmao deste
aqui, que ja automatiza tudo:

```bash
git clone https://github.com/MarbleCeo/macos-theme-for-linux.git
cd macos-theme-for-linux
sudo ./install.sh
```

Depois rode o `linux/install.sh` deste repositorio para aplicar por cima a
paleta e o papel de parede do Big Sur Glow.

---

## Por que o tema nao vem completo?

Duas razoes, ambas praticas:

1. **Copyright.** Os papeis de parede, icones e sons originais do macOS sao da
   Apple. Redistribuir isso e violacao de direitos autorais. Os papeis de
   parede deste repositorio sao gradientes gerados por codigo
   (`assets/wallpaper-*.png`) — arte original, inspirada no visual, sem copiar
   nada.

2. **Confianca.** Um instalador que baixa binario da internet e roda sozinho e
   exatamente o formato que malware usa. Preferimos que voce baixe cada
   ferramenta da fonte oficial, conscientemente.
