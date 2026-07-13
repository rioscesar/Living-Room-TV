[CmdletBinding()]
param([switch]$SkipMain)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "install-autostart.ps1") -SkipMain

function Uninstall-LivingRoomTvAutostart {
  param([Parameter(Mandatory)]$Definition)

  $existing = Get-AutostartShortcutInfo -ShortcutPath $Definition.ShortcutPath
  if (-not $existing) {
    return [pscustomobject]@{ Outcome = "absent"; Definition = $Definition }
  }
  if (-not (Test-AutostartShortcutMatches -Definition $Definition -ShortcutInfo $existing)) {
    throw "The startup entry at $($Definition.ShortcutPath) is not owned by this Living Room TV installation and was not removed."
  }

  Remove-Item -LiteralPath $Definition.ShortcutPath
  return [pscustomobject]@{ Outcome = "removed"; Definition = $Definition }
}

if (-not $SkipMain) {
  $definition = Get-LivingRoomTvAutostartDefinition
  $result = Uninstall-LivingRoomTvAutostart -Definition $definition
  Write-Host "Autostart entry $($result.Outcome): $($definition.ShortcutPath)"
  Write-Host "Steam startup, the project, browser data, and other user profiles were not changed."
  Write-Host "Startup logs were preserved under: $(Join-Path $env:LOCALAPPDATA 'LivingRoomTV')"
}
