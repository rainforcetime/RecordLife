$file = "D:\Project\HarmonyOSApplication\RecordLife\entry\src\main\resources\base\element\string.json"
$json = Get-Content $file -Raw | ConvertFrom-Json
$names = $json.string.name
$groups = $names | Group-Object
foreach ($g in $groups) {
    if ($g.Count -gt 1) {
        Write-Output "DUPE: $($g.Name) count=$($g.Count)"
    }
}

Write-Output "--- en_US ---"
$file2 = "D:\Project\HarmonyOSApplication\RecordLife\entry\src\main\resources\en_US\element\string.json"
$json2 = Get-Content $file2 -Raw | ConvertFrom-Json
$names2 = $json2.string.name
$groups2 = $names2 | Group-Object
foreach ($g in $groups2) {
    if ($g.Count -gt 1) {
        Write-Output "DUPE: $($g.Name) count=$($g.Count)"
    }
}
