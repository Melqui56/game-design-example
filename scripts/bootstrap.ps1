#Requires -Version 7.0
<#
  bootstrap.ps1 — provision the local environment for the game project on Windows.

  Usage:
    .\scripts\bootstrap.ps1            detect, install what's missing, verify.
    .\scripts\bootstrap.ps1 -Check     only verify the environment, change nothing.

  Idempotent: safe to run any number of times.

  Windows is installed into %LOCALAPPDATA%\Programs (no admin required) and
  C:\tools for the toolchain bits that must live on a path without spaces
  (LuaRocks + GCC have issues with %TMP% paths containing spaces).
#>
param(
  [switch]$Check
)

$ErrorActionPreference = "Stop"

function Info($msg) { Write-Host "[bootstrap] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[bootstrap] $msg" -ForegroundColor Yellow }
function Err($msg)  { Write-Host "[bootstrap] $msg" -ForegroundColor Red }

$InstallRoot = Join-Path $env:LOCALAPPDATA "Programs"
$ToolsRoot   = "C:\tools"
$TmpRoot     = Join-Path $ToolsRoot "tmp"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Test-Command($name) {
  return (Get-Command $name -ErrorAction SilentlyContinue) -ne $null
}

function Add-UserPath($dir) {
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ($userPath -split ';' -notcontains $dir) {
    $new = if ([string]::IsNullOrEmpty($userPath)) { $dir } else { "$userPath;$dir" }
    [Environment]::SetEnvironmentVariable("Path", $new, "User")
    Info "added to user PATH: $dir"
  }
}

function Ensure-NoSpaceTmp {
  # LuaRocks/GCC fail with "Access denied" when %TMP% contains spaces (e.g.
  # "C:\Users\Verzion 360\..."). Point TMP/TEMP at a space-free path for the
  # duration of this process and persist it for the user.
  New-Item -ItemType Directory -Force -Path $TmpRoot | Out-Null
  $env:TMP = $TmpRoot
  $env:TEMP = $TmpRoot
  [Environment]::SetEnvironmentVariable("TMP", $TmpRoot, "User")
  [Environment]::SetEnvironmentVariable("TEMP", $TmpRoot, "User")
}

function Refresh-SessionPath {
  $sys  = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $user = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$sys;$user"
}

function Get-Url($url, $outFile) {
  if (Test-Path $outFile) { return }
  Warn "downloading $url"
  curl.exe -L --max-time 300 -o $outFile $url
  if ($LASTEXITCODE -ne 0) { Err "download failed: $url"; exit 1 }
}

function Expand-Zip($zip, $dest) {
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  Expand-Archive -Path $zip -DestinationPath $dest -Force
}

# ---------------------------------------------------------------------------
# Installers
# ---------------------------------------------------------------------------

function Install-Love {
  $loveDir = Join-Path $InstallRoot "LOVE"
  if (Test-Path (Join-Path $loveDir "love.exe")) {
    Info "love: already installed"
    return
  }
  $zip = Join-Path $env:TEMP "love.zip"
  Get-Url "https://github.com/love2d/love/releases/download/11.5/love-11.5-win64.zip" $zip
  $tmp = Join-Path $InstallRoot "love_tmp"
  Expand-Zip $zip $tmp
  $inner = Get-ChildItem $tmp -Directory | Select-Object -First 1
  if (Test-Path $loveDir) { Remove-Item $loveDir -Recurse -Force }
  Move-Item $inner.FullName $loveDir
  Remove-Item $tmp -Recurse -Force
  Info "love: installed to $loveDir"
}

function Install-Lua54 {
  $luaDir = Join-Path $InstallRoot "Lua54"
  if (Test-Path (Join-Path $luaDir "lua.exe")) {
    Info "lua 5.4: already installed"
    return
  }
  $zip = Join-Path $env:TEMP "lua54.zip"
  Get-Url "https://github.com/joedf/LuaBuilds/raw/gh-pages/hdata/lua-5.4.7_Win64_bin.zip" $zip
  New-Item -ItemType Directory -Force -Path $luaDir | Out-Null
  Expand-Archive -Path $zip -DestinationPath $luaDir -Force
  Info "lua 5.4: installed to $luaDir"
}

function Install-LuaHeaders {
  $incDir = Join-Path $ToolsRoot "lua54_include"
  if (Test-Path (Join-Path $incDir "lua.h")) {
    Info "lua headers: already present"
    return
  }
  $tgz = Join-Path $env:TEMP "lua54-src.tar.gz"
  Get-Url "https://www.lua.org/ftp/lua-5.4.7.tar.gz" $tgz
  $src = Join-Path $env:TEMP "lua54src"
  New-Item -ItemType Directory -Force -Path $src | Out-Null
  tar -xzf $tgz -C $src
  $hSrc = Join-Path $src "lua-5.4.7\src"
  New-Item -ItemType Directory -Force -Path $incDir | Out-Null
  Copy-Item (Join-Path $hSrc "lua.h"),(Join-Path $hSrc "luaconf.h"),(Join-Path $hSrc "lauxlib.h"),(Join-Path $hSrc "lualib.h") $incDir -Force
  Info "lua headers: installed to $incDir"
}

function Install-LuaRocks {
  $lrDir = Join-Path $InstallRoot "LuaRocks"
  $lrExe = Join-Path $lrDir "luarocks.exe"
  if (Test-Path $lrExe) {
    Info "luarocks: already installed"
    return
  }
  $zip = Join-Path $env:TEMP "luarocks.zip"
  Get-Url "https://github.com/luarocks/luarocks/releases/download/v3.11.1/luarocks-3.11.1-windows-64.zip" $zip
  Expand-Zip $zip $lrDir
  Info "luarocks: installed to $lrDir"
}

function Install-Rocks {
  $lr = Join-Path (Join-Path $InstallRoot "LuaRocks") "luarocks.exe"
  $luaDir = Join-Path $InstallRoot "Lua54"
  $incDir = Join-Path $ToolsRoot "lua54_include"
  $rockBin = Join-Path $env:APPDATA "luarocks\bin"

  & $lr config variables.LUA_DIR $luaDir
  & $lr config variables.LUA_BINDIR $luaDir
  & $lr config variables.LUA_INCDIR $incDir
  & $lr config variables.LUA_LIBDIR $luaDir

  foreach ($rock in @("busted", "luacheck")) {
    $bin = Join-Path $rockBin "$rock.bat"
    if (Test-Path $bin) {
      Info "rock: $rock already installed"
    } else {
      Warn "installing rock: $rock ..."
      & $lr install $rock
      if ($LASTEXITCODE -ne 0) { Err "could not install rock '$rock'"; exit 1 }
    }
  }
  Add-UserPath $rockBin
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

Ensure-NoSpaceTmp
Refresh-SessionPath

if ($Check) {
  Info "checking environment ..."
  $missing = @()
  if (-not (Test-Path (Join-Path $InstallRoot "LOVE\love.exe")))       { $missing += "love" }
  if (-not (Test-Path (Join-Path $InstallRoot "Lua54\lua.exe")))       { $missing += "lua" }
  if (-not (Test-Path (Join-Path $InstallRoot "LuaRocks\luarocks.exe"))) { $missing += "luarocks" }
  if (-not (Test-Path (Join-Path $env:APPDATA "luarocks\bin\busted.bat")))  { $missing += "busted" }
  if (-not (Test-Path (Join-Path $env:APPDATA "luarocks\bin\luacheck.bat"))){ $missing += "luacheck" }
  if ($missing.Count -gt 0) {
    Err "missing (install with .\scripts\bootstrap.ps1): $($missing -join ', ')"
    exit 1
  }
  Info "all dependencies present."
  exit 0
}

Install-Love
Install-Lua54
Install-LuaHeaders
Install-LuaRocks
Install-Rocks
Add-UserPath (Join-Path $InstallRoot "LOVE")
Add-UserPath (Join-Path $InstallRoot "Lua54")
Add-UserPath (Join-Path $InstallRoot "LuaRocks")

Refresh-SessionPath
$rockBin = Join-Path $env:APPDATA "luarocks\bin"

Info "verifying ..."
& (Join-Path $InstallRoot "LOVE\love.exe") --version
& (Join-Path $InstallRoot "Lua54\lua.exe") -v
& (Join-Path $rockBin "busted.bat") --version
& (Join-Path $rockBin "luacheck.bat") --version

Info "environment ready."
Info "run tests with: .\scripts\test.ps1   (or: busted tests/spec; luacheck src tests)"