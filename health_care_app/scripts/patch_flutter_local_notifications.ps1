# Patch flutter_local_notifications Java source in local Pub cache
# - Replaces ambiguous `bigLargeIcon(null)` call with explicit Bitmap cast
# - Removes UTF-8 BOM if present
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\patch_flutter_local_notifications.ps1

$cacheRoot = Join-Path $env:LOCALAPPDATA "Pub\Cache\hosted\pub.dev"
if (-not (Test-Path $cacheRoot)) {
    Write-Error "Pub cache path not found: $cacheRoot"
    exit 2
}

# find the newest flutter_local_notifications package folder
$pkg = Get-ChildItem -Path $cacheRoot -Directory | Where-Object { $_.Name -like 'flutter_local_notifications*' } | Sort-Object Name -Descending | Select-Object -First 1
if (-not $pkg) {
    Write-Error "flutter_local_notifications package not found in $cacheRoot"
    exit 3
}

Write-Host "Found package: $($pkg.FullName)"
$javaRoot = Join-Path $pkg.FullName 'android\src\main\java'
if (-not (Test-Path $javaRoot)) {
    Write-Error "Java source root not found: $javaRoot"
    exit 4
}

$files = Get-ChildItem -Path $javaRoot -Recurse -Filter 'FlutterLocalNotificationsPlugin.java' -ErrorAction SilentlyContinue
if (-not $files -or $files.Count -eq 0) {
    Write-Error "FlutterLocalNotificationsPlugin.java not found under $javaRoot"
    exit 5
}

$modified = 0
foreach ($f in $files) {
    Write-Host "Patching: $($f.FullName)"
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    # remove BOM if present
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Write-Host "Removing BOM from $($f.Name)"
        $bytes = $bytes[3..($bytes.Length - 1)]
    }
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)

    $newText = $text -replace "bigPictureStyle\.bigLargeIcon\(null\);", "bigPictureStyle.bigLargeIcon((android.graphics.Bitmap) null);"

    if ($newText -ne $text) {
        [System.IO.File]::WriteAllText($f.FullName, $newText, [System.Text.Encoding]::UTF8)
        Write-Host "Applied replacement in $($f.Name)"
        $modified++
    } else {
        Write-Host "No replacement needed in $($f.Name)"
    }
}

if ($modified -gt 0) {
    Write-Host "Patched $modified file(s)."
    exit 0
} else {
    Write-Host "No files patched."
    exit 0
}
