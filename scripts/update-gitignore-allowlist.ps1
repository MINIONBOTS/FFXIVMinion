[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$bootstrapDirs = @(
    "!/.github/",
    "!/.github/workflows/",
    "!/scripts/"
)

$bootstrapFiles = @(
    "!/.github/workflows/gitignore-allowlist-check.yml",
    "!/scripts/update-gitignore-allowlist.ps1"
)

function Get-AllParentDirectories {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    $dirs = New-Object "System.Collections.Generic.HashSet[string]"

    foreach ($path in $Paths) {
        $parts = $path -split "/"
        if ($parts.Length -le 1) {
            continue
        }

        $acc = ""
        for ($i = 0; $i -lt ($parts.Length - 1); $i++) {
            if ($acc) {
                $acc = "$acc/$($parts[$i])"
            }
            else {
                $acc = $parts[$i]
            }

            [void]$dirs.Add("!/$acc/")
        }
    }

    return ($dirs | Sort-Object)
}

if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
    throw "No .git folder found at '$RepoRoot'. Run this script from inside the repository."
}

Push-Location $RepoRoot
try {
    $trackedFiles = git ls-files
    if (-not $trackedFiles) {
        throw "No tracked files found from git ls-files."
    }

    $allowFiles = New-Object "System.Collections.Generic.List[string]"
    foreach ($file in $trackedFiles) {
        if ($file -eq ".gitignore") {
            continue
        }

        $allowFiles.Add("!/$file")
    }

    $allowDirs = Get-AllParentDirectories -Paths $trackedFiles

    $output = New-Object "System.Collections.Generic.List[string]"
    $output.Add("# Auto-generated allowlist: track only files present in this git repository.")
    $output.Add("# Everything else in this active runtime folder is ignored.")
    $output.Add("/**")
    $output.Add("!.gitignore")

    foreach ($dir in $bootstrapDirs) {
        $output.Add($dir)
    }

    foreach ($dir in $allowDirs) {
        $output.Add($dir)
    }

    foreach ($fileRule in $bootstrapFiles) {
        $output.Add($fileRule)
    }

    foreach ($fileRule in ($allowFiles | Sort-Object)) {
        $output.Add($fileRule)
    }

    Set-Content -Path ".gitignore" -Value $output -Encoding ascii
    Write-Host "Updated .gitignore from tracked files ($(($trackedFiles | Measure-Object).Count) entries)."
}
finally {
    Pop-Location
}
