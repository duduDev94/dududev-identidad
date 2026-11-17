
param(
    [ValidateSet("start", "stop", "status")]
    [string]$Accion = "start"
)

$ErrorActionPreference = "Stop"

# ==========================================
# CONFIGURACION
# ==========================================

$Proyecto = $PSScriptRoot
$Web = Join-Path $Proyecto "05_proyecto_web"

$HTML = Join-Path $Web "index.html"
$LogoOriginal = Join-Path $Proyecto "01_identidad\logotipos\svg\dududev_logo.svg"

$Assets = Join-Path $Web "assets"
$LogoWeb = Join-Path $Assets "dududev_logo.svg"

$Logs = Join-Path $Web "logs"
$LogSalida = Join-Path $Logs "server.log"
$LogError = Join-Path $Logs "server-error.log"

$ArchivoPID = Join-Path $Proyecto ".server.pid"

$Puerto = 8000
$URL = "http://127.0.0.1:$Puerto"

# ==========================================
# FUNCIONES
# ==========================================

function Get-ServidorPID {

    if (Test-Path $ArchivoPID) {
        return [int](Get-Content $ArchivoPID -Raw).Trim()
    }

    return $null
}

function Test-ServidorActivo {

    try {
        $respuesta = Invoke-WebRequest `
            -Uri "$URL/" `
            -UseBasicParsing `
            -TimeoutSec 2

        return ($respuesta.StatusCode -eq 200)
    }
    catch {
        return $false
    }
}

# ==========================================
# INICIAR
# ==========================================

if ($Accion -eq "start") {

    Write-Host ""
    Write-Host "duduDev | Servidor local" -ForegroundColor Cyan
    Write-Host "----------------------------------"

    if (!(Test-Path $HTML)) {
        throw "No se encontro index.html."
    }

    # Preparar carpetas
    New-Item -ItemType Directory -Path $Assets -Force | Out-Null
    New-Item -ItemType Directory -Path $Logs -Force | Out-Null

    # Copiar logotipo al directorio publico
    if (Test-Path $LogoOriginal) {

        Copy-Item $LogoOriginal $LogoWeb -Force

        Write-Host "[OK] Logotipo sincronizado." -ForegroundColor Green

        # Actualizar las referencias del HTML
        $Contenido = Get-Content $HTML -Raw

        $Contenido = $Contenido.Replace(
            "../01_identidad/logotipos/svg/dududev_logo.svg",
            "assets/dududev_logo.svg"
        )

        Set-Content -Path $HTML -Value $Contenido -Encoding UTF8
    }
    else {
        Write-Host "[AVISO] No se encontro el SVG original." -ForegroundColor Yellow
    }

    # Comprobar servidor existente
    if (Test-ServidorActivo) {

        Write-Host "[OK] El servidor ya esta funcionando." -ForegroundColor Green
        Start-Process $URL

        exit
    }

    # Buscar Python
    $PythonLauncher = Get-Command py -ErrorAction SilentlyContinue

    if ($PythonLauncher) {
        $Ejecutable = $PythonLauncher.Source
        $Argumentos = @(
            "-3",
            "-m",
            "http.server",
            "$Puerto",
            "--bind",
            "127.0.0.1"
        )
    }
    else {

        $PythonLauncher = Get-Command python -ErrorAction SilentlyContinue

        if (!$PythonLauncher) {
            throw "Python no esta instalado o no esta disponible en PATH."
        }

        $Ejecutable = $PythonLauncher.Source
        $Argumentos = @(
            "-m",
            "http.server",
            "$Puerto",
            "--bind",
            "127.0.0.1"
        )
    }

    # Limpiar logs anteriores
    if (Test-Path $LogSalida) {
        Clear-Content $LogSalida
    }

    if (Test-Path $LogError) {
        Clear-Content $LogError
    }

    # Iniciar Python en segundo plano
    $Proceso = Start-Process `
        -FilePath $Ejecutable `
        -ArgumentList $Argumentos `
        -WorkingDirectory $Web `
        -WindowStyle Hidden `
        -RedirectStandardOutput $LogSalida `
        -RedirectStandardError $LogError `
        -PassThru

    Set-Content -Path $ArchivoPID -Value $Proceso.Id

    Start-Sleep -Seconds 2

    # Verificar funcionamiento
    if (Test-ServidorActivo) {

        Write-Host ""
        Write-Host "[OK] Servidor iniciado correctamente." -ForegroundColor Green
        Write-Host "URL: $URL" -ForegroundColor Cyan

        Start-Process $URL
    }
    else {

        Remove-Item $ArchivoPID -Force -ErrorAction SilentlyContinue

        throw "No se pudo iniciar el servidor. Revisa $LogError"
    }
}

# ==========================================
# DETENER
# ==========================================

elseif ($Accion -eq "stop") {

    $PIDServidor = Get-ServidorPID

    if ($PIDServidor) {

        $Proceso = Get-Process -Id $PIDServidor -ErrorAction SilentlyContinue

        if ($Proceso -and $Proceso.ProcessName -match "python") {

            Stop-Process -Id $PIDServidor -Force

            Write-Host "[OK] Servidor detenido." -ForegroundColor Green
        }
        else {
            Write-Host "[AVISO] El proceso registrado ya no existe." -ForegroundColor Yellow
        }

        Remove-Item $ArchivoPID -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-Host "No hay un proceso registrado." -ForegroundColor Yellow
    }
}

# ==========================================
# ESTADO
# ==========================================

elseif ($Accion -eq "status") {

    if (Test-ServidorActivo) {

        Write-Host "[ACTIVO] Servidor funcionando." -ForegroundColor Green
        Write-Host "URL: $URL" -ForegroundColor Cyan
    }
    else {

        Write-Host "[INACTIVO] Servidor detenido." -ForegroundColor Red
    }
}

Write-Host ""
