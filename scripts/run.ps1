#Requires -Version 7.0
<#
  run.ps1 — run the game with LÖVE on Windows.
#>
$ErrorActionPreference = "Stop"
$Love = Join-Path $env:LOCALAPPDATA "Programs\LOVE\love.exe"
if (-not (Test-Path $Love)) {
  Write-Host "love.exe not found. Run .\scripts\bootstrap.ps1 first." -ForegroundColor Red
  exit 1
}
$Repo = Split-Path -Parent $PSScriptRoot
Write-Host "running game ... (ESC to quit)" -ForegroundColor Cyan
& $Love $Repo