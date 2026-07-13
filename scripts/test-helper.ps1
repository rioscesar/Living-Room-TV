$ErrorActionPreference = "Stop"

$ProtocolKey = "HKCU:\Software\Classes\livingroomtv"
$CommandKey = Join-Path $ProtocolKey "shell\open\command"
$ScriptDirectory = (Resolve-Path -LiteralPath (Split-Path -Parent $MyInvocation.MyCommand.Path)).Path
$HelperPath = Join-Path $ScriptDirectory "livingroomtv-helper.ps1"
$LogDirectory = Join-Path $env:LOCALAPPDATA "LivingRoomTV"
$LogPath = Join-Path $LogDirectory "helper.log"
$StatusPath = Join-Path $LogDirectory "helper-status.json"
$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
  param([string]$Message)
  $failures.Add($Message) | Out-Null
  Write-Host "FAIL: $Message"
}

function Add-Pass {
  param([string]$Message)
  Write-Host "PASS: $Message"
}

if (Test-Path -LiteralPath $ProtocolKey) {
  Add-Pass "Protocol key exists: $ProtocolKey"
} else {
  Add-Failure "Protocol key missing: $ProtocolKey"
}

if (Test-Path -LiteralPath $CommandKey) {
  Add-Pass "Command key exists: $CommandKey"
  $command = (Get-Item -LiteralPath $CommandKey).GetValue("")
  Write-Host "Registered command: $command"
} else {
  Add-Failure "Command key missing: $CommandKey"
}

if (Test-Path -LiteralPath $HelperPath) {
  Add-Pass "Helper script exists: $HelperPath"
} else {
  Add-Failure "Helper script missing: $HelperPath"
}

Write-Host "Invoking safe direct ping..."
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $HelperPath "livingroomtv://action/ping"

if (Test-Path -LiteralPath $StatusPath) {
  Add-Pass "Status file exists: $StatusPath"
  Get-Content -LiteralPath $StatusPath
} else {
  Add-Failure "Status file missing after direct ping: $StatusPath"
}

if (Test-Path -LiteralPath $LogPath) {
  Add-Pass "Log file exists: $LogPath"
  Write-Host "Recent log lines:"
  Get-Content -LiteralPath $LogPath -Tail 10
} else {
  Add-Failure "Log file missing after direct ping: $LogPath"
}

Write-Host "Invoking blocked unknown action..."
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $HelperPath "livingroomtv://action/not-allowed"
$blockedStatus = Get-Content -Raw -LiteralPath $StatusPath | ConvertFrom-Json
if ($blockedStatus.result -eq "blocked") {
  Add-Pass "Unknown helper action remains blocked."
} else {
  Add-Failure "Unknown helper action was not blocked."
}

Write-Host "Optional browser/protocol test command:"
Write-Host "Start-Process 'livingroomtv://action/ping'"
Write-Host "Logs: $LogPath"
Write-Host "Status: $StatusPath"

if ($failures.Count -gt 0) {
  Write-Host "Helper diagnostics failed."
  exit 1
}

Write-Host "Helper diagnostics passed."
