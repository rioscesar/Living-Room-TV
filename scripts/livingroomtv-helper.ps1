[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [string]$Uri,
  [switch]$SkipMain
)

$ErrorActionPreference = "Stop"

$LogDirectory = Join-Path $env:LOCALAPPDATA "LivingRoomTV"
$LogPath = Join-Path $LogDirectory "helper.log"
$StatusPath = Join-Path $LogDirectory "helper-status.json"
$PowerActions = @("sleep", "restart", "shutdown")
$AllowedActionNames = @("ping", "ea") + $PowerActions

function Initialize-HelperStorage {
  if (-not (Test-Path -LiteralPath $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
  }
}

function Write-HelperLog {
  param(
    [string]$Event,
    [string]$RawUri = "",
    [string]$Action = "",
    [string]$Result = "",
    [string]$Detail = ""
  )

  Initialize-HelperStorage

  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $line = "[$timestamp] event=$Event rawUri=""$RawUri"" action=""$Action"" result=""$Result"" detail=""$Detail"""
  Add-Content -LiteralPath $LogPath -Value $line
}

function Write-HelperStatus {
  param(
    [string]$Action,
    [string]$Result,
    [string]$Detail
  )

  Initialize-HelperStorage

  $status = [ordered]@{
    timestamp = (Get-Date).ToString("o")
    action = $Action
    result = $Result
    detail = $Detail
  }

  $status | ConvertTo-Json | Set-Content -LiteralPath $StatusPath -Encoding UTF8
}

function ConvertFrom-HelperUri {
  param([string]$RawUri)

  if ([string]::IsNullOrWhiteSpace($RawUri)) {
    return $null
  }

  try {
    $parsed = [System.Uri]$RawUri
  } catch {
    return $null
  }

  if ($parsed.Scheme -ne "livingroomtv" -or
      $parsed.Host -ne "action" -or
      -not [string]::IsNullOrEmpty($parsed.Query) -or
      -not [string]::IsNullOrEmpty($parsed.Fragment) -or
      -not [string]::IsNullOrEmpty($parsed.UserInfo) -or
      $parsed.Port -ne -1) {
    return $null
  }

  $segments = $parsed.AbsolutePath.Trim("/") -split "/"
  if ($segments.Count -ne 1 -or [string]::IsNullOrWhiteSpace($segments[0])) {
    return $null
  }

  return $segments[0].ToLowerInvariant()
}

function Get-RequestedAction {
  param([string]$RawUri)

  $action = ConvertFrom-HelperUri -RawUri $RawUri
  if (-not $action) {
    Write-HelperLog -Event "parse" -RawUri $RawUri -Result "blocked" -Detail "Malformed or unsupported helper URI."
    return $null
  }

  Write-HelperLog -Event "parse" -RawUri $RawUri -Action $action -Result "ok" -Detail "Action parsed."
  return $action
}

function Test-AllowlistedAction {
  param([string]$Action)

  return $AllowedActionNames -contains $Action
}

function Invoke-Ping {
  Write-HelperStatus -Action "ping" -Result "ok" -Detail "Helper ping received."
  Write-HelperLog -Event "execute" -RawUri $Uri -Action "ping" -Result "success" -Detail "Status file updated at $StatusPath."
}

function Get-EaCandidatePaths {
  return @(
    "$env:ProgramFiles\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe",
    "${env:ProgramFiles(x86)}\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe",
    "$env:LOCALAPPDATA\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe"
  ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}

function Start-EaApp {
  $candidatePaths = Get-EaCandidatePaths

  Write-HelperLog -Event "ea-search" -RawUri $Uri -Action "ea" -Result "info" -Detail "Searched paths: $($candidatePaths -join " | ")"

  foreach ($candidate in $candidatePaths) {
    if (Test-Path -LiteralPath $candidate) {
      Start-Process -FilePath $candidate
      Write-HelperStatus -Action "ea" -Result "ok" -Detail "EA app launch requested."
      Write-HelperLog -Event "execute" -RawUri $Uri -Action "ea" -Result "success" -Detail "Started $candidate"
      return
    }
  }

  Write-HelperStatus -Action "ea" -Result "not_found" -Detail "EA app not found in known locations."
  Write-HelperLog -Event "execute" -RawUri $Uri -Action "ea" -Result "not_found" -Detail "EA not found. Searched paths: $($candidatePaths -join " | ")"
}

function Show-PowerActionConfirmation {
  param(
    [ValidateSet("sleep", "restart", "shutdown")]
    [string]$Action
  )

  $actionLabels = @{
    sleep = "put this PC to sleep"
    restart = "restart this PC"
    shutdown = "shut down this PC"
  }

  try {
    $sessionId = (Get-Process -Id $PID).SessionId
    if (-not [Environment]::UserInteractive -or $sessionId -eq 0) {
      return [pscustomobject]@{
        Displayed = $false
        Outcome = "failed"
        Detail = "Interactive desktop confirmation is unavailable."
      }
    }

    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    $message = "Allow Living Room TV to $($actionLabels[$Action])?"
    $result = [System.Windows.Forms.MessageBox]::Show(
      $message,
      "Confirm $Action",
      [System.Windows.Forms.MessageBoxButtons]::YesNo,
      [System.Windows.Forms.MessageBoxIcon]::Warning,
      [System.Windows.Forms.MessageBoxDefaultButton]::Button2
    )

    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
      return [pscustomobject]@{
        Displayed = $true
        Outcome = "confirmed"
        Detail = "Local user confirmed $Action."
      }
    }

    return [pscustomobject]@{
      Displayed = $true
      Outcome = "cancelled"
      Detail = "Local user cancelled $Action."
    }
  } catch {
    return [pscustomobject]@{
      Displayed = $false
      Outcome = "failed"
      Detail = "Confirmation dialog failed: $($_.Exception.Message)"
    }
  }
}

function Invoke-PowerActionCommand {
  param(
    [ValidateSet("sleep", "restart", "shutdown")]
    [string]$Action
  )

  switch ($Action) {
    "sleep" {
      if (-not ("LivingRoomTvPower" -as [type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class LivingRoomTvPower {
  [DllImport("powrprof.dll", SetLastError = true)]
  public static extern bool SetSuspendState(bool hibernate, bool forceCritical, bool disableWakeEvent);
}
"@
      }

      if (-not [LivingRoomTvPower]::SetSuspendState($false, $false, $false)) {
        throw "Windows rejected the sleep request."
      }
    }
    "restart" {
      $shutdownPath = Join-Path $env:WINDIR "System32\shutdown.exe"
      Start-Process -FilePath $shutdownPath -ArgumentList "/r /t 5 /c `"Living Room TV restart requested.`""
    }
    "shutdown" {
      $shutdownPath = Join-Path $env:WINDIR "System32\shutdown.exe"
      Start-Process -FilePath $shutdownPath -ArgumentList "/s /t 5 /c `"Living Room TV shutdown requested.`""
    }
  }
}

function Invoke-PowerActionWithAuthorization {
  param(
    [ValidateSet("sleep", "restart", "shutdown")]
    [string]$Action,
    [Parameter(Mandatory)] [scriptblock]$ConfirmationCallback,
    [Parameter(Mandatory)] [scriptblock]$ExecutionCallback,
    [Parameter(Mandatory)] [scriptblock]$EventCallback
  )

  & $EventCallback $Action "power-request" "received" "Power action requested."

  try {
    $confirmation = & $ConfirmationCallback $Action
  } catch {
    $confirmation = [pscustomobject]@{
      Displayed = $false
      Outcome = "failed"
      Detail = "Confirmation callback failed: $($_.Exception.Message)"
    }
  }

  if ($confirmation.Displayed) {
    & $EventCallback $Action "power-confirmation" "displayed" "Local confirmation dialog displayed."
  }

  if ($confirmation.Outcome -ne "confirmed") {
    $outcome = if ($confirmation.Outcome -eq "cancelled") { "cancelled" } else { "failed" }
    & $EventCallback $Action "power-confirmation" $outcome $confirmation.Detail
    return [pscustomobject]@{
      Outcome = $outcome
      ExecutionAttempted = $false
      Detail = $confirmation.Detail
    }
  }

  & $EventCallback $Action "power-confirmation" "confirmed" $confirmation.Detail
  & $EventCallback $Action "power-execution" "attempted" "Executing confirmed fixed action."

  try {
    & $ExecutionCallback $Action
    & $EventCallback $Action "power-execution" "success" "Confirmed power action was requested from Windows."
    return [pscustomobject]@{
      Outcome = "success"
      ExecutionAttempted = $true
      Detail = "Confirmed power action was requested from Windows."
    }
  } catch {
    & $EventCallback $Action "power-execution" "failed" $_.Exception.Message
    return [pscustomobject]@{
      Outcome = "failed"
      ExecutionAttempted = $true
      Detail = $_.Exception.Message
    }
  }
}

function Invoke-AuthorizedPowerAction {
  param(
    [ValidateSet("sleep", "restart", "shutdown")]
    [string]$Action
  )

  $recordEvent = {
    param($EventAction, $EventName, $EventResult, $EventDetail)
    Write-HelperLog -Event $EventName -RawUri $Uri -Action $EventAction -Result $EventResult -Detail $EventDetail
  }

  $result = Invoke-PowerActionWithAuthorization `
    -Action $Action `
    -ConfirmationCallback ${function:Show-PowerActionConfirmation} `
    -ExecutionCallback ${function:Invoke-PowerActionCommand} `
    -EventCallback $recordEvent

  Write-HelperStatus -Action $Action -Result $result.Outcome -Detail $result.Detail
  return $result
}

if (-not $SkipMain) {
  Initialize-HelperStorage
  Write-HelperLog -Event "invoke" -RawUri $Uri -Result "received" -Detail "Helper started."

  $action = Get-RequestedAction -RawUri $Uri

  # Security model: the browser may request only one normalized action name. The
  # helper maps it to fixed allowlisted code. Power actions additionally require
  # affirmative interaction with a fixed local dialog before execution.
  $allowedActions = @{
    "ping" = { Invoke-Ping }
    "ea" = { Start-EaApp }
    "sleep" = { Invoke-AuthorizedPowerAction -Action "sleep" }
    "restart" = { Invoke-AuthorizedPowerAction -Action "restart" }
    "shutdown" = { Invoke-AuthorizedPowerAction -Action "shutdown" }
  }

  if (-not $action -or -not (Test-AllowlistedAction -Action $action) -or -not $allowedActions.ContainsKey($action)) {
    Write-HelperStatus -Action "$action" -Result "blocked" -Detail "Unknown or invalid action."
    Write-HelperLog -Event "allowlist" -RawUri $Uri -Action "$action" -Result "blocked" -Detail "Unknown action rejected."
    exit 0
  }

  Write-HelperLog -Event "allowlist" -RawUri $Uri -Action $action -Result "allowed" -Detail "Action is allowlisted."

  try {
    $result = & $allowedActions[$action]
    if ($result -and $result.Outcome -eq "failed") {
      exit 1
    }
  } catch {
    Write-HelperStatus -Action $action -Result "error" -Detail $_.Exception.Message
    Write-HelperLog -Event "execute" -RawUri $Uri -Action $action -Result "error" -Detail $_.Exception.Message
    exit 1
  }
}
