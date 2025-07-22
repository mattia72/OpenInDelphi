# PowerShell-Skript zum Aktivieren des Delphi-Fensters
# Autor: mattia72
# Beschreibung: Findet und aktiviert das Delphi IDE-Fenster

# Win32 API Funktionen definieren
Add-Type -MemberDefinition @"
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    [DllImport("user32.dll")]
    public static extern bool IsWindow(IntPtr hWnd);
"@ -Name Win32 -Namespace Win32Functions

# Funktion zum Aktivieren eines Fensters
function Activate-Window {
    param(
        [IntPtr]$WindowHandle,
        [string]$ProcessName
    )
    
    if ([Win32Functions.Win32]::IsWindow($WindowHandle)) {
        # SW_RESTORE = 9 (Fenster wiederherstellen falls minimiert)
        [Win32Functions.Win32]::ShowWindow($WindowHandle, 9) | Out-Null
        [Win32Functions.Win32]::SetForegroundWindow($WindowHandle) | Out-Null
        Write-Host "Delphi window activated for process: $ProcessName"
        return $true
    }
    return $false
}

# Hauptlogik
try {
    $delphiProcesses = Get-Process | Where-Object {
        $_.ProcessName -like "*bds*" -or 
        $_.ProcessName -like "*delphi*" -or 
        $_.MainWindowTitle -like "*Delphi*" -or
        $_.MainWindowTitle -like "*RAD Studio*"
    }
    
    $activated = $false
    
    foreach ($process in $delphiProcesses) {
        if ($process.MainWindowHandle -ne 0) {
            if (Activate-Window -WindowHandle $process.MainWindowHandle -ProcessName $process.ProcessName) {
                $activated = $true
                break
            }
        }
    }
    
    if (-not $activated) {
        Write-Warning "No Delphi window found or could not be activated"
        exit 1
    }
    
    exit 0
    
} catch {
    Write-Error "Error activating Delphi window: $($_.Exception.Message)"
    exit 1
}
