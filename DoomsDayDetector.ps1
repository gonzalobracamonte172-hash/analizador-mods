chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# ============================================================
# CONFIGURACIÓN
# ============================================================

$defaultPath = "$env:APPDATA\.minecraft\mods"

$illegalKeywords = @(
    "autototem",
    "freecam",
    "aimbot",
    "killaura",
    "autoclicker",
    "xray",
    "reach",
    "fly",
    "scaffold",
    "criticals",
    "archer",
    "rocket"
)

$suspiciousKeywords = @(
    "autohost",
    "autotoolset",
    "autotten"
)

# ============================================================
# FUNCIONES DE INTERFAZ
# ============================================================

function Show-Header {
n    Clear-Host
n    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                              ║" -ForegroundColor Cyan
    Write-Host "  ║              E L - S O M B R I O             ║" -ForegroundColor Cyan
    Write-Host "  ║                                              ║" -ForegroundColor Cyan
    Write-Host "  ║                 MOD ANALYZER                ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                              ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Progress {
n    param(
        [int]$Current,
        [int]$Total,
        [string]$Text
    )
n    $width = 42
n    if ($Total -le 0) {
        return
    }
n    $percent = [math]::Round(($Current / $Total) * 100)
n    $filled = [math]::Floor(($percent / 100) * $width)
    $empty = $width - $filled
n    $bar = ("█" * $filled) + ("░" * $empty)

    Write-Host "`r  [$bar] $percent%  $Text" -NoNewline -ForegroundColor Cyan
}

# ============================================================
# INICIO
# ============================================================

Show-Header
nWrite-Host "  ANALIZADOR DE MODS" -ForegroundColor White
Write-Host "  ──────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  Verificación mediante hashes y Modrinth." -ForegroundColor DarkGray
Write-Host ""

$modsPath = Read-Host "  Ruta de la carpeta de mods [Enter = predeterminada]"
nif ([string]::IsNullOrWhiteSpace($modsPath)) {
    $modsPath = $defaultPath
}
nif (-not (Test-Path $modsPath)) {
n    Write-Host ""
    Write-Host "  ✕ No se encontró la carpeta." -ForegroundColor Red
    Write-Host ""
    Write-Host "    $modsPath" -ForegroundColor DarkGray
    Write-Host ""
n    Read-Host "  Pulsa Enter para salir"
    exit
}

$jars = @(Get-ChildItem -Path $modsPath -Filter *.jar -File)
nif ($jars.Count -eq 0) {
n    Write-Host ""
    Write-Host "  ! No se encontraron archivos .jar." -ForegroundColor Yellow
    Write-Host ""
n    Read-Host "  Pulsa Enter para salir"
    exit
}

# ============================================================
# INFORMACIÓN DEL ESCANEO
# ============================================================

Show-Header

Write-Host "  ESCANEO PREPARADO" -ForegroundColor White
Write-Host "  ──────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  Carpeta" -ForegroundColor DarkGray
Write-Host "  $modsPath" -ForegroundColor White
Write-Host ""

Write-Host "  Archivos encontrados : " -NoNewline -ForegroundColor DarkGray
Write-Host "$($jars.Count)" -ForegroundColor Cyan

Write-Host ""
Write-Host "  Iniciando análisis..." -ForegroundColor DarkGray

Start-Sleep -Milliseconds 700

# ============================================================
# PASO 1 - HASHES
# ============================================================

Show-Header

Write-Host "  ANALIZANDO MODS" -ForegroundColor White
Write-Host "  ──────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  PASO 1 / 3" -ForegroundColor Cyan
Write-Host "  Calculando hashes SHA1..." -ForegroundColor DarkGray
Write-Host ""

$hashMap = @{}
$i = 0

foreach ($jar in $jars) {
n    $i++

    $hash = (
        Get-FileHash `
        -Path $jar.FullName `
        -Algorithm SHA1
    ).Hash.ToLower()

    $hashMap[$hash] = $jar

    Show-Progress `
        -Current $i `
        -Total $jars.Count `
        -Text "Procesando archivos"
}

Write-Host ""
Write-Host ""
Write-Host "  ✓ Hashes completados" -ForegroundColor Green

Start-Sleep -Milliseconds 500

# ============================================================
# PASO 2 - MODRINTH
# ============================================================

Show-Header

Write-Host "  ANALIZANDO MODS" -ForegroundColor White
Write-Host "  ──────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  PASO 2 / 3" -ForegroundColor Cyan
Write-Host "  Consultando Modrinth..." -ForegroundColor DarkGray
Write-Host ""

$modrinthData = @{}
ntry {
n    $body = @{
        hashes = @($hashMap.Keys)
        algorithm = "sha1"
    } | ConvertTo-Json
n    $modrinthData = Invoke-RestMethod `
        -Uri "https://api.modrinth.com/v2/version_files" `
        -Method Post `
        -Body $body `
        -ContentType "application/json"
n    Write-Host "  ✓ Base de datos consultada correctamente" -ForegroundColor Green
} catch {
n    Write-Host "  ! No se pudo conectar a Modrinth" -ForegroundColor Yellow
    Write-Host "    Se continuará con el análisis local." -ForegroundColor DarkGray
}

Start-Sleep -Milliseconds 700

# ============================================================
# PASO 3 - CLASIFICACIÓN
# ============================================================

Show-Header

Write-Host "  ANALIZANDO MODS" -ForegroundColor White
Write-Host "  ──────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  PASO 3 / 3" -ForegroundColor Cyan
Write-Host "  Clasificando archivos..." -ForegroundColor DarkGray
Write-Host ""

$modList = @()
$i = 0
total = $hashMap.Count

foreach ($h in $hashMap.Keys) {
n    $i++

    $jar = $hashMap[$h]
    $info = $modrinthData.$h
n    $nameForCheck = $jar.BaseName.ToLower()
n    if ($info) {
n        $displayName = "$($info.name) (v$($info.version_number))"
        $estado = "VERIFICADO"
    }
    else {
n        $displayName = $jar.BaseName
        $estado = "NO IDENTIFICADO"
    }
n    $matchIllegal = $illegalKeywords |
        Where-Object {
            $nameForCheck -like "*$_*"
        }
n    $matchSuspicious = $suspiciousKeywords |
        Where-Object {
            $nameForCheck -like "*$_*"
        }
n    if ($matchIllegal) {
n        $categoria = "ILEGAL"
        $color = "Red"
    }
    elseif ($matchSuspicious) {
n        $categoria = "SOSPECHOSO"
        $color = "Yellow"
    }
    else {
n        $categoria = "NORMAL"
        $color = "Green"
    }
n    $modList += [PSCustomObject]@{
        DisplayName = $displayName
        Estado      = $estado
        Archivo     = $jar.Name
        Categoria   = $categoria
        Color       = $color
    }
n    Show-Progress `
        -Current $i `
        -Total $total `
        -Text "Clasificando mods"
}

# ============================================================
# ARCHIVOS CAMUFLADOS
# ============================================================

Get-ChildItem -Path $modsPath -File |
    Where-Object {
        $_.Extension -ne ".jar" -and
        $_.BaseName.ToLower() -like "*autoclick*"
    } |
    ForEach-Object {
n        $modList += [PSCustomObject]@{
            DisplayName = $_.BaseName
            Estado      = "ARCHIVO CAMUFLADO"
            Archivo     = $_.Name
            Categoria   = "ILEGAL"
            Color       = "Magenta"
        }
    }
nWrite-Host ""
Write-Host ""
Write-Host "  ✓ Clasificación completada" -ForegroundColor Green

Start-Sleep -Milliseconds 800

# ============================================================
# RESULTADOS
# ============================================================

Show-Header

$modListSorted = @(
    $modList | Sort-Object DisplayName
)
n$illegalCount = @(
    $modListSorted |
    Where-Object {
        $_.Categoria -eq "ILEGAL"
    }
).Count

$suspiciousCount = @(
    $modListSorted |
    Where-Object {
        $_.Categoria -eq "SOSPECHOSO"
    }
).Count

$normalCount = @(
    $modListSorted |
    Where-Object {
        $_.Categoria -eq "NORMAL"
    }
).Count

# ============================================================
# RESUMEN
# ============================================================

Write-Host "  RESULTADOS DEL ANALISIS" -ForegroundColor White
Write-Host "  ──────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  TOTAL        : " -NoNewline -ForegroundColor DarkGray
Write-Host "$($modListSorted.Count)" -ForegroundColor Cyan

Write-Host "  ILEGALES     : " -NoNewline -ForegroundColor DarkGray
Write-Host "$illegalCount" -ForegroundColor Red

Write-Host "  SOSPECHOSOS  : " -NoNewline -ForegroundColor DarkGray
Write-Host "$suspiciousCount" -ForegroundColor Yellow

Write-Host "  NORMALES     : " -NoNewline -ForegroundColor DarkGray
Write-Host "$normalCount" -ForegroundColor Green

Write-Host ""

# ============================================================
# LISTA DE RESULTADOS
# ============================================================

Write-Host "  MODS ENCONTRADOS" -ForegroundColor Cyan
Write-Host ""

foreach ($m in $modListSorted) {
n    switch ($m.Categoria) {
n        "ILEGAL" {
            $symbol = "✕"
        }
n        "SOSPECHOSO" {
            $symbol = "!"
        }
n        default {
            $symbol = "✓"
        }
    }
n    Write-Host "  $symbol " -NoNewline -ForegroundColor $m.Color
    Write-Host "$($m.DisplayName)" -ForegroundColor White
n    Write-Host "      Estado : " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($m.Estado)" -ForegroundColor $m.Color
n    Write-Host "      Archivo: " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($m.Archivo)" -ForegroundColor DarkGray
n    Write-Host ""
}

# ============================================================
# GUARDADO
# ============================================================

$outFile = Join-Path `
    (Split-Path $modsPath -Parent) `
    "analisis_mods.txt"

$outContent = $modListSorted |
    ForEach-Object {
        "[$($_.Categoria)] $($_.DisplayName) - $($_.Estado) - $($_.Archivo)"
    }

$outContent |
    Out-File `
    -FilePath $outFile `
    -Encoding utf8

# ============================================================
# ESTADO FINAL
# ============================================================

Write-Host "  ──────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

if ($illegalCount -gt 0) {
n    Write-Host "  ⚠ SE DETECTARON $illegalCount MOD(S) ILEGAL(ES)" -ForegroundColor Red
}
elseif ($suspiciousCount -gt 0) {
n    Write-Host "  ! SE DETECTARON $suspiciousCount MOD(S) SOSPECHOSO(S)" -ForegroundColor Yellow
}
else {
n    Write-Host "  ✓ NO SE DETECTARON MODS ILEGALES" -ForegroundColor Green
}

Write-Host ""
Write-Host "  Reporte guardado en:" -ForegroundColor DarkGray
Write-Host "  $outFile" -ForegroundColor Cyan
Write-Host ""

Write-Host "  ══════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host "                 ANALISIS FINALIZADO" -ForegroundColor Cyan
Write-Host "  ══════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""

Read-Host "  Pulsa Enter para cerrar"
