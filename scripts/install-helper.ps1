$ErrorActionPreference = "Stop"

$ProtocolName = "livingroomtv"
$ScriptDirectory = (Resolve-Path -LiteralPath (Split-Path -Parent $MyInvocation.MyCommand.Path)).Path
$HelperPath = Join-Path $ScriptDirectory "livingroomtv-helper.ps1"
$ProtocolKey = "HKCU:\Software\Classes\$ProtocolName"
$CommandKey = Join-Path $ProtocolKey "shell\open\command"
$PowerShellPath = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"

if (-not (Test-Path -LiteralPath $HelperPath)) {
  throw "Helper script not found: $HelperPath"
}

New-Item -Path $CommandKey -Force | Out-Null
Set-Item -Path $ProtocolKey -Value "URL:Living Room TV Helper"
New-ItemProperty -Path $ProtocolKey -Name "URL Protocol" -Value "" -PropertyType String -Force | Out-Null

$command = "`"$PowerShellPath`" -NoProfile -ExecutionPolicy Bypass -File `"$HelperPath`" `"%1`""
Set-Item -Path $CommandKey -Value $command

Write-Host "Installed livingroomtv:// helper protocol."
Write-Host "Scope: current user (HKCU), no administrator rights required."
Write-Host "Helper: $HelperPath"
Write-Host "Command: $command"
Write-Host "Test with: Start-Process 'livingroomtv://action/ping'"
