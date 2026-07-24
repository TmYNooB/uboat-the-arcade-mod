param(
    [string]$SavePath,
    [string]$GameInstallPath = "D:\Steam\steamapps\common\UBOAT",
    [string]$OutputPath,
    [int]$MaxDepth = 8,
    [int]$MaxCollectionItems = 200
)

$ErrorActionPreference = 'Stop'

function Get-LatestManualSavePath {
    $saveDir = Join-Path $env:USERPROFILE 'AppData\LocalLow\Deep Water Studio\UBOAT\Saves'
    if (-not (Test-Path $saveDir)) {
        throw "Save directory not found: $saveDir"
    }

    $manual = Get-ChildItem -Path $saveDir -File -Filter *.save |
        Where-Object { $_.Name -notmatch '^Autosave_' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $manual) {
        throw "No manual save file found in: $saveDir"
    }

    return $manual.FullName
}

function Convert-ToSafeJsonObject {
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $InputObject,
        [int]$Depth = 0,
        [int]$MaxDepth = 8,
        [int]$MaxCollectionItems = 200,
        [hashtable]$Visited
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if (-not $Visited) {
        $Visited = @{}
    }

    $type = $InputObject.GetType()

    if ($InputObject -is [string] -or
        $InputObject -is [bool] -or
        $InputObject -is [byte] -or
        $InputObject -is [sbyte] -or
        $InputObject -is [int16] -or
        $InputObject -is [uint16] -or
        $InputObject -is [int32] -or
        $InputObject -is [uint32] -or
        $InputObject -is [int64] -or
        $InputObject -is [uint64] -or
        $InputObject -is [single] -or
        $InputObject -is [double] -or
        $InputObject -is [decimal]) {
        return $InputObject
    }

    if ($InputObject -is [datetime]) {
        return $InputObject.ToString('o')
    }

    if ($type.IsEnum) {
        return $InputObject.ToString()
    }

    if ($Depth -ge $MaxDepth) {
        return "[MaxDepth:$($type.FullName)]"
    }

    if (-not $type.IsValueType) {
        $id = [System.Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($InputObject)
        if ($Visited.ContainsKey($id)) {
            return "[Ref:$($type.FullName):$id]"
        }
        $Visited[$id] = $true
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $dictResult = [ordered]@{}
        $count = 0

        foreach ($key in $InputObject.Keys) {
            if ($count -ge $MaxCollectionItems) {
                $dictResult['__truncated'] = $true
                break
            }

            $safeKey = if ($null -eq $key) { '<null>' } else { [string]$key }
            $dictResult[$safeKey] = Convert-ToSafeJsonObject -InputObject $InputObject[$key] -Depth ($Depth + 1) -MaxDepth $MaxDepth -MaxCollectionItems $MaxCollectionItems -Visited $Visited
            $count++
        }

        return $dictResult
    }

    if (($InputObject -is [System.Collections.IEnumerable]) -and -not ($InputObject -is [string])) {
        $list = New-Object System.Collections.Generic.List[object]
        $count = 0

        foreach ($item in $InputObject) {
            if ($count -ge $MaxCollectionItems) {
                $list.Add('[Truncated]')
                break
            }

            $list.Add((Convert-ToSafeJsonObject -InputObject $item -Depth ($Depth + 1) -MaxDepth $MaxDepth -MaxCollectionItems $MaxCollectionItems -Visited $Visited))
            $count++
        }

        return $list
    }

    $result = [ordered]@{}
    $result['__type'] = $type.FullName

    foreach ($prop in ($type.GetProperties([System.Reflection.BindingFlags]'Public,Instance') | Where-Object { $_.GetIndexParameters().Count -eq 0 })) {
        try {
            $value = $prop.GetValue($InputObject, $null)
            $result[$prop.Name] = Convert-ToSafeJsonObject -InputObject $value -Depth ($Depth + 1) -MaxDepth $MaxDepth -MaxCollectionItems $MaxCollectionItems -Visited $Visited
        }
        catch {
            $result[$prop.Name] = "[Error:$($_.Exception.Message)]"
        }
    }

    foreach ($field in $type.GetFields([System.Reflection.BindingFlags]'Public,NonPublic,Instance')) {
        if ($result.Contains($field.Name)) {
            continue
        }

        try {
            $value = $field.GetValue($InputObject)
            $result[$field.Name] = Convert-ToSafeJsonObject -InputObject $value -Depth ($Depth + 1) -MaxDepth $MaxDepth -MaxCollectionItems $MaxCollectionItems -Visited $Visited
        }
        catch {
            $result[$field.Name] = "[Error:$($_.Exception.Message)]"
        }
    }

    return $result
}

if (-not $SavePath) {
    $SavePath = Get-LatestManualSavePath
}

if (-not (Test-Path $SavePath)) {
    throw "Save file not found: $SavePath"
}

$managedDir = Join-Path $GameInstallPath 'UBOAT_Data\Managed'
$gameAsmPath = Join-Path $managedDir 'com.uboat.game.dll'

if (-not (Test-Path $gameAsmPath)) {
    throw "Game assembly not found: $gameAsmPath"
}

if (-not $OutputPath) {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $OutputPath = Join-Path $repoRoot 'Source\latest-manual-savegame-decoded.json'
}

$saveFile = Get-Item $SavePath

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

[System.AppDomain]::CurrentDomain.add_AssemblyResolve({
    param($sender, $args)

    $name = ($args.Name.Split(',')[0] + '.dll')
    $candidate = Join-Path $managedDir $name
    if (Test-Path $candidate) {
        return [System.Reflection.Assembly]::LoadFrom($candidate)
    }

    return $null
})

[void][System.Reflection.Assembly]::LoadFrom($gameAsmPath)

$decoded = $null
$decodedRootType = $null
$decodeStrategy = $null
$decodeErrors = New-Object System.Collections.Generic.List[string]

try {
    $gameAsm = [System.Reflection.Assembly]::LoadFrom($gameAsmPath)
    $settingsType = $gameAsm.GetType('UBOAT.Game.Core.Serialization.GameStateSerializationSettings', $true)
    $deserializerType = $gameAsm.GetType('UBOAT.Game.Serialization.GameStateDeserializer', $true)

    $settings = [System.Activator]::CreateInstance($settingsType)
    $deserializer = [System.Activator]::CreateInstance($deserializerType, @($settings))
    $deserializeMethod = $deserializerType.GetMethod('Deserialize', [type[]]@([System.IO.Stream], [bool]))

    $memory = [System.IO.MemoryStream]::new($gameStateBytes)
    try {
        $streamArg = [System.IO.Stream]$memory
        $decoded = $deserializeMethod.Invoke($deserializer, [object[]]@($streamArg, $true))
        if ($null -ne $decoded) {
            $decodedRootType = $decoded.GetType().FullName
            $decodeStrategy = 'GameStateDeserializer.Deserialize(stream, true)'
        }
    }
    finally {
        $memory.Dispose()
    }
}
catch {
    $decodeErrors.Add("GameStateDeserializer failed: $($_.Exception.Message)")
    if ($_.Exception.InnerException) {
        $decodeErrors.Add("GameStateDeserializer inner: $($_.Exception.InnerException.Message)")
    }
}

if ($null -eq $decoded) {
    foreach ($offset in @(0, 4, 8, 16)) {
        try {
            if ($offset -ge $gameStateBytes.Length) {
                continue
            }

            $sliceLen = $gameStateBytes.Length - $offset
            $slice = New-Object byte[] $sliceLen
            [System.Array]::Copy($gameStateBytes, $offset, $slice, 0, $sliceLen)

            $memory = [System.IO.MemoryStream]::new($slice)
            try {
                $formatter = New-Object System.Runtime.Serialization.Formatters.Binary.BinaryFormatter
                $decoded = $formatter.Deserialize($memory)
                if ($null -ne $decoded) {
                    $decodedRootType = $decoded.GetType().FullName
                    $decodeStrategy = "BinaryFormatter.Deserialize(offset=$offset)"
                    break
                }
            }
            finally {
                $memory.Dispose()
            }
        }
        catch {
            $decodeErrors.Add("BinaryFormatter offset $offset failed: $($_.Exception.Message)")
            if ($_.Exception.InnerException) {
                $decodeErrors.Add("BinaryFormatter offset $offset inner: $($_.Exception.InnerException.Message)")
            }
        }
    }
}

if ($null -eq $decoded) {
    throw "Unable to decode game state. Tried GameStateDeserializer and BinaryFormatter fallbacks. Details: $($decodeErrors -join ' || ')"
}

$safe = Convert-ToSafeJsonObject -InputObject $decoded -MaxDepth $MaxDepth -MaxCollectionItems $MaxCollectionItems

$output = [pscustomobject]@{
    generatedAt = (Get-Date).ToString('s')
    sourceSave = $SavePath
    sourceSaveName = $saveFile.Name
    sourceSaveLastWriteTime = $saveFile.LastWriteTime.ToString('s')
    sourceSaveSizeBytes = $saveFile.Length
    gameStateBlockBytes = $gameStateLen
    screenshotBlockBytes = $screenshotLen
    screenshotJpegSignature = ($screenshotBytes.Length -ge 3 -and $screenshotBytes[0] -eq 0xFF -and $screenshotBytes[1] -eq 0xD8 -and $screenshotBytes[2] -eq 0xFF)
    decodeStrategy = $decodeStrategy
    decodedRootType = $decodedRootType
    decodeErrors = @($decodeErrors)
    decoded = $safe
}

$output | ConvertTo-Json -Depth 100 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Output "Save decoded to: $OutputPath"
Write-Output "Decoded root type: $($decoded.GetType().FullName)"
