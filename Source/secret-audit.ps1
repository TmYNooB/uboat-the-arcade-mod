param(
    [string]$OutputPath = "Source/secret-audit-report.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$patterns = @(
    @{ Name = "GitHub classic token"; Regex = 'ghp_[A-Za-z0-9]{36}' },
    @{ Name = "GitHub fine-grained token"; Regex = 'github_pat_[A-Za-z0-9_]{20,}' },
    @{ Name = "GitHub OAuth token"; Regex = 'gho_[A-Za-z0-9]{36}' },
    @{ Name = "Slack token"; Regex = 'xox[baprs]-[A-Za-z0-9-]{10,}' },
    @{ Name = "AWS Access Key ID"; Regex = 'AKIA[0-9A-Z]{16}' },
    @{ Name = "Google API key"; Regex = 'AIza[0-9A-Za-z\-_]{35}' },
    @{ Name = "Generic assigned secret"; Regex = '(?i)(api[_-]?key|token|secret|password)\s*[:=]\s*["''][^"''\r\n]{8,}["'']' },
    @{ Name = "Private key block"; Regex = '-----BEGIN (RSA|OPENSSH|EC|DSA|PGP) PRIVATE KEY-----' },
    @{ Name = "Steam auth artifact"; Regex = 'steam_login_secure|steamMachineAuth' }
)

$excludeExt = @('.xlsx','.jpg','.jpeg','.png','.gif','.webp','.dat','.zip','.7z','.rar','.dll','.exe','.bin')
$root = (Get-Location).Path

function Mask-Value {
    param([string]$Value)

    if (-not $Value) { return "" }
    if ($Value.Length -le 8) { return ('*' * $Value.Length) }

    $keep = 4
    $middleLen = $Value.Length - (2 * $keep)
    if ($middleLen -lt 1) { $middleLen = 1 }
    return $Value.Substring(0, $keep) + ('*' * $middleLen) + $Value.Substring($Value.Length - $keep)
}

$findings = @()

$files = Get-ChildItem -Recurse -File -Force | Where-Object {
    $_.FullName -notmatch '\\.git\\' -and
    $_.FullName -notmatch '\\.steam-upload\\content\\' -and
    ($excludeExt -notcontains $_.Extension.ToLowerInvariant())
}

foreach ($file in $files) {
    $rel = $file.FullName.Substring($root.Length + 1)

    foreach ($pattern in $patterns) {
        $matches = Select-String -Path $file.FullName -Pattern $pattern.Regex -AllMatches -Encoding UTF8 -ErrorAction SilentlyContinue
        foreach ($lineMatch in $matches) {
            foreach ($tokenMatch in $lineMatch.Matches) {
                $findings += [pscustomobject]@{
                    Scope = 'working-tree'
                    Type = $pattern.Name
                    File = $rel
                    Line = $lineMatch.LineNumber
                    ValueMasked = Mask-Value -Value $tokenMatch.Value
                }
            }
        }
    }
}

$commits = git rev-list --all
foreach ($commit in $commits) {
    foreach ($pattern in $patterns) {
        $raw = git grep -n -I -E $pattern.Regex $commit -- . 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $raw) {
            continue
        }

        foreach ($entry in ($raw -split "`n")) {
            if (-not $entry.Trim()) { continue }

            $parts = $entry -split ':', 4
            if ($parts.Count -lt 4) { continue }

            $path = $parts[1]
            $lineNo = 0
            [void][int]::TryParse($parts[2], [ref]$lineNo)
            $text = $parts[3]
            $valueMatches = [regex]::Matches($text, $pattern.Regex)

            foreach ($vm in $valueMatches) {
                $findings += [pscustomobject]@{
                    Scope = 'git-history'
                    Type = $pattern.Name
                    Commit = $commit
                    File = $path
                    Line = $lineNo
                    ValueMasked = Mask-Value -Value $vm.Value
                }
            }
        }
    }
}

$uniqueFindings = $findings | Sort-Object Scope, Type, File, Line, ValueMasked -Unique
$resolvedOut = Join-Path $root $OutputPath
$uniqueFindings | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $resolvedOut -Encoding UTF8

Write-Output ("FINDINGS_COUNT " + $uniqueFindings.Count)
Write-Output ("REPORT " + $resolvedOut)
$uniqueFindings | Select-Object -First 100 | Format-Table -AutoSize
