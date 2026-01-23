# Script to copy all DLLs to the dcc_base.exe directory for runtime
$targetDir = "c:\GitHub\OpenDCC\build_houdini\src\bin\dcc_base\Release"

# Find all .dll files in the build tree (excluding install dir)
$dllFiles = Get-ChildItem -Path "c:\GitHub\OpenDCC\build_houdini" -Recurse -Filter "*.dll" | Where-Object { $_.DirectoryName -notmatch "install" }

# Copy unique DLLs to the target directory
foreach ($dll in $dllFiles) {
    $destPath = Join-Path $targetDir $dll.Name
    if (-not (Test-Path $destPath)) {
        Write-Host "Copying $($dll.Name)"
        Copy-Item $dll.FullName $destPath -ErrorAction SilentlyContinue
    }
}
Write-Host "Done copying DLLs to $targetDir"
