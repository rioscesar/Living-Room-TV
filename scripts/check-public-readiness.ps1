[CmdletBinding()]
param(
  [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
  [switch]$SkipRun
)

$ErrorActionPreference = "Stop"

function Assert-NoSensitiveText {
  param([Parameter(Mandatory)] [string]$Text)

  $directEmailPattern = '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b'
  if ($Text -match $directEmailPattern) {
    throw "Public content contains an email address."
  }

  $splitEmailPatterns = @(
    '(?i)["'']([A-Z0-9._%+-]+)["'']\s*\+\s*["'']@["'']\s*\+\s*["'']([A-Z0-9.-]+\.[A-Z]{2,})["'']',
    '(?i)["'']([A-Z0-9._%+-]+)["'']\s*\+\s*["'']@([A-Z0-9.-]+\.[A-Z]{2,})["'']'
  )
  foreach ($pattern in $splitEmailPatterns) {
    if ($Text -match $pattern) {
      throw "Public content reconstructs an email address from split strings."
    }
  }
}

function Assert-PublicReadinessContract {
  param(
    [Parameter(Mandatory)] [hashtable]$Files,
    [Parameter(Mandatory)] [string[]]$TrackedPaths
  )

  $required = @(
    "README.md", "LICENSE", "ARCHITECTURE.md", "CONTRIBUTING.md",
    "CODE_OF_CONDUCT.md", "SECURITY.md", "SUPPORT.md", "STATE.md",
    "docs/RELEASE-CHECKLIST.md", "docs/SCREENSHOTS.md",
    ".github/workflows/validate.yml", ".github/pull_request_template.md",
    ".github/ISSUE_TEMPLATE/config.yml",
    ".github/ISSUE_TEMPLATE/bug_report.yml",
    ".github/ISSUE_TEMPLATE/feature_request.yml"
  )

  foreach ($path in $required) {
    if (-not $Files.ContainsKey($path)) {
      throw "Required public-readiness file is missing: $path"
    }
  }

  $scannerImplementationPaths = @(
    "scripts/check-public-readiness.ps1",
    "tests/public-readiness.tests.ps1"
  )
  $allText = (($Files.GetEnumerator() | Where-Object {
    $scannerImplementationPaths -notcontains $_.Key
  } | ForEach-Object { $_.Value }) -join "`n")
  Assert-NoSensitiveText -Text $allText

  $bannedContent = [ordered]@{
    "Windows user profile path" = '(?i)C:\\Users\\'
    "private workspace path" = '(?i)(?:^|[^A-Za-z])D:\\'
    "private storage reference" = '(?i)OneDrive'
    "private audience wording" = '(?i)\b(?:wife|spouse|household)\b'
    "GitHub classic token" = 'ghp_[A-Za-z0-9]{20,}'
    "GitHub fine-grained token" = 'github_pat_[A-Za-z0-9_]+'
    "AWS access key" = 'AKIA[0-9A-Z]{16}'
    "private key" = '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'
  }

  foreach ($name in $bannedContent.Keys) {
    if ($allText -match $bannedContent[$name]) {
      throw "Public content contains $name."
    }
  }

  $blockedTrackedPaths = @(
    '(^|/)favorites\.local\.js$', '(^|/)\.env(?:\..*)?$',
    '(^|/)helper\.log$', '(^|/)helper-status\.json$',
    '(^|/)credentials?(?:\.|$)', '(^|/)secrets?(?:\.|$)'
  )
  foreach ($path in $TrackedPaths) {
    $normalized = $path -replace '\\', '/'
    foreach ($pattern in $blockedTrackedPaths) {
      if ($normalized -match $pattern) {
        throw "Private or generated file is tracked: $path"
      }
    }
  }

  $example = $Files["favorites.local.example.js"]
  if ($example -notmatch 'https://example\.com' -or $example -match 'https?://(?!example\.com|www\.example\.com)') {
    throw "Favorites example must use reserved example.com destinations only."
  }

  $readme = $Files["README.md"]
  $readmeRequirements = @(
    "## Quick Start", "## Controller Setup", "## Private Favorites",
    "## Optional Windows Helper", "## Security Model", "## Current Limitations",
    "## Troubleshooting", "## Development", "## License and Responsible Use",
    "D-pad", "Left stick", "Right stick", "Right trigger", "View button",
    "Product and service names are trademarks"
  )
  foreach ($text in $readmeRequirements) {
    if (-not $readme.Contains($text)) {
      throw "README is missing required public guidance: $text"
    }
  }

  $workflow = $Files[".github/workflows/validate.yml"]
  if ($workflow -notmatch 'runs-on:\s*windows-latest' -or
      $workflow -notmatch 'actions/checkout@[0-9a-f]{40}' -or
      $workflow -match '\$\{\{\s*secrets\.') {
    throw "Validation workflow must be Windows-based, SHA-pinned, and secret-free."
  }

  $helper = $Files["scripts/livingroomtv-helper.ps1"]
  foreach ($action in @("ping", "ea", "sleep", "restart", "shutdown")) {
    if ($helper -notmatch ('["'']' + $action + '["'']\s*=')) {
      throw "Helper is missing fixed allowlisted action: $action"
    }
  }
  if ($helper -match '(?i)Invoke-Expression|\biex\b|ScriptBlock\]::Create') {
    throw "Helper contains a dynamic execution primitive."
  }

  if ($Files["app.js"] -match '(?i)getGamepads\s*\(|gamepadconnected|gamepaddisconnected') {
    throw "Dashboard contains a native Gamepad input path."
  }
}

if (-not $SkipRun) {
  $git = Get-Command git -ErrorAction SilentlyContinue
  if (-not $git) {
    throw "Git is required for tracked-file and history validation."
  }

  $tracked = @(& $git.Source -C $ProjectRoot ls-files)
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to enumerate tracked files."
  }

  $files = @{}
  foreach ($relativePath in $tracked) {
    $fullPath = Join-Path $ProjectRoot $relativePath
    if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
      try {
        $files[$relativePath] = Get-Content -Raw -LiteralPath $fullPath -ErrorAction Stop
      } catch {
        # Binary files are covered by explicit asset review rather than text matching.
      }
    }
  }

  # Include untracked files in the active implementation so the checker validates
  # the proposed public surface before it is committed.
  $untracked = @(& $git.Source -C $ProjectRoot ls-files --others --exclude-standard)
  foreach ($relativePath in $untracked) {
    $fullPath = Join-Path $ProjectRoot $relativePath
    if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
      $files[$relativePath] = Get-Content -Raw -LiteralPath $fullPath
    }
  }

  Assert-PublicReadinessContract -Files $files -TrackedPaths $tracked

  $emails = @(& $git.Source -C $ProjectRoot log --all --format="%ae%n%ce")
  $unexpectedEmails = @($emails | Where-Object {
    $_ -and
    $_ -ne "noreply@github.com" -and
    $_ -notmatch '^[^@]+@users\.noreply\.github\.com$'
  })
  if ($unexpectedEmails.Count -gt 0) {
    throw "Reachable Git history contains a non-noreply email address."
  }

  Write-Host "PASS: public-readiness contract checks."
}
