$ErrorActionPreference = 'Stop'

$managed = 'D:\Steam\steamapps\common\UBOAT\UBOAT_Data\Managed'
$payload = 'C:\Users\User\AppData\LocalLow\Deep Water Studio\UBOAT\Mods\uboat-the-arcade-mod\Source\latest-manual-savegame-rest.bin'

[AppDomain]::CurrentDomain.add_AssemblyResolve({
    param($sender, $args)
    $name = $args.Name.Split(',')[0] + '.dll'
    $candidate = Join-Path $managed $name
    if (Test-Path $candidate) {
        return [Reflection.Assembly]::LoadFrom($candidate)
    }
    return $null
})

[void][Reflection.Assembly]::LoadFrom((Join-Path $managed 'com.uboat.game.dll'))

$all = [IO.File]::ReadAllBytes($payload)
$offsets = @(25, 37016279, 41387446, 41387499, 41646208, 41646261)

foreach ($off in $offsets) {
    Write-Output "-- offset=$off --"
    if ($off -ge $all.Length) {
        Write-Output 'skip: offset beyond length'
        continue
    }

    $slice = New-Object byte[] ($all.Length - $off)
    [Array]::Copy($all, $off, $slice, 0, $slice.Length)

    $ms = [IO.MemoryStream]::new($slice)
    try {
        $bf = New-Object Runtime.Serialization.Formatters.Binary.BinaryFormatter
        $obj = $bf.Deserialize($ms)
        Write-Output ("type=" + $obj.GetType().FullName)
        Write-Output ("toString=" + $obj.ToString())
    }
    catch {
        Write-Output ("error=" + $_.Exception.Message)
        if ($_.Exception.InnerException) {
            Write-Output ("inner=" + $_.Exception.InnerException.Message)
        }
    }
    finally {
        $ms.Dispose()
    }
}
