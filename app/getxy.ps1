param([string]$Name)
$env:PATH = "E:\dev\android-sdk\platform-tools;" + $env:PATH
adb -s 1027525383001648 shell uiautomator dump /sdcard/ui.xml 2>&1 | Out-Null
adb -s 1027525383001648 pull /sdcard/ui.xml "$env:TEMP\ui_cur.xml" 2>&1 | Out-Null
$x = Get-Content "$env:TEMP\ui_cur.xml" -Raw
$m = [regex]::Match($x, ('content-desc="' + [regex]::Escape($Name) + '"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'))
if ($m.Success) {
    $cx = ([int]$m.Groups[1].Value + [int]$m.Groups[3].Value)/2
    $cy = ([int]$m.Groups[2].Value + [int]$m.Groups[4].Value)/2
    Write-Output "$cx,$cy"
} else {
    Write-Output "NOTFOUND"
}
