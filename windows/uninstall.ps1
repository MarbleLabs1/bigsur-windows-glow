<#
.SYNOPSIS
    Desfaz o tema Big Sur Glow e devolve as configuracoes anteriores.

.DESCRIPTION
    Le o backup gravado pelo install.ps1 em
    %LOCALAPPDATA%\bigsur-theme\backup.json e restaura cada valor exatamente
    como estava. Valores que nao existiam antes sao removidos, e nao apenas
    zerados, para o Windows voltar ao comportamento padrao.

.PARAMETER Keep
    Mantem o arquivo de backup depois de restaurar.

.EXAMPLE
    .\uninstall.ps1

.NOTES
    Autor: MarbleCeo
#>

[CmdletBinding()]
param(
    [switch]$Keep
)

$ErrorActionPreference = 'Stop'

$StateDir   = Join-Path $env:LOCALAPPDATA 'bigsur-theme'
$BackupPath = Join-Path $StateDir 'backup.json'

$Personalize = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
$Dwm         = 'HKCU:\Software\Microsoft\Windows\DWM'
$Advanced    = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$Search      = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
$Desktop     = 'HKCU:\Control Panel\Desktop'

function Write-Step  { param($m) Write-Host "  -> $m" -ForegroundColor Cyan }
function Write-Ok    { param($m) Write-Host "  OK $m" -ForegroundColor Green }

Add-Type -Namespace BigSur -Name Native -MemberDefinition @'
    [System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
'@

# Restaura um valor, ou apaga a chave se ela nao existia antes.
function Restore-RegValue {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord')
    if ($null -eq $Value) {
        Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        return
    }
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

# --------------------------------------------------------------------------- #

Write-Host ""
Write-Host "  Big Sur Glow - removendo o tema" -ForegroundColor Magenta
Write-Host ""

if (-not (Test-Path $BackupPath)) {
    Write-Host "  Nenhum backup encontrado em $BackupPath." -ForegroundColor Yellow
    Write-Host "  Nada a restaurar - o tema provavelmente nunca foi aplicado nesta conta." -ForegroundColor Yellow
    Write-Host ""
    return
}

$backup = Get-Content $BackupPath -Raw | ConvertFrom-Json
Write-Step "restaurando o backup de $($backup.savedAt)"

Restore-RegValue $Personalize 'AppsUseLightTheme'     $backup.AppsUseLightTheme
Restore-RegValue $Personalize 'SystemUsesLightTheme'  $backup.SystemUsesLightTheme
Restore-RegValue $Personalize 'EnableTransparency'    $backup.EnableTransparency

Restore-RegValue $Dwm 'AccentColor'           $backup.AccentColor
Restore-RegValue $Dwm 'ColorizationColor'     $backup.ColorizationColor
Restore-RegValue $Dwm 'ColorizationAfterglow' $backup.ColorizationAfterglow
Restore-RegValue $Dwm 'ColorPrevalence'       $backup.ColorPrevalence

Restore-RegValue $Advanced 'TaskbarAl' $backup.TaskbarAl
Restore-RegValue $Advanced 'TaskbarDa' $backup.TaskbarDa
Restore-RegValue $Search   'SearchboxTaskbarMode' $backup.SearchboxTaskbarMode

Restore-RegValue $Desktop 'WallpaperStyle' $backup.WallpaperStyle 'String'
Restore-RegValue $Desktop 'Wallpaper'      $backup.Wallpaper      'String'
Write-Ok "chaves restauradas"

if ($backup.Wallpaper -and (Test-Path $backup.Wallpaper)) {
    Write-Step "devolvendo o papel de parede anterior"
    [BigSur.Native]::SystemParametersInfo(20, 0, $backup.Wallpaper, 3) | Out-Null
    Write-Ok (Split-Path $backup.Wallpaper -Leaf)
}

Write-Step "reiniciando o Explorer"
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 800
if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
    Start-Process explorer
}
Write-Ok "Explorer reiniciado"

if (-not $Keep) {
    Remove-Item $BackupPath -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "  Tema removido. Suas configuracoes voltaram ao que eram." -ForegroundColor Green
Write-Host ""
