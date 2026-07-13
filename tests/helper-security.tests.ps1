$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$HelperPath = Join-Path $ProjectRoot "scripts/livingroomtv-helper.ps1"
. $HelperPath -SkipMain

function Assert-Equal {
  param($Actual, $Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "$Name expected '$Expected' but received '$Actual'."
  }
}

function New-EventCollector {
  param([System.Collections.Generic.List[object]]$Events)
  return {
    param($Action, $EventName, $Result, $Detail)
    $Events.Add([pscustomobject]@{
      Action = $Action
      Event = $EventName
      Result = $Result
      Detail = $Detail
    }) | Out-Null
  }.GetNewClosure()
}

$cancelExecutionCount = 0
$cancelEvents = New-Object System.Collections.Generic.List[object]
$cancelResult = Invoke-PowerActionWithAuthorization `
  -Action "shutdown" `
  -ConfirmationCallback {
    param($Action)
    [pscustomobject]@{ Displayed = $true; Outcome = "cancelled"; Detail = "Synthetic cancellation." }
  } `
  -ExecutionCallback {
    param($Action)
    $script:cancelExecutionCount++
  } `
  -EventCallback (New-EventCollector -Events $cancelEvents)

Assert-Equal $cancelResult.Outcome "cancelled" "Cancellation outcome"
Assert-Equal $cancelResult.ExecutionAttempted $false "Cancellation execution flag"
Assert-Equal $cancelExecutionCount 0 "Cancellation execution count"
Assert-Equal ($cancelEvents.Result -contains "displayed") $true "Cancellation displayed event"
Assert-Equal ($cancelEvents.Result -contains "cancelled") $true "Cancellation result event"
Assert-Equal (($cancelEvents.Result -join ",")) "received,displayed,cancelled" "Cancellation event sequence"
Write-Host "PASS: cancellation prevents power execution and records the outcome."

$confirmExecutionCount = 0
$confirmEvents = New-Object System.Collections.Generic.List[object]
$confirmResult = Invoke-PowerActionWithAuthorization `
  -Action "restart" `
  -ConfirmationCallback {
    param($Action)
    [pscustomobject]@{ Displayed = $true; Outcome = "confirmed"; Detail = "Synthetic confirmation." }
  } `
  -ExecutionCallback {
    param($Action)
    $script:confirmExecutionCount++
  } `
  -EventCallback (New-EventCollector -Events $confirmEvents)

Assert-Equal $confirmResult.Outcome "success" "Confirmation outcome"
Assert-Equal $confirmResult.ExecutionAttempted $true "Confirmation execution flag"
Assert-Equal $confirmExecutionCount 1 "Confirmation execution count"
Assert-Equal ($confirmEvents.Result -contains "confirmed") $true "Confirmation result event"
Assert-Equal ($confirmEvents.Result -contains "attempted") $true "Execution attempted event"
Assert-Equal ($confirmEvents.Result -contains "success") $true "Execution success event"
Assert-Equal (($confirmEvents.Result -join ",")) "received,displayed,confirmed,attempted,success" "Confirmation event sequence"
Write-Host "PASS: simulated affirmative confirmation reaches only the injected execution path."

$failedExecutionCount = 0
$failedEvents = New-Object System.Collections.Generic.List[object]
$failedResult = Invoke-PowerActionWithAuthorization `
  -Action "sleep" `
  -ConfirmationCallback {
    param($Action)
    [pscustomobject]@{ Displayed = $false; Outcome = "failed"; Detail = "Synthetic noninteractive session." }
  } `
  -ExecutionCallback {
    param($Action)
    $script:failedExecutionCount++
  } `
  -EventCallback (New-EventCollector -Events $failedEvents)

Assert-Equal $failedResult.Outcome "failed" "Noninteractive outcome"
Assert-Equal $failedResult.ExecutionAttempted $false "Noninteractive execution flag"
Assert-Equal $failedExecutionCount 0 "Noninteractive execution count"
Assert-Equal ($failedEvents.Result -contains "failed") $true "Noninteractive failure event"
Write-Host "PASS: dialog failure or noninteractive execution fails closed."

$rawAction = ConvertFrom-HelperUri -RawUri "livingroomtv://action/shutdown"
Assert-Equal $rawAction "shutdown" "Raw protocol normalized action"
$rawExecutionCount = 0
$rawResult = Invoke-PowerActionWithAuthorization `
  -Action $rawAction `
  -ConfirmationCallback {
    param($Action)
    [pscustomobject]@{ Displayed = $true; Outcome = "cancelled"; Detail = "Synthetic raw URI cancellation." }
  } `
  -ExecutionCallback {
    param($Action)
    $script:rawExecutionCount++
  } `
  -EventCallback { param($Action, $EventName, $Result, $Detail) }

Assert-Equal $rawResult.Outcome "cancelled" "Raw protocol authorization outcome"
Assert-Equal $rawExecutionCount 0 "Raw protocol execution count"
Write-Host "PASS: raw protocol invocation cannot bypass helper confirmation."

Assert-Equal (Test-AllowlistedAction -Action "not-allowed") $false "Unknown action allowlist"
Assert-Equal (ConvertFrom-HelperUri -RawUri "livingroomtv://action/not-allowed") "not-allowed" "Unknown action normalization"
Write-Host "PASS: unknown actions remain outside the allowlist."

$injectionUris = @(
  "livingroomtv://action/shutdown/extra",
  "livingroomtv://action/shutdown%22",
  "livingroomtv://action/shutdown?argument=unsafe",
  "https://action/shutdown"
)
foreach ($candidate in $injectionUris) {
  $candidateAction = ConvertFrom-HelperUri -RawUri $candidate
  if ($candidateAction -and (Test-AllowlistedAction -Action $candidateAction)) {
    throw "Injection-shaped URI reached an allowlisted action: $candidate"
  }
}

$helperSource = Get-Content -Raw -LiteralPath $HelperPath
if ($helperSource -match '(?i)Invoke-Expression|\biex\b|ScriptBlock\]::Create') {
  throw "Helper contains a dynamic execution primitive."
}
foreach ($powerAction in @("sleep", "restart", "shutdown")) {
  $dispatchPattern = '"' + $powerAction + '"\s*=\s*\{\s*Invoke-AuthorizedPowerAction\s+-Action\s+"' + $powerAction + '"\s*\}'
  if ($helperSource -notmatch $dispatchPattern) {
    throw "Power action does not route through helper authorization: $powerAction"
  }
}
if ($helperSource -notmatch 'MessageBoxButtons\]::YesNo' -or
    $helperSource -notmatch 'MessageBoxDefaultButton\]::Button2' -or
    $helperSource -notmatch '\[Environment\]::UserInteractive') {
  throw "Native confirmation must use Yes/No, default No, and fail closed outside an interactive session."
}
Write-Host "PASS: injection-shaped URIs and dynamic execution primitives remain blocked."
Write-Host "PASS: every power dispatch uses native helper authorization with default No."
