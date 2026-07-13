[CmdletBinding()]
param([switch]$SkipMain)

$ErrorActionPreference = "Stop"
$AutostartShortcutName = "Living Room TV.lnk"
$AutostartDescription = "Living Room TV automatic startup"

function Get-LivingRoomTvAutostartDefinition {
  param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$StartupDirectory = [Environment]::GetFolderPath("Startup")
  )

  $wrapperPath = Join-Path $ProjectRoot "scripts\start-living-room-tv.ps1"
  $powerShellPath = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
  return [pscustomobject]@{
    ShortcutPath = Join-Path $StartupDirectory $AutostartShortcutName
    TargetPath = $powerShellPath
    Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$wrapperPath`""
    WorkingDirectory = $ProjectRoot
    Description = $AutostartDescription
    WrapperPath = $wrapperPath
  }
}

function Get-AutostartShortcutInfo {
  param([Parameter(Mandatory)] [string]$ShortcutPath)

  if (-not (Test-Path -LiteralPath $ShortcutPath -PathType Leaf)) {
    return $null
  }

  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut($ShortcutPath)
  return [pscustomobject]@{
    TargetPath = $shortcut.TargetPath
    Arguments = $shortcut.Arguments
    WorkingDirectory = $shortcut.WorkingDirectory
    Description = $shortcut.Description
  }
}

function Test-AutostartShortcutMatches {
  param(
    [Parameter(Mandatory)]$Definition,
    [Parameter(Mandatory)]$ShortcutInfo
  )

  return (
    $ShortcutInfo.TargetPath -eq $Definition.TargetPath -and
    $ShortcutInfo.Arguments -eq $Definition.Arguments -and
    $ShortcutInfo.WorkingDirectory -eq $Definition.WorkingDirectory -and
    $ShortcutInfo.Description -eq $Definition.Description
  )
}

function Install-LivingRoomTvAutostart {
  param([Parameter(Mandatory)]$Definition)

  if (-not (Test-Path -LiteralPath $Definition.WrapperPath -PathType Leaf)) {
    throw "Startup wrapper not found: $($Definition.WrapperPath)"
  }
  if (-not (Test-Path -LiteralPath $Definition.TargetPath -PathType Leaf)) {
    throw "Windows PowerShell not found: $($Definition.TargetPath)"
  }

  $startupDirectory = Split-Path -Parent $Definition.ShortcutPath
  if (-not (Test-Path -LiteralPath $startupDirectory)) {
    New-Item -ItemType Directory -Path $startupDirectory -Force | Out-Null
  }

  $existing = Get-AutostartShortcutInfo -ShortcutPath $Definition.ShortcutPath
  if ($existing) {
    if (-not (Test-AutostartShortcutMatches -Definition $Definition -ShortcutInfo $existing)) {
      throw "An unrelated startup entry already exists at $($Definition.ShortcutPath). It was not overwritten."
    }
    return [pscustomobject]@{ Outcome = "unchanged"; Definition = $Definition }
  }

  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut($Definition.ShortcutPath)
  $shortcut.TargetPath = $Definition.TargetPath
  $shortcut.Arguments = $Definition.Arguments
  $shortcut.WorkingDirectory = $Definition.WorkingDirectory
  $shortcut.Description = $Definition.Description
  $shortcut.WindowStyle = 7
  $shortcut.Save()

  return [pscustomobject]@{ Outcome = "created"; Definition = $Definition }
}

if (-not $SkipMain) {
  $definition = Get-LivingRoomTvAutostartDefinition
  $result = Install-LivingRoomTvAutostart -Definition $definition
  Write-Host "Autostart entry $($result.Outcome): $($definition.ShortcutPath)"
  Write-Host "Scope: current Windows user only; no administrator rights required."
  Write-Host "Target: $($definition.TargetPath)"
  Write-Host "Arguments: $($definition.Arguments)"
  Write-Host "Steam startup and Windows automatic login were not changed."
  Write-Host "Test: powershell -ExecutionPolicy Bypass -File .\scripts\test-autostart.ps1"
  Write-Host "Uninstall: powershell -ExecutionPolicy Bypass -File .\scripts\uninstall-autostart.ps1"
}
