
# ==========================================
# duduDev - Brand Identity
# Ejecutor del sitio web
# ==========================================

$ErrorActionPreference = "Stop"

# Ruta del proyecto
$Proyecto = $PSScriptRoot

# Rutas principales
$Web = Join-Path $Proyecto "05_proyecto_web"
$HTML = Join-Path $Web "index.html"
$CSS = Join-Path $Web "css\style.css"
$JS = Join-Path $Web "js\main.js"

$Logo = Join-Path $Proyecto "01_identidad\logotipos\svg\dududev_logo.svg"

Clear-Host

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "       duduDev | Brand Identity" -ForegroundColor White
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Validar archivos
$Archivos = @(
    $HTML,
    $CSS,
    $JS,
    $Logo
)

$Errores = @()

foreach ($Archivo in $Archivos) {

    if (Test-Path $Archivo) {
        Write-Host "[OK] $Archivo" -ForegroundColor Green
    }
    else {
        Write-Host "[ERROR] No encontrado: $Archivo" -ForegroundColor Red
        $Errores += $Archivo
    }
}

if ($Errores.Count -gt 0) {
    Write-Host ""
    Write-Host "Hay archivos pendientes. Revisa las rutas." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Validacion completada." -ForegroundColor Green

# Abrir Visual Studio Code
Write-Host ""
Write-Host "Abriendo Visual Studio Code..." -ForegroundColor Yellow

if (Get-Command code -ErrorAction SilentlyContinue) {
    Start-Process code -ArgumentList "`"$Web`""
}
else {
    Write-Host "VS Code no esta disponible en PATH." -ForegroundColor Yellow
}

# Abrir sitio web
Write-Host ""
Write-Host "Iniciando sitio web..." -ForegroundColor Yellow

Start-Process $HTML

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "       SITIO INICIADO CORRECTAMENTE" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
