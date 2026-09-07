chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Clear-Host

# ============================================================
# EL-SOMBRIO FORENSIC SCANNER
# ============================================================

$script:DefaultModsPath = "$env:APPDATA\.minecraft\mods"

$script:IllegalKeywords = @(
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

$script:SuspiciousKeywords = @(
    "autohost",
    "autotoolset",
    "autototten"
)

# ============================================================
# ESTADÍSTICAS
# ============================================================

$script:ScanInfo = [ordered]@{
    ModsAnalizados       = 0
    ModsNormales         = 0
    ModsSospechosos      = 0
    ModsIlegales         = 0
    ArchivosCamuflados   = 0

    DrivesAnalizados     = 0
    EXEEncontrados       = 0
    DLLEncontradas       = 0
    JAREncontrados       = 0

    JARAnalizados        = 0
    JARSospechosos       = 0
    FirmasDetectadas     = 0

    ServiciosRunning       = 0
    ServiciosStopped       = 0
    ServiciosNoEncontrados = 0
}

# ============================================================
# SERVICIOS A COMPROBAR
# ============================================================

$script:WindowsServices = @(
    "dps",
    "appinfo",
    "pcasvc",
    "eventlog",
    "sysmain",
    "dusmsvc",
    "bam"
)

# ============================================================
# UTILIDADES
# ============================================================

function Pause-Scanner {
    Write-Host ""
    Write-Host "  Presiona ENTER para continuar..." -ForegroundColor DarkGray
    Read-Host
}

function Show-Line {
    Write-Host "  ----------------------------------------------------------------" -ForegroundColor DarkGray
}

function Show-Title {
    param(
        [string]$Title
    )

    Clear-Host

    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host ("  ║{0,-62}║" -f $Title) -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Test-Administrator {
n    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
n    return $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Get-FileSHA1 {
    param(
        [string]$Path
    )

    try {
        return (Get-FileHash -Algorithm SHA1 -LiteralPath $Path).Hash
    }
    catch {
        return $null
    }
}

# ============================================================
# REINICIAR ESTADÍSTICAS
# ============================================================

function Reset-ScanInfo {
n    $script:ScanInfo.ModsAnalizados       = 0
    $script:ScanInfo.ModsNormales        = 0
    $script:ScanInfo.ModsSospechosos     = 0
    $script:ScanInfo.ModsIlegales        = 0
    $script:ScanInfo.ArchivosCamuflados  = 0
n    $script:ScanInfo.DrivesAnalizados    = 0
    $script:ScanInfo.EXEEncontrados      = 0
    $script:ScanInfo.DLLEncontradas      = 0
    $script:ScanInfo.JAREncontrados      = 0
n    $script:ScanInfo.JARAnalizados       = 0
    $script:ScanInfo.JARSospechosos      = 0
    $script:ScanInfo.FirmasDetectadas    = 0
n    $script:ScanInfo.ServiciosRunning       = 0
    $script:ScanInfo.ServiciosStopped       = 0
    $script:ScanInfo.ServiciosNoEncontrados = 0
}

# ============================================================
# SERVICIOS WINDOWS
# ============================================================

function Get-WindowsServiceStatus {
    $results = @()
    $script:ScanInfo.ServiciosRunning       = 0
    $script:ScanInfo.ServiciosStopped       = 0
    $script:ScanInfo.ServiciosNoEncontrados = 0
    foreach ($service in $script:WindowsServices) {
        # sc.exe se ejecuta dentro de la misma terminal PowerShell
        $output = @(
            & sc.exe query $service 2>&1
        )
        $text = ($output -join "`n")
        $state = "DESCONOCIDO"
        if ($text -match '(?im)^\s*(ESTADO|STATE)\s*:\s*4\s+RUNNING') {
            $state = "RUNNING"
            $script:ScanInfo.ServiciosRunning++
        }
        elseif ($text -match '(?im)^\s*(ESTADO|STATE)\s*:\s*1\s+STOPPED') {
            $state = "STOPPED"
            $script:ScanInfo.ServiciosStopped++
        }
        elseif ($text -match '1060') {
            $state = "NO ENCONTRADO"
            $script:ScanInfo.ServiciosNoEncontrados++
        }
        $results += [PSCustomObject]@{
            Nombre = $service
            Estado = $state
            Raw    = $output
        }
    }
    return $results
}

# ============================================================
# INTERFAZ DIRECTA: SERVICIOS WINDOWS
# ============================================================

function Show-WindowsServices {
    Show-Title "SERVICIOS WINDOWS"
    $services = Get-WindowsServiceStatus
    Write-Host "  RESUMEN" -ForegroundColor Cyan
    Show-Line
    Write-Host ""
    Write-Host "  - RUNNING       : $($script:ScanInfo.ServiciosRunning)" -ForegroundColor Green
    Write-Host "  - STOPPED       : $($script:ScanInfo.ServiciosStopped)" -ForegroundColor Yellow
    Write-Host "  - NO ENCONTRADO : $($script:ScanInfo.ServiciosNoEncontrados)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  ESTADO DE SERVICIOS" -ForegroundColor Cyan
    Show-Line
    foreach ($service in $services) {
        switch ($service.Estado) {
            "RUNNING" {
                $color = "Green"
            }
            "STOPPED" {
                $color = "Yellow"
            }
            "NO ENCONTRADO" {
                $color = "Red"
            }
            default {
                $color = "Gray"
            }
        }
        Write-Host ""
        Write-Host "  - $($service.Nombre)" -ForegroundColor White
        Write-Host "      ESTADO : $($service.Estado)" -ForegroundColor $color
    }
    Write-Host ""
    Show-Line
    Write-Host ""
    Write-Host "  INFORMACIÓN COMPLETA DE SC QUERY" -ForegroundColor Cyan
    Show-Line
    foreach ($service in $services) {
        Write-Host ""
        Write-Host "  ╔─ - $($service.Nombre)" -ForegroundColor Yellow
        foreach ($line in $service.Raw) {
            if ([string]::IsNullOrWhiteSpace($line)) {                continue
            }
            Write-Host "  ║  $($line.ToString().TrimEnd())" -ForegroundColor White
        }
        Write-Host "  ╚──────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "  La información fue obtenida con sc.exe desde esta terminal." -ForegroundColor DarkGray
    Write-Host "  No se abrió ninguna ventana CMD." -ForegroundColor DarkGray
    Pause-Scanner
}

# ============================================================
# TABLA GENERAL
# ============================================================

function Show-InformationTable {
    Show-Title "TABLA DE INFORMACIÓN"
    Write-Host "  MODS" -ForegroundColor Cyan
    Show-Line
    Write-Host "  - Mods analizados       : $($script:ScanInfo.ModsAnalizados)"
    Write-Host "  - Mods normales         : $($script:ScanInfo.ModsNormales)"
    Write-Host "  - Mods sospechosos      : $($script:ScanInfo.ModsSospechosos)"
    Write-Host "  - Mods ilegales         : $($script:ScanInfo.ModsIlegales)"
    Write-Host "  - Archivos camuflados   : $($script:ScanInfo.ArchivosCamuflados)"
    Write-Host ""
    Write-Host "  DOOMSDAY" -ForegroundColor Cyan
    Show-Line
    Write-Host "  - Drives analizados     : $($script:ScanInfo.DrivesAnalizados)"
    Write-Host "  - EXE encontrados       : $($script:ScanInfo.EXEEncontrados)"
    Write-Host "  - DLL encontradas       : $($script:ScanInfo.DLLEncontradas)"
    Write-Host "  - JAR encontrados       : $($script:ScanInfo.JAREncontrados)"
    Write-Host "  - JAR analizados        : $($script:ScanInfo.JARAnalizados)"
    Write-Host "  - JAR sospechosos       : $($script:ScanInfo.JARSospechosos)"
    Write-Host "  - Firmas detectadas     : $($script:ScanInfo.FirmasDetectadas)"
    Write-Host ""
    Write-Host "  SERVICIOS WINDOWS" -ForegroundColor Cyan
    Show-Line
    Write-Host "  - RUNNING              : $($script:ScanInfo.ServiciosRunning)" -ForegroundColor Green
    Write-Host "  - STOPPED              : $($script:ScanInfo.ServiciosStopped)" -ForegroundColor Yellow
    Write-Host "  - NO ENCONTRADOS       : $($script:ScanInfo.ServiciosNoEncontrados)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Servicios comprobados:" -ForegroundColor Gray
    foreach ($service in $script:WindowsServices) {
        Write-Host "  - $service" -ForegroundColor White
    }
    Pause-Scanner
}

# ============================================================
# ANALIZAR MODS
# ============================================================

function Start-ModScan {
    Show-Title "ANÁLISIS DE MODS"
    $modsPath = Read-Host "  Ruta de mods [$($script:DefaultModsPath)]"
    if ([string]::IsNullOrWhiteSpace($modsPath)) {
        $modsPath = $script:DefaultModsPath
    }
    if (-not (Test-Path -LiteralPath $modsPath)) {
        Write-Host ""
        Write-Host "  [!] La carpeta no existe." -ForegroundColor Red
        Pause-Scanner
        return
    }
    $jars = @(Get-ChildItem -LiteralPath $modsPath -Filter "*.jar" -File -ErrorAction SilentlyContinue)
    if ($jars.Count -eq 0) {
        Write-Host ""
        Write-Host "  [!] No se encontraron archivos JAR." -ForegroundColor Yellow
        Pause-Scanner
        return
    }
    $script:ScanInfo.ModsAnalizados = $jars.Count
    Write-Host ""
    Write-Host "  Mods encontrados: $($jars.Count)" -ForegroundColor Cyan
    Write-Host ""
    foreach ($jar in $jars) {
        $name = $jar.BaseName.ToLower()
        $illegal = $false
        $suspicious = $false
        foreach ($keyword in $script:IllegalKeywords) {
            if ($name -like "*$keyword*") {
                $illegal = $true
                break
            }
        }
        if (-not $illegal) {
            foreach ($keyword in $script:SuspiciousKeywords) {
                if ($name -like "*$keyword*") {
                    $suspicious = $true
                    break
                }
            }
        }
        if ($illegal) {
            $script:ScanInfo.ModsIlegales++
            Write-Host "  X " -NoNewline -ForegroundColor Red
            Write-Host "- $($jar.Name)" -ForegroundColor White
        }
        elseif ($suspicious) {
            $script:ScanInfo.ModsSospechosos++
            Write-Host "  ! " -NoNewline -ForegroundColor Yellow
            Write-Host "- $($jar.Name)" -ForegroundColor White
        }
        else {
            $script:ScanInfo.ModsNormales++
            Write-Host "  + " -NoNewline -ForegroundColor Green
            Write-Host "- $($jar.Name)" -ForegroundColor White
        }
    }
    # Archivos que intentan parecer mods pero no son JAR
    $otherFiles = @(
        Get-ChildItem -LiteralPath $modsPath -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Extension -ne ".jar" -and
            $_.BaseName -match "autoclick"
        }
    )
    $script:ScanInfo.ArchivosCamuflados = $otherFiles.Count
    foreach ($file in $otherFiles) {
        Write-Host "  ! " -NoNewline -ForegroundColor Yellow
        Write-Host "- $($file.Name) [CAMUFLADO]" -ForegroundColor White
    }
    $report = Join-Path $modsPath "analisis_mods.txt"
    @(
        "EL-SOMBRIO FORENSIC SCANNER"
        "ANÁLISIS DE MODS"
        "============================"
        ""
        "Mods analizados      : $($script:ScanInfo.ModsAnalizados)"
        "Mods normales        : $($script:ScanInfo.ModsNormales)"
        "Mods sospechosos     : $($script:ScanInfo.ModsSospechosos)"
        "Mods ilegales        : $($script:ScanInfo.ModsIlegales)"
        "Archivos camuflados  : $($script:ScanInfo.ArchivosCamuflados)"
        ""
        "ARCHIVOS:"
    ) | Out-File -FilePath $report -Encoding UTF8
    foreach ($jar in $jars) {
        "- $($jar.Name)" | Out-File -FilePath $report -Append -Encoding UTF8
    }
    Write-Host ""
    Write-Host "  [OK] Análisis terminado." -ForegroundColor Green
    Write-Host "  [OK] Reporte: $report" -ForegroundColor Gray
    Pause-Scanner
}

# ============================================================
# FIRMAS DOOMSDAY
# ============================================================

$script:KnownHexPatterns = @(
    "6161370E160609949E0029033EA7000A2C1D03548403011D1008A1FFF6033EA7000A2B1D03548403011D07A1FFF710FEAC150599001A2A160C14005C6588B800",
    "0C1504851D85160A6161370E160609949E0029033EA7000A2C1D03548403011D1008A1FFF6033EA7000A2B1D03548403011D07A1FFF710FEAC150599001A2A16",
    "5910071088544C2A2BB8004D3B033DA7000A2B1C03548402011C1008A1FFF61A9E000C1A110800A2000503AC04AC00000000000A0005004E000101FA000001D3"
)

$script:KnownClassPatterns = @(
    "net/java/f",
    "net/java/g",
    "net/java/h",
    "net/java/i",
    "net/java/k",
    "net/java/l",
    "net/java/m",
    "net/java/r",
    "net/java/s",
    "net/java/t",
    "net/java/y"
)

function ConvertHex-ToBytes {
    param(
        [string]$Hex
    )
    $bytes = New-Object byte[] ($Hex.Length / 2)
    for ($i = 0; $i -lt $Hex.Length; $i += 2) {
        $bytes[$i / 2] = [Convert]::ToByte(
            $Hex.Substring($i, 2),
            16
        )
    }
    return $bytes
}

function Search-BytePattern {
    param(
        [byte[]]$Data,
        [byte[]]$Pattern
    )
    if ($Pattern.Length -gt $Data.Length) {
        return $false
    }
    for ($i = 0; $i -le ($Data.Length - $Pattern.Length); $i++) {
        $match = $true
        for ($j = 0; $j -lt $Pattern.Length; $j++) {
            if ($Data[$i + $j] -ne $Pattern[$j]) {
                $match = $false
                break
            }
        }
        if ($match) {
            return $true
        }
    }
    return $false
}

function Search-ClassPattern {
    param(
        [byte[]]$Data,
        [string]$Pattern
    )
    $text = [System.Text.Encoding]::ASCII.GetString($Data)
    return $text.Contains($Pattern)
}

function Test-DoomsdayJar {
    param(
        [string]$Path
    )
    try {        $data = [System.IO.File]::ReadAllBytes($Path)
    }
    catch {        return $false
    }
    $byteMatches = 0
    $classMatches = 0
    foreach ($hex in $script:KnownHexPatterns) {
        $pattern = ConvertHex-ToBytes $hex
        if (Search-BytePattern -Data $data -Pattern $pattern) {
            $byteMatches++
        }
    }
    foreach ($class in $script:KnownClassPatterns) {
        if (Search-ClassPattern -Data $data -Pattern $class) {
            $classMatches++
        }
    }
    if ($byteMatches -ge 2) {
        return $true
    }
    if ($byteMatches -ge 1 -and $classMatches -ge 5) {
        return $true
    }
    if ($classMatches -ge 8) {
        return $true
    }
    return $false
}

# ============================================================
# DRIVES
# ============================================================

function Get-ScanDrives {
    return @(
        Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
        Select-Object -ExpandProperty DeviceID
    )
}

# ============================================================
# DOOMSDAY SCANNER
# ============================================================

function Start-DoomsdayScan {
    Show-Title "DOOMSDAY SCANNER"
    $drives = @(Get-ScanDrives)
    if ($drives.Count -eq 0) {
        Write-Host "  [!] No se encontraron unidades." -ForegroundColor Red
        Pause-Scanner
        return
    }
    Write-Host "  Unidades detectadas:" -ForegroundColor Cyan
    Write-Host ""
    foreach ($drive in $drives) {
        Write-Host "  - $drive" -ForegroundColor White
    }
    Write-Host ""
    foreach ($drive in $drives) {
        $script:ScanInfo.DrivesAnalizados++
        Write-Host "  Escaneando $drive ..." -ForegroundColor Cyan
        try {            $files = Get-ChildItem -Path "$drive\" -File -Recurse -Force -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                switch ($file.Extension.ToLower()) {
                    ".exe" {                        $script:ScanInfo.EXEEncontrados++                    }
                    ".dll" {
