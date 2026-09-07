# Add 'dd' function to PowerShell profile (download & run / or open for review)
if (!(Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}
$function = @'
function dd {
    param([switch]$check)
    if ($check) {
        iwr -useb 'https://raw.githubusercontent.com/gonzalobracamonte172-hash/analizador-mods/main/DoomsDayDetector.ps1' -OutFile "$env:USERPROFILE\DoomsDayDetector.ps1"
        notepad "$env:USERPROFILE\DoomsDayDetector.ps1"
    }
    else {
        iex (iwr -useb 'https://raw.githubusercontent.com/gonzalobracamonte172-hash/analizador-mods/main/DoomsDayDetector.ps1')
    }
}
'@
Add-Content -Path $PROFILE -Value $function
Write-Host "Function 'dd' added to your profile. Run '. $PROFILE' or restart PowerShell to use it." -ForegroundColor Green
