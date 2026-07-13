[CmdletBinding()]
param(
  [string]$ProjectRoot
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Split-Path -Parent $PSScriptRoot
}

function Assert-ProjectContract {
  param(
    [Parameter(Mandatory)] [string]$AppSource,
    [Parameter(Mandatory)] [string]$HelperSource
  )

  $requiredActionTypes = @("url", "protocol", "helper", "placeholder")
  foreach ($actionType in $requiredActionTypes) {
    if ($AppSource -notmatch ('["'']' + [regex]::Escape($actionType) + '["'']')) {
      throw "app.js is missing required action type: $actionType"
    }
  }

  $requiredHelperActions = @("ping", "ea", "sleep", "restart", "shutdown")
  foreach ($action in $requiredHelperActions) {
    if ($AppSource -notmatch ('["'']' + $action + '["'']')) {
      throw "app.js is missing helper allowlist action: $action"
    }
    if ($HelperSource -notmatch ('["'']' + $action + '["'']\s*=')) {
      throw "Helper dispatch table is missing action: $action"
    }
  }

}

$requiredPaths = @(
  "AGENTS.md",
  "ARCHITECTURE.md",
  "CODE_OF_CONDUCT.md",
  "CONTRIBUTING.md",
  "LICENSE",
  "STATE.md",
  "SECURITY.md",
  "SUPPORT.md",
  "README.md",
  "index.html",
  "style.css",
  "app.js",
  "favorites.local.example.js",
  "docs/PRINCIPLES.md",
  "docs/VISION.md",
  "docs/ROADMAP.md",
  "docs/BACKLOG.md",
  "docs/DESIGN.md",
  "docs/DECISIONS.md",
  "docs/CHANGELOG.md",
  "docs/RELEASES.md",
  "scripts/livingroomtv-helper.ps1",
  "scripts/start-living-room-tv.ps1",
  "scripts/install-autostart.ps1",
  "scripts/uninstall-autostart.ps1",
  "scripts/test-autostart.ps1",
  "tests/helper-security.tests.ps1",
  "tests/autostart.tests.ps1",
  ".github/workflows/validate.yml",
  "docs/RELEASE-CHECKLIST.md"
)

foreach ($relativePath in $requiredPaths) {
  $path = Join-Path $ProjectRoot $relativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Required project file is missing: $relativePath"
  }
}

$indexSource = Get-Content -Raw (Join-Path $ProjectRoot "index.html")
if ($indexSource -notmatch 'href=["'']style\.css["'']') {
  throw "index.html does not load style.css."
}
if ($indexSource -notmatch 'src=["'']app\.js["'']') {
  throw "index.html does not load app.js."
}

$appPath = Join-Path $ProjectRoot "app.js"
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
  throw "Node.js is required; JavaScript syntax validation cannot be skipped."
}

& $node.Source --check $appPath
if ($LASTEXITCODE -ne 0) {
  throw "Node syntax check failed for app.js."
}

$appSource = Get-Content -Raw $appPath
$helperSource = Get-Content -Raw (Join-Path $ProjectRoot "scripts/livingroomtv-helper.ps1")
Assert-ProjectContract -AppSource $appSource -HelperSource $helperSource

Write-Host "PASS: Living Room TV project contract checks."
