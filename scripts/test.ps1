#Requires -Version 7.0
<#
  test.ps1 — Windows equivalent of `make check` (lint + headless tests).

  Usage:
    .\scripts\test.ps1            lint + tests
    .\scripts\test.ps1 -Lint      luacheck only
    .\scripts\test.ps1 -Test      busted only
#>
param(
  [switch]$Lint,
  [switch]$Test
)

$ErrorActionPreference = "Stop"
$RockBin = Join-Path $env:APPDATA "luarocks\bin"
$Luacheck = Join-Path $RockBin "luacheck.bat"
$Busted   = Join-Path $RockBin "busted.bat"

$sys  = [Environment]::GetEnvironmentVariable("Path", "Machine")
$user = [Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$sys;$user;$RockBin"
$env:TMP = "C:\tools\tmp"; $env:TEMP = "C:\tools\tmp"

$doLint = $Lint -or (-not $Test)
$doTest = $Test -or (-not $Lint)

if ($doLint) {
  Write-Host "[check] luacheck src tests" -ForegroundColor Cyan
  & $Luacheck src tests
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if ($doTest) {
  Write-Host "[check] busted tests/spec" -ForegroundColor Cyan
  & $Busted tests/spec
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "[check] done" -ForegroundColor Green