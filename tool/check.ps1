# Verificación automática del proyecto.
# Uso:
#   powershell -ExecutionPolicy Bypass -File tool/check.ps1
#   powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/proveedores/*"
param(
  [string[]]$ArchivosPermitidos = @()
)

$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

$env:Path = "D:\flutter\bin;$env:Path"
$env:PUB_CACHE = "D:\dev-cache\pub"
$env:GRADLE_USER_HOME = "D:\dev-cache\gradle"

function Paso($titulo) {
  Write-Host "`n==> $titulo" -ForegroundColor Cyan
}

# 1. Si se indicaron archivos permitidos, verificar que no se haya tocado nada fuera de esa lista.
if ($ArchivosPermitidos.Count -gt 0) {
  Paso "Control de archivos modificados"
  $tocados = @(git status --porcelain | ForEach-Object { $_.Substring(3).Trim() -replace '\\', '/' })
  foreach ($f in $tocados) {
    $ok = $false
    foreach ($patron in $ArchivosPermitidos) {
      $p = $patron -replace '\\', '/'
      if ($f -like $p) { $ok = $true; break }
    }
    if (-not $ok) {
      Write-Host "ERROR: archivo fuera del alcance de la tarea: $f" -ForegroundColor Red
      Write-Host "Permitidos: $($ArchivosPermitidos -join ', ')" -ForegroundColor Yellow
      exit 1
    }
  }
  Write-Host "OK ($($tocados.Count) archivo(s) dentro del alcance)" -ForegroundColor Green
}

# 2. Pruebas del esquema SQL (si existen)
if (Test-Path "$raiz/tool/sql-test/run.mjs") {
  Paso "Pruebas del esquema SQL (PGlite)"
  Push-Location "$raiz/tool/sql-test"
  node run.mjs
  if ($LASTEXITCODE -ne 0) { Pop-Location; exit 1 }
  Pop-Location
}

# 3. Flutter (cuando exista la carpeta app/)
if (Test-Path "$raiz/app/pubspec.yaml") {
  Push-Location "$raiz/app"

  Paso "Formato (dart format)"
  dart format --output=none --set-exit-if-changed lib test
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Ejecutando 'dart format lib test' para corregir el formato..." -ForegroundColor Yellow
    dart format lib test
  }

  Paso "Análisis estático (flutter analyze)"
  flutter analyze --no-pub
  if ($LASTEXITCODE -ne 0) { Pop-Location; exit 1 }

  Paso "Tests (flutter test)"
  flutter test --no-pub
  if ($LASTEXITCODE -ne 0) { Pop-Location; exit 1 }

  Pop-Location
}

Write-Host "`nTODO OK" -ForegroundColor Green
