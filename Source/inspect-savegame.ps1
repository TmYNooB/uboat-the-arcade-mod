param(
    [Parameter(Mandatory = $true)]
    [string]$SavePath,
    [string]$ExportScreenshotPath,
    [switch]$DumpGameStateStrings
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $SavePath)) {
    throw "Save file not found: $SavePath"
}

$fs = [System.IO.File]::Open($SavePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
try {
    $deflate = New-Object System.IO.Compression.DeflateStream($fs, [System.IO.Compression.CompressionMode]::Decompress)
    try {
        $reader = New-Object System.IO.BinaryReader($deflate)
        try {
            $gameStateLen = $reader.ReadInt32()
            $gameStateBytes = $reader.ReadBytes($gameStateLen)

            $screenshotLen = $reader.ReadInt32()
            $screenshotBytes = $reader.ReadBytes($screenshotLen)

            $result = [pscustomobject]@{
                SavePath = $SavePath
                SaveSizeBytes = (Get-Item $SavePath).Length
                GameStateBlockBytes = $gameStateLen
                ScreenshotBlockBytes = $screenshotLen
                ScreenshotJpegSignature = ($screenshotBytes.Length -ge 3 -and $screenshotBytes[0] -eq 0xFF -and $screenshotBytes[1] -eq 0xD8 -and $screenshotBytes[2] -eq 0xFF)
            }

            Write-Output $result

            if ($ExportScreenshotPath) {
                [System.IO.File]::WriteAllBytes($ExportScreenshotPath, $screenshotBytes)
                Write-Output "Exported screenshot: $ExportScreenshotPath"
            }

            $patterns = @(
                'Type VIIC', 'Type VIIC41', 'Type IIA', 'U-96', 'Crew', 'Survivor',
                'Prisoner', 'Skipper', 'UBoat', 'BoatType', 'PlayerShip', 'Conning'
            )

            $utf8 = [System.Text.Encoding]::UTF8.GetString($gameStateBytes)
            $utf16 = [System.Text.Encoding]::Unicode.GetString($gameStateBytes)

            Write-Output 'Pattern hits in GameState block:'
            foreach ($p in $patterns) {
                $c8 = ([regex]::Matches($utf8, [regex]::Escape($p))).Count
                $c16 = ([regex]::Matches($utf16, [regex]::Escape($p))).Count
                Write-Output ("- {0}: utf8={1}, utf16={2}" -f $p, $c8, $c16)
            }

            if ($DumpGameStateStrings) {
                $strings = New-Object System.Collections.Generic.List[string]
                $sb = New-Object System.Text.StringBuilder
                foreach ($b in $gameStateBytes) {
                    if ($b -ge 32 -and $b -le 126) {
                        [void]$sb.Append([char]$b)
                    } else {
                        if ($sb.Length -ge 6) {
                            $strings.Add($sb.ToString())
                        }
                        $sb.Clear() | Out-Null
                    }
                }
                if ($sb.Length -ge 6) {
                    $strings.Add($sb.ToString())
                }

                $interesting = $strings | Sort-Object -Unique | Where-Object {
                    $_ -match 'Type|VIIC|Crew|Survivor|Prisoner|Skipper|U-\d+|Conning|Turm|Boat|Player'
                }

                Write-Output 'Interesting extracted ASCII strings from GameState block:'
                $interesting | Select-Object -First 200 | ForEach-Object { Write-Output ("  {0}" -f $_) }
            }
        }
        finally {
            $reader.Dispose()
        }
    }
    finally {
        $deflate.Dispose()
    }
}
finally {
    $fs.Dispose()
}
