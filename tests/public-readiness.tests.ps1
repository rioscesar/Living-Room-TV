$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$CheckerPath = Join-Path $ProjectRoot "scripts/check-public-readiness.ps1"
. $CheckerPath -ProjectRoot $ProjectRoot -SkipRun

function Assert-PublicControlFails {
  param(
    [Parameter(Mandatory)] [scriptblock]$Control,
    [Parameter(Mandatory)] [string]$Name
  )

  try {
    & $Control
  } catch {
    Write-Host "PASS: public-readiness positive control flagged $Name."
    return
  }
  throw "Public-readiness positive control did not flag $Name."
}

$required = @(
  "README.md", "LICENSE", "ARCHITECTURE.md", "CONTRIBUTING.md",
  "CODE_OF_CONDUCT.md", "SECURITY.md", "SUPPORT.md", "STATE.md",
  "docs/RELEASE-CHECKLIST.md", "docs/SCREENSHOTS.md",
  ".github/workflows/validate.yml", ".github/pull_request_template.md",
  ".github/ISSUE_TEMPLATE/config.yml", ".github/ISSUE_TEMPLATE/bug_report.yml",
  ".github/ISSUE_TEMPLATE/feature_request.yml"
)

$goodFiles = @{}
foreach ($path in $required) { $goodFiles[$path] = "safe" }
$goodFiles["README.md"] = @'
## Quick Start
## Controller Setup
## Private Favorites
## Optional Windows Helper
## Security Model
## Current Limitations
## Troubleshooting
## Development
## License and Responsible Use
D-pad Left stick Right stick Right trigger View button
Product and service names are trademarks
'@
$goodFiles["favorites.local.example.js"] = 'url: "https://example.com"'
$goodFiles[".github/workflows/validate.yml"] = @'
runs-on: windows-latest
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
'@
$goodFiles["scripts/livingroomtv-helper.ps1"] = @'
$allowed = @{ "ping" = {}; "ea" = {}; "sleep" = {}; "restart" = {}; "shutdown" = {} }
'@
$goodFiles["app.js"] = 'const inputOwner = "keyboard";'

Assert-PublicReadinessContract -Files $goodFiles -TrackedPaths @("README.md", "app.js")
Write-Host "PASS: public-readiness negative control accepted known-good content."

Assert-PublicControlFails -Name "direct synthetic email" -Control {
  $broken = $goodFiles.Clone()
  $broken["SUPPORT.md"] = 'Contact test-person@example.invalid'
  Assert-PublicReadinessContract -Files $broken -TrackedPaths @("SUPPORT.md")
}

Assert-PublicControlFails -Name "split-string synthetic email reconstruction" -Control {
  $broken = $goodFiles.Clone()
  $broken["SUPPORT.md"] = 'const address = "private-user" + "@" + "example.invalid";'
  Assert-PublicReadinessContract -Files $broken -TrackedPaths @("SUPPORT.md")
}

Assert-PublicControlFails -Name "personal profile path" -Control {
  $broken = $goodFiles.Clone()
  $broken["SUPPORT.md"] = 'See C:\Users\example\helper.log'
  Assert-PublicReadinessContract -Files $broken -TrackedPaths @("SUPPORT.md")
}

Assert-PublicControlFails -Name "tracked private Favorites" -Control {
  Assert-PublicReadinessContract -Files $goodFiles -TrackedPaths @("favorites.local.js")
}

Assert-PublicControlFails -Name "unpinned CI action" -Control {
  $broken = $goodFiles.Clone()
  $broken[".github/workflows/validate.yml"] = 'runs-on: windows-latest`nuses: actions/checkout@v4'
  Assert-PublicReadinessContract -Files $broken -TrackedPaths @("README.md")
}

Assert-PublicControlFails -Name "dynamic helper execution" -Control {
  $broken = $goodFiles.Clone()
  $broken["scripts/livingroomtv-helper.ps1"] += "`nInvoke-Expression `$command"
  Assert-PublicReadinessContract -Files $broken -TrackedPaths @("README.md")
}

Write-Host "PASS: public-readiness checker self-tests completed."
