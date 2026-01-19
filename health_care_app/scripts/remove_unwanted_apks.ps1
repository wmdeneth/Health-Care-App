$root = (Resolve-Path -LiteralPath ".").Path
$keep = Join-Path $root 'build\app\outputs\flutter-apk\app-release.apk'
Write-Output "Keep path: $keep"

Get-ChildItem -Path $root -Recurse -Filter *.apk | ForEach-Object {
    $full = $_.FullName
    if ($full -ieq $keep) {
        Write-Output "Keeping: $full"
    } else {
        Write-Output "Removing: $full"
        try {
            Remove-Item -Force $full -ErrorAction Stop
        } catch {
            Write-Output "Failed to remove: $full -> $_"
        }
    }
}
Write-Output "Removal pass complete."