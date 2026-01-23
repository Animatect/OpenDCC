# Check DLL dependencies
$exePath = "c:\GitHub\OpenDCC\build_houdini\src\bin\dcc_base\Release\dcc_base.exe"

# List current DLLs in directory
Write-Host "=== DLLs in exe directory ==="
Get-ChildItem "c:\GitHub\OpenDCC\build_houdini\src\bin\dcc_base\Release\*.dll" | Select-Object Name | Format-Table -HideTableHeaders

# Check if file exists
if (Test-Path $exePath) {
    Write-Host "dcc_base.exe found at: $exePath"
} else {
    Write-Host "ERROR: dcc_base.exe not found!"
}
