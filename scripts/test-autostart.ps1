[CmdletBinding()]
param([switch]$Launch)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "install-autostart.ps1") -SkipMain
. (Join-Path $PSScriptRoot "start-living-room-tv.ps1") -SkipMain

$failures = New-Object System.Collections.Generic.List[string]

function Add-AutostartPass {
  param([string]$Message)
  Write-Host "PASS: $Message"
}

function Add-AutostartFailure {
  param([string]$Message)
  $failures.Add($Message) | Out-Null
  Write-Host "FAIL: $Message"
}

$definition = Get-LivingRoomTvAutostartDefinition
$shortcutInfo = Get-AutostartShortcutInfo -ShortcutPath $definition.ShortcutPath
if (-not $shortcutInfo) {
  Add-AutostartFailure "Current-user startup shortcut is not installed: $($definition.ShortcutPath)"
} elseif (Test-AutostartShortcutMatches -Definition $definition -ShortcutInfo $shortcutInfo) {
  Add-AutostartPass "Current-user startup shortcut matches this installation."
} else {
  Add-AutostartFailure "Startup shortcut exists but its target, quoting, working directory, or ownership marker differs."
}

if (Test-Path -LiteralPath $definition.WrapperPath -PathType Leaf) {
  Add-AutostartPass "Startup wrapper exists: $($definition.WrapperPath)"
} else {
  Add-AutostartFailure "Startup wrapper is missing: $($definition.WrapperPath)"
}

$browser = Find-SupportedBrowser
if ($browser) {
  Add-AutostartPass "Supported browser found: $browser"
} else {
  Add-AutostartFailure "Google Chrome or Chromium was not found."
}

Write-Host "Running a non-destructive startup dry run."
Invoke-LivingRoomTvStartup -PlanOnly | Out-Null

if ($Launch -and $failures.Count -eq 0) {
  Write-Host "Launching Living Room TV once for manual validation; no sign-out or restart will occur."
  Invoke-LivingRoomTvStartup | Out-Null
}

Write-Host "A real sign-out/sign-in test is still required to validate Windows logon behavior."
if ($failures.Count -gt 0) {
  throw "Autostart diagnostics failed with $($failures.Count) finding(s)."
}

Write-Host "Autostart diagnostics passed."
