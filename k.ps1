# === [CONFIG] ===
$scriptName = "ctf_script.ps1"
$scriptPath = "$env:APPDATA\$scriptName"
$logFile = "$env:APPDATA\ctf_log.txt"
$startupShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\ctf_startup.lnk"

# === [STEP 1] - Generate the background script ===
$scriptContent = @'
# CTF Educational Script - Logging timestamps every 10 seconds
"CTF script started at $(Get-Date)" | Out-File "$env:APPDATA\ctf_log.txt" -Append
while ($true) {
    Start-Sleep -Seconds 10
    "Running at $(Get-Date)" | Out-File "$env:APPDATA\ctf_log.txt" -Append
}
'@

# Create the script file
$scriptContent | Out-File $scriptPath -Encoding UTF8 -Force
Write-Host "✅ Script written to $scriptPath"

# === [STEP 2] - Create shortcut in Startup folder ===
$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($startupShortcut)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
$shortcut.WorkingDirectory = $env:APPDATA
$shortcut.WindowStyle = 7  # Minimized
$shortcut.Save()

Write-Host "✅ Startup shortcut created at $startupShortcut"
Write-Host "🧪 This will run at next login and log to $logFile"

# === [STEP 3] - Run script now (without UAC prompt) ===
$bytes = [System.Text.Encoding]::Unicode.GetBytes('powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $scriptPath + '"')
$encodedCommand = [Convert]::ToBase64String($bytes)
Start-Process powershell.exe -ArgumentList "-EncodedCommand $encodedCommand" -WindowStyle Hidden

Write-Host "✅ Script also started in background for current session"
