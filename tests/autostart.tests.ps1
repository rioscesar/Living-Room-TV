$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$InstallPath = Join-Path $ProjectRoot "scripts\install-autostart.ps1"
$UninstallPath = Join-Path $ProjectRoot "scripts\uninstall-autostart.ps1"
$StartPath = Join-Path $ProjectRoot "scripts\start-living-room-tv.ps1"
$TestScriptPath = Join-Path $ProjectRoot "scripts\test-autostart.ps1"

. $InstallPath -SkipMain
. $UninstallPath -SkipMain
. $StartPath -SkipMain

function Assert-AutostartEqual {
  param($Actual, $Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "$Name expected '$Expected' but received '$Actual'."
  }
}

function Assert-AutostartThrows {
  param([scriptblock]$Action, [string]$Name)
  try {
    & $Action
  } catch {
    Write-Host "PASS: $Name was rejected."
    return
  }
  throw "$Name was not rejected."
}

foreach ($scriptPath in @($InstallPath, $UninstallPath, $StartPath, $TestScriptPath)) {
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors.Count -gt 0) {
    throw "PowerShell parser failed for $scriptPath`: $($errors[0].Message)"
  }
}
Write-Host "PASS: autostart PowerShell scripts parse successfully."

$TestRoot = Join-Path $env:TEMP ("Living Room TV Autostart Test " + [guid]::NewGuid().ToString("N"))
$ProjectWithSpaces = Join-Path $TestRoot "Project With Spaces"
$ScriptsDirectory = Join-Path $ProjectWithSpaces "scripts"
$StartupDirectory = Join-Path $TestRoot "Startup Folder"
New-Item -ItemType Directory -Path $ScriptsDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $StartupDirectory -Force | Out-Null
Copy-Item -LiteralPath $StartPath -Destination (Join-Path $ScriptsDirectory "start-living-room-tv.ps1")
Set-Content -LiteralPath (Join-Path $ProjectWithSpaces "index.html") -Value "<!doctype html>" -Encoding UTF8

try {
  $definition = Get-LivingRoomTvAutostartDefinition -ProjectRoot $ProjectWithSpaces -StartupDirectory $StartupDirectory
  if ($definition.Arguments -notmatch '-File\s+".+Project With Spaces.+start-living-room-tv\.ps1"$') {
    throw "Wrapper path with spaces is not quoted safely: $($definition.Arguments)"
  }
  Write-Host "PASS: startup shortcut arguments quote paths with spaces."

  $firstInstall = Install-LivingRoomTvAutostart -Definition $definition
  $secondInstall = Install-LivingRoomTvAutostart -Definition $definition
  Assert-AutostartEqual $firstInstall.Outcome "created" "First install outcome"
  Assert-AutostartEqual $secondInstall.Outcome "unchanged" "Second install outcome"
  Assert-AutostartEqual @(Get-ChildItem -LiteralPath $StartupDirectory -Filter "*.lnk").Count 1 "Startup shortcut count"
  $installedInfo = Get-AutostartShortcutInfo -ShortcutPath $definition.ShortcutPath
  Assert-AutostartEqual (Test-AutostartShortcutMatches -Definition $definition -ShortcutInfo $installedInfo) $true "Installed shortcut contract"
  Write-Host "PASS: installer is idempotent and creates one owned shortcut."

  $firstRemoval = Uninstall-LivingRoomTvAutostart -Definition $definition
  $secondRemoval = Uninstall-LivingRoomTvAutostart -Definition $definition
  Assert-AutostartEqual $firstRemoval.Outcome "removed" "First uninstall outcome"
  Assert-AutostartEqual $secondRemoval.Outcome "absent" "Second uninstall outcome"
  Write-Host "PASS: uninstaller is idempotent."

  $shell = New-Object -ComObject WScript.Shell
  $foreignShortcut = $shell.CreateShortcut($definition.ShortcutPath)
  $foreignShortcut.TargetPath = $definition.TargetPath
  $foreignShortcut.Arguments = "-NoProfile"
  $foreignShortcut.WorkingDirectory = $env:TEMP
  $foreignShortcut.Description = "Unrelated startup entry"
  $foreignShortcut.Save()
  Assert-AutostartThrows -Name "unrelated startup entry removal" -Action {
    Uninstall-LivingRoomTvAutostart -Definition $definition | Out-Null
  }
  Assert-AutostartEqual (Test-Path -LiteralPath $definition.ShortcutPath) $true "Foreign shortcut preservation"
  Write-Host "PASS: uninstaller preserves unrelated startup entries."

  $fakeBrowser = Join-Path $TestRoot "chrome.exe"
  Set-Content -LiteralPath $fakeBrowser -Value "synthetic browser" -Encoding UTF8
  $foundBrowser = Find-SupportedBrowser -Candidates @((Join-Path $TestRoot "missing.exe"), $fakeBrowser)
  Assert-AutostartEqual $foundBrowser (Resolve-Path -LiteralPath $fakeBrowser).Path "Browser detection fallback"

  $launcherPath = Join-Path $ProjectWithSpaces "index.html"
  $launcherUri = ConvertTo-LauncherFileUri -LauncherPath $launcherPath
  if ($launcherUri -notmatch '^file:///' -or $launcherUri -notmatch '%20') {
    throw "Local launcher URI is not safely encoded: $launcherUri"
  }
  $plan = New-StartupLaunchPlan -BrowserPath $fakeBrowser -LauncherPath $launcherPath
  Assert-AutostartEqual ($plan.Arguments -contains "--new-window") $true "New-window flag"
  Assert-AutostartEqual ($plan.Arguments -contains "--start-fullscreen") $true "Fullscreen flag"
  Assert-AutostartEqual ($plan.Arguments -contains $launcherUri) $true "Launcher URI argument"
  Write-Host "PASS: browser detection and fixed launch planning are deterministic."

  $testGuardName = "Local\LivingRoomTV.Startup.Test." + [guid]::NewGuid().ToString("N")
  $firstGuard = Enter-StartupGuard -Name $testGuardName
  $secondGuard = Enter-StartupGuard -Name $testGuardName
  try {
    Assert-AutostartEqual $firstGuard.Acquired $true "First startup guard acquisition"
    Assert-AutostartEqual $secondGuard.Acquired $false "Duplicate startup guard acquisition"
  } finally {
    Exit-StartupGuard -Handle $secondGuard
    Exit-StartupGuard -Handle $firstGuard
  }
  $releasedGuard = Enter-StartupGuard -Name $testGuardName
  try {
    Assert-AutostartEqual $releasedGuard.Acquired $true "Released startup guard reacquisition"
  } finally {
    Exit-StartupGuard -Handle $releasedGuard
  }
  Write-Host "PASS: runtime guard blocks concurrent launcher windows and releases cleanly."

  $startupSources = (Get-Content -Raw $InstallPath), (Get-Content -Raw $UninstallPath), (Get-Content -Raw $StartPath) -join "`n"
  if ($startupSources -match '(?i)HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Run|HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run|Register-ScheduledTask|New-ScheduledTask|AutoAdminLogon|DefaultPassword|#requires\s+-RunAsAdministrator|-Verb\s+RunAs') {
    throw "Autostart implementation contains a machine-wide, Scheduled Task, or auto-login modification."
  }
  if ($startupSources -match '(?i)Invoke-Expression|\biex\b|ScriptBlock\]::Create|shutdown\.exe|SetSuspendState|Stop-Process|taskkill') {
    throw "Autostart implementation contains dynamic execution, a power action, or unrelated process termination."
  }
  if ($startupSources -match '(?i)--user-data-dir|--kiosk') {
    throw "Autostart implementation changes browser profiles or kiosk behavior."
  }
  Write-Host "PASS: autostart remains current-user, fixed-command, non-elevated, and power-safe."
} finally {
  $resolvedTemp = [System.IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
  $resolvedTestRoot = [System.IO.Path]::GetFullPath($TestRoot)
  if (-not $resolvedTestRoot.StartsWith($resolvedTemp, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to remove test data outside the temporary directory: $resolvedTestRoot"
  }
  if (Test-Path -LiteralPath $TestRoot) {
    Remove-Item -LiteralPath $TestRoot -Recurse -Force
  }
}

Write-Host "PASS: autostart security and lifecycle tests completed."
