# DoomsDayDetector — Analizador de mods

Pequeña utilidad en PowerShell para analizar la carpeta de mods de Minecraft: calcula hashes SHA1, consulta la base de datos pública de Modrinth para identificar mods y clasifica archivos como ILEGAL / SOSPECHOSO / NORMAL según patrones en el nombre.

IMPORTANTE de seguridad
- No ejecutes scripts desde Internet sin revisarlos antes. El comando "one-liner" ejecuta el script directamente y es menos seguro.
- Recomendado: descargar, abrir y revisar el script localmente antes de ejecutar.

Requisitos
- Windows con PowerShell (5.1 o PowerShell 7+).
- Conexión a Internet para las consultas a Modrinth (opcional: el script sigue funcionando parcialmente sin conexión).

Archivos
- DoomsDayDetector.ps1 — script principal.

Uso (más seguro — descargar y revisar)
1. Descargar el script:
   powershell -NoProfile -ExecutionPolicy Bypass -Command "iwr -useb 'https://raw.githubusercontent.com/gonzalobracamonte172-hash/analizador-mods/main/DoomsDayDetector.ps1' -OutFile .\DoomsDayDetector.ps1'"
2. Abrir y revisar:
   notepad .\DoomsDayDetector.ps1
3. Ejecutar:
   powershell -NoProfile -ExecutionPolicy Bypass -File .\DoomsDayDetector.ps1

One-liner (ejecuta sin revisar — MENOS SEGURO)
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (iwr -useb 'https://raw.githubusercontent.com/gonzalobracamonte172-hash/analizador-mods/main/DoomsDayDetector.ps1')"

