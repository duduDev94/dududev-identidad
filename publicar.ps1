
# ============================================================
# duduDev | PUBLICACION AUTOMATIZADA
# Git + GitHub + GitHub Pages
# ============================================================

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# CONFIGURACION
# ------------------------------------------------------------

$Proyecto = $PSScriptRoot
$Web = Join-Path $Proyecto "05_proyecto_web"

$HTML = Join-Path $Web "index.html"
$Assets = Join-Path $Web "assets"

$LogoOriginal = Join-Path $Proyecto "01_identidad\logotipos\svg\dududev_logo.svg"
$LogoWeb = Join-Path $Assets "dududev_logo.svg"

$WorkflowDir = Join-Path $Proyecto ".github\workflows"
$WorkflowFile = Join-Path $WorkflowDir "deploy.yml"

$RepoNombre = "dududev-identidad"
$Descripcion = "Identidad visual y sitio web oficial de duduDev"

# ------------------------------------------------------------
# FUNCIONES
# ------------------------------------------------------------

function Mostrar-Titulo {
    param([string]$Texto)

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host " $Texto" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
}

function Verificar-Comando {
    param([string]$Comando)

    return [bool](Get-Command $Comando -ErrorAction SilentlyContinue)
}

function Ejecutar-Comando {
    param(
        [string]$Programa,
        [string[]]$Argumentos
    )

    & $Programa @Argumentos

    if ($LASTEXITCODE -ne 0) {
        throw "Error ejecutando: $Programa $($Argumentos -join ' ')"
    }
}

# ------------------------------------------------------------
# 1. VALIDAR PROYECTO
# ------------------------------------------------------------

Mostrar-Titulo "1. VALIDANDO PROYECTO"

if (!(Test-Path $HTML)) {
    throw "No existe 05_proyecto_web\index.html"
}

New-Item -ItemType Directory -Path $Assets -Force | Out-Null

Write-Host "[OK] Proyecto encontrado." -ForegroundColor Green

# ------------------------------------------------------------
# 2. VERIFICAR HERRAMIENTAS
# ------------------------------------------------------------

Mostrar-Titulo "2. VERIFICANDO HERRAMIENTAS"

if (!(Verificar-Comando "git")) {
    Write-Host "Git no esta instalado." -ForegroundColor Yellow

    if (Verificar-Comando "winget") {
        Ejecutar-Comando "winget" @(
            "install",
            "--id", "Git.Git",
            "-e"
        )
    }

    Write-Host "Cierra PowerShell, abre una nueva ventana y vuelve a ejecutar este script." -ForegroundColor Yellow
    exit
}

if (!(Verificar-Comando "gh")) {
    Write-Host "GitHub CLI no esta instalado." -ForegroundColor Yellow

    if (Verificar-Comando "winget") {
        Ejecutar-Comando "winget" @(
            "install",
            "--id", "GitHub.cli",
            "-e"
        )
    }

    Write-Host "Cierra PowerShell, abre una nueva ventana y vuelve a ejecutar este script." -ForegroundColor Yellow
    exit
}

git --version
gh --version

# ------------------------------------------------------------
# 3. SINCRONIZAR LOGOTIPO
# ------------------------------------------------------------

Mostrar-Titulo "3. SINCRONIZANDO LOGOTIPO"

if (Test-Path $LogoOriginal) {

    Copy-Item $LogoOriginal $LogoWeb -Force

    $ContenidoHTML = Get-Content $HTML -Raw

    $ContenidoHTML = $ContenidoHTML.Replace(
        "../01_identidad/logotipos/svg/dududev_logo.svg",
        "assets/dududev_logo.svg"
    )

    Set-Content -Path $HTML -Value $ContenidoHTML -Encoding UTF8

    Write-Host "[OK] Logotipo sincronizado." -ForegroundColor Green
}
elseif (!(Test-Path $LogoWeb)) {
    throw "No se encuentra el logotipo original ni su copia en assets."
}
else {
    Write-Host "[OK] Se utilizara el logotipo existente en assets." -ForegroundColor Green
}

# ------------------------------------------------------------
# 4. CREAR GITIGNORE
# ------------------------------------------------------------

Mostrar-Titulo "4. CONFIGURANDO ARCHIVOS"

$GitIgnore = @'
# Archivos temporales
*.tmp
*.log

# Servidor local
.server.pid
05_proyecto_web/logs/

# Entornos Python
.venv/
venv/
__pycache__/

# Sistema operativo
Thumbs.db
.DS_Store
desktop.ini

# Editores
.vscode/
.idea/
'@

Set-Content `
    -Path (Join-Path $Proyecto ".gitignore") `
    -Value $GitIgnore `
    -Encoding UTF8

# ------------------------------------------------------------
# 5. CREAR README
# ------------------------------------------------------------

$Readme = @'
# duduDev

Construyendo soluciones digitales.

## Descripcion

Proyecto de identidad visual y sitio web de duduDev.

Especialidades:
- Desarrollo web
- Programacion
- Automatizacion

## Tecnologias

- HTML5
- CSS3
- JavaScript
- SVG

## Estructura

- `01_identidad`: recursos de marca.
- `02_recursos`: imagenes e iconos.
- `03_aplicaciones`: aplicaciones de identidad.
- `04_documentacion`: manuales y referencias.
- `05_proyecto_web`: sitio web.

## Publicacion

El sitio se publica mediante GitHub Pages y GitHub Actions.
'@

$ReadmePath = Join-Path $Proyecto "README.md"

if (!(Test-Path $ReadmePath)) {
    Set-Content -Path $ReadmePath -Value $Readme -Encoding UTF8
}

# ------------------------------------------------------------
# 6. CREAR WORKFLOW DE GITHUB ACTIONS
# ------------------------------------------------------------

Mostrar-Titulo "5. CONFIGURANDO PUBLICACION AUTOMATICA"

New-Item -ItemType Directory -Path $WorkflowDir -Force | Out-Null

$Workflow = @'
name: Publicar sitio duduDev

on:
  push:
    branches:
      - main
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: github-pages
  cancel-in-progress: true

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}

    runs-on: ubuntu-latest

    steps:
      - name: Descargar repositorio
        uses: actions/checkout@v6

      - name: Configurar GitHub Pages
        uses: actions/configure-pages@v5

      - name: Preparar archivos del sitio
        uses: actions/upload-pages-artifact@v4
        with:
          path: ./05_proyecto_web

      - name: Publicar sitio
        id: deployment
        uses: actions/deploy-pages@v4
'@

Set-Content -Path $WorkflowFile -Value $Workflow -Encoding UTF8

# Evita el procesamiento Jekyll del sitio
New-Item `
    -ItemType File `
    -Path (Join-Path $Web ".nojekyll") `
    -Force | Out-Null

Write-Host "[OK] GitHub Actions configurado." -ForegroundColor Green

# ------------------------------------------------------------
# 7. CONFIGURAR GIT
# ------------------------------------------------------------

Mostrar-Titulo "6. CONFIGURANDO GIT"

Set-Location $Proyecto

if (!(Test-Path (Join-Path $Proyecto ".git"))) {
    Ejecutar-Comando "git" @("init")
}

Ejecutar-Comando "git" @("branch", "-M", "main")

$GitNombre = git config --get user.name 2>$null

if ([string]::IsNullOrWhiteSpace($GitNombre)) {
    $GitNombre = Read-Host "Escribe tu nombre para Git"
    Ejecutar-Comando "git" @("config", "user.name", $GitNombre)
}

$GitEmail = git config --get user.email 2>$null

if ([string]::IsNullOrWhiteSpace($GitEmail)) {
    $GitEmail = Read-Host "Escribe tu correo para Git"
    Ejecutar-Comando "git" @("config", "user.email", $GitEmail)
}

Write-Host "[OK] Identidad de Git configurada." -ForegroundColor Green

# ------------------------------------------------------------
# 8. AUTENTICACION GITHUB
# ------------------------------------------------------------

Mostrar-Titulo "7. AUTENTICANDO GITHUB"

gh auth status 2>$null | Out-Null

if ($LASTEXITCODE -ne 0) {

    Write-Host "Se necesita iniciar sesion en GitHub." -ForegroundColor Yellow

    Ejecutar-Comando "gh" @(
        "auth",
        "login",
        "--hostname", "github.com",
        "--git-protocol", "https",
        "--web",
        "--scopes", "repo,workflow"
    )
}

$UsuarioGitHub = gh api user --jq ".login"

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($UsuarioGitHub)) {
    throw "No se pudo identificar la cuenta de GitHub."
}

Write-Host "Cuenta: $UsuarioGitHub" -ForegroundColor Green

# ------------------------------------------------------------
# 9. CREAR REPOSITORIO
# ------------------------------------------------------------

Mostrar-Titulo "8. CREANDO REPOSITORIO"

$RepositorioCompleto = "$UsuarioGitHub/$RepoNombre"

gh repo view $RepositorioCompleto 2>$null | Out-Null
$RepositorioExiste = ($LASTEXITCODE -eq 0)

if (!$RepositorioExiste) {

    Write-Host "Creando repositorio publico..." -ForegroundColor Yellow

    Ejecutar-Comando "gh" @(
        "repo",
        "create",
        $RepoNombre,
        "--public",
        "--description",
        $Descripcion
    )
}
else {
    Write-Host "[OK] El repositorio ya existe." -ForegroundColor Green
}

# ------------------------------------------------------------
# 10. CONFIGURAR REMOTO
# ------------------------------------------------------------

Mostrar-Titulo "9. CONECTANDO REPOSITORIO"

$URLRepositorio = "https://github.com/$RepositorioCompleto.git"

$Remoto = git remote get-url origin 2>$null

if ($LASTEXITCODE -eq 0 -and $Remoto) {

    if ($Remoto.TrimEnd("/") -ne $URLRepositorio.TrimEnd("/")) {
        throw "El remoto origin apunta a otro repositorio: $Remoto"
    }
}
else {
    Ejecutar-Comando "git" @(
        "remote",
        "add",
        "origin",
        $URLRepositorio
    )
}

Write-Host "[OK] Repositorio remoto configurado." -ForegroundColor Green

# ------------------------------------------------------------
# 11. CONFIGURAR GITHUB PAGES
# ------------------------------------------------------------

Mostrar-Titulo "10. ACTIVANDO GITHUB PAGES"

gh api `
    --method POST `
    "repos/$RepositorioCompleto/pages" `
    -f build_type=workflow 2>$null | Out-Null

$PagesConfigurado = ($LASTEXITCODE -eq 0)

if (!$PagesConfigurado) {

    gh api `
        --method PUT `
        "repos/$RepositorioCompleto/pages" `
        -f build_type=workflow 2>$null | Out-Null

    $PagesConfigurado = ($LASTEXITCODE -eq 0)
}

if ($PagesConfigurado) {
    Write-Host "[OK] GitHub Pages configurado." -ForegroundColor Green
}
else {
    Write-Host "[AVISO] No se pudo configurar Pages mediante API." -ForegroundColor Yellow
    Write-Host "Se indicara como configurarlo manualmente al finalizar."
}

# ------------------------------------------------------------
# 12. GUARDAR CAMBIOS
# ------------------------------------------------------------

Mostrar-Titulo "11. GUARDANDO VERSION"

Ejecutar-Comando "git" @("add", "-A")

$Cambios = git status --porcelain

if ($Cambios) {
    Ejecutar-Comando "git" @(
        "commit",
        "-m",
        "Publicacion inicial de duduDev"
    )
}
else {
    Write-Host "[OK] No hay cambios nuevos que guardar." -ForegroundColor Green
}

# ------------------------------------------------------------
# 13. SUBIR A GITHUB
# ------------------------------------------------------------

Mostrar-Titulo "12. SUBIENDO ARCHIVOS"

Ejecutar-Comando "git" @(
    "push",
    "-u",
    "origin",
    "main"
)

Write-Host "[OK] Archivos enviados a GitHub." -ForegroundColor Green

# ------------------------------------------------------------
# 14. ESPERAR PUBLICACION
# ------------------------------------------------------------

Mostrar-Titulo "13. ESPERANDO PUBLICACION"

Start-Sleep -Seconds 10

$URLWeb = "https://$UsuarioGitHub.github.io/$RepoNombre/"

$RunId = gh run list `
    --repo $RepositorioCompleto `
    --workflow deploy.yml `
    --limit 1 `
    --json databaseId `
    --jq ".[0].databaseId" 2>$null

if ($LASTEXITCODE -eq 0 -and $RunId -and $RunId -ne "null") {

    Write-Host "Esperando resultado de GitHub Actions..." -ForegroundColor Yellow

    gh run watch $RunId `
        --repo $RepositorioCompleto `
        --exit-status

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[AVISO] La publicacion no termino correctamente." -ForegroundColor Yellow
        Write-Host "Revisa la pestaña Actions del repositorio."
    }
}
else {
    Write-Host "[AVISO] Aun no se encuentra una ejecucion de publicacion." -ForegroundColor Yellow
}

# ------------------------------------------------------------
# 15. RESULTADO
# ------------------------------------------------------------

Mostrar-Titulo "PROCESO FINALIZADO"

Write-Host "Repositorio:" -ForegroundColor Cyan
Write-Host "https://github.com/$RepositorioCompleto"

Write-Host ""
Write-Host "Sitio web esperado:" -ForegroundColor Cyan
Write-Host $URLWeb -ForegroundColor Green

Write-Host ""
Write-Host "Si Pages se configuro correctamente y Actions termino," -ForegroundColor Gray
Write-Host "tu sitio estara publicado en esa direccion." -ForegroundColor Gray

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
