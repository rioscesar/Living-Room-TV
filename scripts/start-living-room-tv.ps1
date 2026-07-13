[CmdletBinding()]
param(
  [switch]$DryRun,
  [switch]$SkipMain
)

$ErrorActionPreference = "Stop"

$StartupLogDirectory = Join-Path $env:LOCALAPPDATA "LivingRoomTV"
$StartupLogPath = Join-Path $StartupLogDirectory "startup.log"
$StartupGuardName = "Local\LivingRoomTV.Startup.Launcher"

function Write-StartupLog {
  param(
    [Parameter(Mandatory)] [string]$Action,
    [Parameter(Mandatory)] [string]$Detail
  )

  if (-not (Test-Path -LiteralPath $StartupLogDirectory)) {
    New-Item -ItemType Directory -Path $StartupLogDirectory -Force | Out-Null
  }

  $timestamp = (Get-Date).ToString("o")
  "$timestamp`t$Action`t$Detail" | Add-Content -LiteralPath $StartupLogPath -Encoding UTF8
}

function Get-SupportedBrowserCandidates {
  $candidates = New-Object System.Collections.Generic.List[string]
  $appPathKeys = @(
    "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe",
    "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe",
    "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\App Paths\chromium.exe",
    "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\App Paths\chromium.exe"
  )

  foreach ($key in $appPathKeys) {
    if (Test-Path -LiteralPath $key) {
      $value = (Get-Item -LiteralPath $key).GetValue("")
      if ($value) {
        $candidates.Add([string]$value)
      }
    }
  }

  foreach ($commandName in @("chrome.exe", "chromium.exe")) {
    $command = Get-Command $commandName -ErrorAction SilentlyContinue
    if ($command -and $command.Source) {
      $candidates.Add($command.Source)
    }
  }

  $knownPaths = @(
    (Join-Path $env:ProgramFiles "Google\Chrome\Application\chrome.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Google\Chrome\Application\chrome.exe"),
    (Join-Path $env:LOCALAPPDATA "Google\Chrome\Application\chrome.exe"),
    (Join-Path $env:ProgramFiles "Chromium\Application\chrome.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Chromium\Application\chrome.exe"),
    (Join-Path $env:LOCALAPPDATA "Chromium\Application\chrome.exe")
  )
  foreach ($path in $knownPaths) {
    if ($path) {
      $candidates.Add($path)
    }
  }

  return @($candidates | Select-Object -Unique)
}

function Find-SupportedBrowser {
  param([string[]]$Candidates = (Get-SupportedBrowserCandidates))

  foreach ($candidate in $Candidates) {
    if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
      return (Resolve-Path -LiteralPath $candidate).Path
    }
  }

  return $null
}

function ConvertTo-LauncherFileUri {
  param([Parameter(Mandatory)] [string]$LauncherPath)

  $resolvedPath = (Resolve-Path -LiteralPath $LauncherPath).Path
  $uri = [System.Uri]$resolvedPath
  return $uri.AbsoluteUri
}

function New-StartupLaunchPlan {
  param(
    [Parameter(Mandatory)] [string]$BrowserPath,
    [Parameter(Mandatory)] [string]$LauncherPath
  )

  return [pscustomobject]@{
    BrowserPath = $BrowserPath
    LauncherPath = (Resolve-Path -LiteralPath $LauncherPath).Path
    LauncherUri = ConvertTo-LauncherFileUri -LauncherPath $LauncherPath
    Arguments = @("--new-window", "--start-fullscreen", (ConvertTo-LauncherFileUri -LauncherPath $LauncherPath))
  }
}

function Test-SteamReady {
  return $null -ne (Get-Process -Name "steam" -ErrorAction SilentlyContinue | Select-Object -First 1)
}

function Enter-StartupGuard {
  param([string]$Name = $StartupGuardName)

  $semaphore = New-Object System.Threading.Semaphore(1, 1, $Name)
  $acquired = $semaphore.WaitOne(0, $false)

  return [pscustomobject]@{
    Semaphore = $semaphore
    Acquired = $acquired
  }
}

function Exit-StartupGuard {
  param([Parameter(Mandatory)]$Handle)

  if ($Handle.Acquired) {
    $Handle.Semaphore.Release() | Out-Null
  }
  $Handle.Semaphore.Dispose()
}

function Invoke-LivingRoomTvStartup {
  param([switch]$PlanOnly)

  $projectRoot = Split-Path -Parent $PSScriptRoot
  $launcherPath = Join-Path $projectRoot "index.html"
  if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) {
    Write-StartupLog -Action "failed" -Detail "Launcher file is missing: $launcherPath"
    throw "Living Room TV launcher not found: $launcherPath"
  }

  $browserPath = Find-SupportedBrowser
  if (-not $browserPath) {
    Write-StartupLog -Action "failed" -Detail "Google Chrome or Chromium was not found in the documented locations."
    throw "Google Chrome or Chromium was not found. Install a supported browser and run the startup test again."
  }

  $plan = New-StartupLaunchPlan -BrowserPath $browserPath -LauncherPath $launcherPath
  Write-StartupLog -Action "detected" -Detail "Browser: $($plan.BrowserPath)"
  Write-StartupLog -Action "detected" -Detail "Launcher: $($plan.LauncherPath)"

  if (Test-SteamReady) {
    Write-StartupLog -Action "steam" -Detail "Steam is running; Desktop Layout may be available."
  } else {
    Write-StartupLog -Action "steam" -Detail "Steam is not running yet; launching without controller-readiness delay."
  }

  if ($PlanOnly) {
    Write-Host "Dry run only; no browser was started."
    Write-Host "Browser: $($plan.BrowserPath)"
    Write-Host "Launcher: $($plan.LauncherPath)"
    Write-Host "Arguments: $($plan.Arguments -join ' ')"
    Write-Host "Log: $StartupLogPath"
    return $plan
  }

  $guardHandle = Enter-StartupGuard
  try {
    if (-not $guardHandle.Acquired) {
      Write-StartupLog -Action "skipped" -Detail "Another Living Room TV startup wrapper is already active."
      Write-Host "Living Room TV is already being managed by another startup wrapper."
      return $null
    }

    Write-StartupLog -Action "launch" -Detail "Starting one fullscreen browser window."
    $process = Start-Process `
      -FilePath $plan.BrowserPath `
      -ArgumentList $plan.Arguments `
      -WorkingDirectory $projectRoot `
      -PassThru
    Write-StartupLog -Action "launched" -Detail "Browser process id: $($process.Id)"

    # Holding the per-session guard for the browser process lifetime prevents a
    # second startup invocation from creating another launcher window.
    $process.WaitForExit()
    Write-StartupLog -Action "closed" -Detail "Browser process exited."
    return $process
  } catch {
    Write-StartupLog -Action "failed" -Detail $_.Exception.Message
    throw
  } finally {
    Exit-StartupGuard -Handle $guardHandle
  }
}

if (-not $SkipMain) {
  Invoke-LivingRoomTvStartup -PlanOnly:$DryRun | Out-Null
}
