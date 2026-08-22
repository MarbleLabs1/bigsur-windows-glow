<#
.SYNOPSIS
    Aplica o tema Big Sur Glow no Windows 10/11.

.DESCRIPTION
    Altera apenas configuracoes de aparencia do usuario atual (HKCU). Nao mexe
    em arquivos de sistema, nao exige administrador e nao instala nada de
    terceiros. Tudo o que e alterado e salvo antes em um backup, e o
    uninstall.ps1 devolve exatamente como estava.

    O que este script faz:
      - modo claro ou escuro (aplicativos e barra de tarefas)
      - cor de destaque da paleta Big Sur Glow
      - transparencia das janelas ligada
      - papel de parede (gradiente original que acompanha o repositorio)
      - barra de tarefas centralizada, sem caixa de busca e sem widgets

.PARAMETER Dark
    Usa a variante escura. O padrao e a clara.

.PARAMETER NoWallpaper
    Mantem o papel de parede atual.

.PARAMETER NoTaskbar
    Nao mexe na barra de tarefas.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -Dark
    .\install.ps1 -Dark -NoWallpaper

.NOTES
    Autor: MarbleCeo
    Para o visual completo (bordas arredondadas, dock, icones), veja
    docs/optional-tools.md.
#>

[CmdletBinding()]
param(
    [switch]$Dark,
    [switch]$NoWallpaper,
    [switch]$NoTaskbar
)

$ErrorActionPreference = 'Stop'

$RepoRoot  = Split-Path -Parent $PSScriptRoot
$StateDir  = Join-Path $env:LOCALAPPDATA 'bigsur-theme'
$BackupPath = Join-Path $StateDir 'backup.json'

$Personalize = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
$Dwm         = 'HKCU:\Software\Microsoft\Windows\DWM'
$Advanced    = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$Search      = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
$Desktop     = 'HKCU:\Control Panel\Desktop'

function Write-Step   { param($m) Write-Host "  -> $m" -ForegroundColor Cyan }
function Write-Ok     { param($m) Write-Host "  OK $m" -ForegroundColor Green }
function Write-Warn2  { param($m) Write-Host "  !  $m" -ForegroundColor Yellow }

function Get-RegValue {
    param([string]$Path, [string]$Name)
    try {
        return (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
    } catch {
        return $null
    }
}

function Set-RegValue {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord')
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

# Converte #RRGGBB para o DWORD ABGR que o DWM espera.
function ConvertTo-AbgrDword {
    param([string]$Hex)
    $h = $Hex.TrimStart('#')
    $r = [Convert]::ToInt32($h.Substring(0, 2), 16)
    $g = [Convert]::ToInt32($h.Substring(2, 2), 16)
    $b = [Convert]::ToInt32($h.Substring(4, 2), 16)
    return ([int]0xFF -shl 24) -bor ($b -shl 16) -bor ($g -shl 8) -bor $r
}

Add-Type -Namespace BigSur -Name Native -MemberDefinition @'
    [System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
'@

function Set-Wallpaper {
    param([string]$Path)
    # SPI_SETDESKWALLPAPER = 20, atualiza o perfil e avisa as janelas
    [BigSur.Native]::SystemParametersInfo(20, 0, $Path, 3) | Out-Null
}

# --------------------------------------------------------------------------- #

$variant = if ($Dark) { 'dark' } else { 'light' }

Write-Host ""
Write-Host "  Big Sur Glow - tema para Windows" -ForegroundColor Magenta
Write-Host "  variante: $variant" -ForegroundColor DarkGray
Write-Host ""

$palettePath = Join-Path $RepoRoot 'shared\palette.json'
if (-not (Test-Path $palettePath)) {
    throw "shared/palette.json nao encontrado. Rode o script de dentro do repositorio clonado."
}
$palette = Get-Content $palettePath -Raw | ConvertFrom-Json
$accentHex = $palette.accent.$variant

# ---------------------------- backup --------------------------------------- #

if (-not (Test-Path $StateDir)) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }

if (Test-Path $BackupPath) {
    Write-Warn2 "backup anterior mantido em $BackupPath"
} else {
    Write-Step "salvando suas configuracoes atuais"
    $backup = [ordered]@{
        savedAt            = (Get-Date).ToString('s')
        AppsUseLightTheme  = Get-RegValue $Personalize 'AppsUseLightTheme'
        SystemUsesLightTheme = Get-RegValue $Personalize 'SystemUsesLightTheme'
        EnableTransparency = Get-RegValue $Personalize 'EnableTransparency'
        AccentColor        = Get-RegValue $Dwm 'AccentColor'
        ColorizationColor  = Get-RegValue $Dwm 'ColorizationColor'
        ColorizationAfterglow = Get-RegValue $Dwm 'ColorizationAfterglow'
        ColorPrevalence    = Get-RegValue $Dwm 'ColorPrevalence'
        TaskbarAl          = Get-RegValue $Advanced 'TaskbarAl'
        TaskbarDa          = Get-RegValue $Advanced 'TaskbarDa'
        SearchboxTaskbarMode = Get-RegValue $Search 'SearchboxTaskbarMode'
        Wallpaper          = Get-RegValue $Desktop 'Wallpaper'
        WallpaperStyle     = Get-RegValue $Desktop 'WallpaperStyle'
    }
    $backup | ConvertTo-Json | Set-Content -Path $BackupPath -Encoding UTF8
    Write-Ok "backup em $BackupPath"
}

# ---------------------------- aparencia ------------------------------------ #

Write-Step "aplicando modo $variant"
$light = if ($Dark) { 0 } else { 1 }
Set-RegValue $Personalize 'AppsUseLightTheme'   $light
Set-RegValue $Personalize 'SystemUsesLightTheme' $light
Write-Ok "modo $variant"

Write-Step "cor de destaque $accentHex"
$accent = ConvertTo-AbgrDword $accentHex
Set-RegValue $Dwm 'AccentColor'           $accent
Set-RegValue $Dwm 'ColorizationColor'     $accent
Set-RegValue $Dwm 'ColorizationAfterglow' $accent
Set-RegValue $Dwm 'ColorPrevalence'       1
Write-Ok "cor de destaque aplicada"

Write-Step "ligando transparencia"
Set-RegValue $Personalize 'EnableTransparency' 1
Write-Ok "transparencia ligada"

# ---------------------------- papel de parede ------------------------------ #

if (-not $NoWallpaper) {
    $wallpaper = Join-Path $RepoRoot ($palette.wallpaper.$variant -replace '/', '\')
    if (Test-Path $wallpaper) {
        Write-Step "aplicando papel de parede"
        Set-RegValue $Desktop 'WallpaperStyle' '10' 'String'   # 10 = preencher
        Set-RegValue $Desktop 'TileWallpaper'  '0'  'String'
        Set-Wallpaper -Path (Resolve-Path $wallpaper).Path
        Write-Ok (Split-Path $wallpaper -Leaf)
    } else {
        Write-Warn2 "papel de parede nao encontrado em $wallpaper"
    }
}

# ---------------------------- barra de tarefas ----------------------------- #

if (-not $NoTaskbar) {
    Write-Step "ajustando a barra de tarefas"
    Set-RegValue $Advanced 'TaskbarAl' 1              # centralizada (Windows 11)
    Set-RegValue $Advanced 'TaskbarDa' 0              # sem widgets
    Set-RegValue $Search   'SearchboxTaskbarMode' 0   # sem caixa de busca
    Write-Ok "barra de tarefas ajustada"
}

# ---------------------------- aplicar -------------------------------------- #

Write-Step "reiniciando o Explorer para aplicar"
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 800
if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
    Start-Process explorer
}
Write-Ok "Explorer reiniciado"

Write-Host ""
Write-Host "  Tema aplicado." -ForegroundColor Green
Write-Host "  Para voltar ao que era antes:  .\uninstall.ps1" -ForegroundColor DarkGray
Write-Host "  Bordas arredondadas, dock e icones: docs/optional-tools.md" -ForegroundColor DarkGray
Write-Host ""
