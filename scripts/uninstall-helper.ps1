$ErrorActionPreference = "Stop"

$ProtocolKey = "HKCU:\Software\Classes\livingroomtv"

if (Test-Path -LiteralPath $ProtocolKey) {
  Remove-Item -LiteralPath $ProtocolKey -Recurse -Force
  Write-Host "Removed livingroomtv:// helper protocol."
  Write-Host "Logs were not deleted. They remain under %LOCALAPPDATA%\LivingRoomTV."
} else {
  Write-Host "livingroomtv:// helper protocol is not installed."
}
