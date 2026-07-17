$ErrorActionPreference = 'Stop'
Import-Module ImportExcel

$modDir = 'c:\Users\User\AppData\LocalLow\Deep Water Studio\UBOAT\Mods\uboat-the-arcade-mod\Data Sheets'
$origDir = 'D:\Steam\steamapps\common\UBOAT\UBOAT_Data\Data Sheets'
$xlsx = @('General.xlsx', 'Entities.xlsx', 'Sandbox.xlsx', 'CharacterClasses.xlsx')

function Get-DecimalTokens([string]$s) {
    $tokens = @()
    if ([string]::IsNullOrWhiteSpace($s)) {
        return $tokens
    }

    $matches = [regex]::Matches($s, '(?<![0-9])([0-9]+([\.,])[0-9]+)(?![0-9])')
    foreach ($m in $matches) {
        $raw = $m.Groups[1].Value
        $sep = $m.Groups[2].Value
        $norm = $raw.Replace(',', '.')
        $num = 0.0
        if ([double]::TryParse($norm, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$num)) {
            $tokens += [pscustomobject]@{
                Raw = $raw
                Sep = $sep
                Num = $num
            }
        }
    }

    return $tokens
}

function ParsePairs([string]$s) {
    $d = @{}
    if ([string]::IsNullOrWhiteSpace($s)) {
        return $d
    }

    foreach ($part in ($s -split ',')) {
        $kv = $part.Trim()
        if ($kv -match '^([^=]+)=(.+)$') {
            $k = $matches[1].Trim()
            $v = $matches[2].Trim()
            $d[$k] = $v
        }
    }

    return $d
}

$report = [ordered]@{
    generatedAt = (Get-Date).ToString('s')
    mode = 'deep-token-scan'
    files = @()
    summary = [ordered]@{
        checkedFiles = 0
        checkedSheets = 0
        checkedRows = 0
        checkedCells = 0
        checkedParameterValues = 0
        tokenSeparatorMismatches = 0
        parameterTokenSeparatorMismatches = 0
    }
}

foreach ($file in $xlsx) {
    $modPath = Join-Path $modDir $file
    $origPath = Join-Path $origDir $file

    if (!(Test-Path $modPath) -or !(Test-Path $origPath)) {
        continue
    }

    $sheetInfos = Get-ExcelSheetInfo -Path $modPath
    $fileEntry = [ordered]@{
        file = $file
        sheets = @()
    }

    foreach ($si in $sheetInfos) {
        $sheet = $si.Name
        $modRows = @(Import-Excel -Path $modPath -WorksheetName $sheet -NoHeader)
        $origRows = @(Import-Excel -Path $origPath -WorksheetName $sheet -NoHeader)

        $origById = @{}
        foreach ($r in $origRows) {
            $id = [string]$r.P1
            if (-not [string]::IsNullOrWhiteSpace($id)) {
                $origById[$id] = $r
            }
        }

        $sheetEntry = [ordered]@{
            sheet = $sheet
            checkedOverrideRows = 0
            cellTokenMismatches = @()
            parameterTokenMismatches = @()
        }

        foreach ($mr in $modRows) {
            $id = [string]$mr.P1
            if ([string]::IsNullOrWhiteSpace($id)) {
                continue
            }
            if ($id.StartsWith('/')) {
                continue
            }
            if (-not $origById.ContainsKey($id)) {
                continue
            }

            $or = $origById[$id]
            $sheetEntry.checkedOverrideRows++
            $report.summary.checkedRows++

            foreach ($prop in $mr.PSObject.Properties) {
                $name = $prop.Name
                if ($name -eq 'P1') {
                    continue
                }

                $mv = [string]$mr.$name
                $ov = [string]$or.$name
                if ([string]::IsNullOrWhiteSpace($mv) -or [string]::IsNullOrWhiteSpace($ov)) {
                    continue
                }

                $report.summary.checkedCells++
                $mt = @(Get-DecimalTokens $mv)
                $ot = @(Get-DecimalTokens $ov)

                if ($mt.Count -eq 0 -or $ot.Count -eq 0) {
                    continue
                }

                $n = [Math]::Min($mt.Count, $ot.Count)
                for ($i = 0; $i -lt $n; $i++) {
                    if ([Math]::Abs($mt[$i].Num - $ot[$i].Num) -lt 1e-12 -and $mt[$i].Sep -ne $ot[$i].Sep) {
                        $sheetEntry.cellTokenMismatches += [pscustomobject]@{
                            id = $id
                            column = $name
                            tokenIndex = $i
                            modToken = $mt[$i].Raw
                            origToken = $ot[$i].Raw
                            modSep = $mt[$i].Sep
                            origSep = $ot[$i].Sep
                            modCell = $mv
                            origCell = $ov
                        }
                        $report.summary.tokenSeparatorMismatches++
                    }
                }
            }

            $paramCols = @('P16', 'P17', 'P18', 'P19', 'P20', 'P21', 'P22', 'P23', 'P24', 'P25')
            foreach ($pc in $paramCols) {
                if (-not ($mr.PSObject.Properties.Name -contains $pc)) {
                    continue
                }

                $mps = [string]$mr.$pc
                $ops = [string]$or.$pc
                if ([string]::IsNullOrWhiteSpace($mps) -or [string]::IsNullOrWhiteSpace($ops)) {
                    continue
                }

                $mp = ParsePairs $mps
                $op = ParsePairs $ops
                foreach ($k in $mp.Keys) {
                    if (-not $op.ContainsKey($k)) {
                        continue
                    }

                    $report.summary.checkedParameterValues++
                    $mv = [string]$mp[$k]
                    $ov = [string]$op[$k]
                    $mt = @(Get-DecimalTokens $mv)
                    $ot = @(Get-DecimalTokens $ov)

                    if ($mt.Count -eq 0 -or $ot.Count -eq 0) {
                        continue
                    }

                    $n = [Math]::Min($mt.Count, $ot.Count)
                    for ($i = 0; $i -lt $n; $i++) {
                        if ([Math]::Abs($mt[$i].Num - $ot[$i].Num) -lt 1e-12 -and $mt[$i].Sep -ne $ot[$i].Sep) {
                            $sheetEntry.parameterTokenMismatches += [pscustomobject]@{
                                id = $id
                                column = $pc
                                parameter = $k
                                tokenIndex = $i
                                modToken = $mt[$i].Raw
                                origToken = $ot[$i].Raw
                                modSep = $mt[$i].Sep
                                origSep = $ot[$i].Sep
                                modValue = $mv
                                origValue = $ov
                            }
                            $report.summary.parameterTokenSeparatorMismatches++
                        }
                    }
                }
            }
        }

        if ($sheetEntry.cellTokenMismatches.Count -gt 0 -or $sheetEntry.parameterTokenMismatches.Count -gt 0) {
            $fileEntry.sheets += $sheetEntry
        }

        $report.summary.checkedSheets++
    }

    if ($fileEntry.sheets.Count -gt 0) {
        $report.files += $fileEntry
    }

    $report.summary.checkedFiles++
}

$out = 'c:\Users\User\AppData\LocalLow\Deep Water Studio\UBOAT\Mods\uboat-the-arcade-mod\Source\number-format-audit-deep-2026-07-17.json'
$report | ConvertTo-Json -Depth 10 | Set-Content -Path $out -Encoding UTF8

Write-Output "Wrote $out"
Write-Output (
    'Summary: cellTokens=' + $report.summary.tokenSeparatorMismatches +
    ', paramTokens=' + $report.summary.parameterTokenSeparatorMismatches +
    ', rows=' + $report.summary.checkedRows +
    ', cells=' + $report.summary.checkedCells +
    ', paramVals=' + $report.summary.checkedParameterValues
)
