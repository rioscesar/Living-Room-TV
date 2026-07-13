$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$CheckerPath = Join-Path $ProjectRoot "scripts/check-project.ps1"

function Assert-ControlFails {
  param(
    [Parameter(Mandatory)] [scriptblock]$Control,
    [Parameter(Mandatory)] [string]$Name
  )

  try {
    & $Control
  } catch {
    Write-Host "PASS: positive control flagged $Name."
    return
  }

  throw "Positive control did not flag $Name."
}

. $CheckerPath -ProjectRoot $ProjectRoot

& (Join-Path $ProjectRoot "scripts/check-public-readiness.ps1") -ProjectRoot $ProjectRoot
& (Join-Path $ProjectRoot "tests/public-readiness.tests.ps1")
& (Join-Path $ProjectRoot "tests/helper-security.tests.ps1")
& (Join-Path $ProjectRoot "tests/autostart.tests.ps1")

& node --test (Join-Path $ProjectRoot "tests/navigation.test.js")
if ($LASTEXITCODE -ne 0) {
  throw "Node navigation regression tests failed."
}

$goodApp = @'
const supported = ["url", "protocol", "helper", "placeholder"];
const helpers = ["ping", "ea", "sleep", "restart", "shutdown"];
'@

$goodHelper = @'
$handlers = @{
  "ping" = {}; "ea" = {}; "sleep" = {}; "restart" = {}; "shutdown" = {}
}
'@

Assert-ProjectContract -AppSource $goodApp -HelperSource $goodHelper
Write-Host "PASS: negative control accepted the known-good contract."

Assert-ControlFails -Name "missing shutdown helper dispatch" -Control {
  Assert-ProjectContract -AppSource $goodApp -HelperSource ($goodHelper -replace '"shutdown"\s*=\s*\{\}', '')
}

Write-Host "PASS: checker self-tests completed."
