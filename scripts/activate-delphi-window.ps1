# PowerShell script to activate the Delphi window
# Author: mattia72
# Description: Finds and activates the Delphi IDE window

# Define Win32 API functions
Add-Type -MemberDefinition @"
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    [DllImport("user32.dll")]
    public static extern bool IsWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);
"@ -Name Win32 -Namespace Win32Functions

# Function to activate a window
function Activate-Window {
    param(
        [IntPtr]$WindowHandle,
        [string]$ProcessName
    )
    
    if ([Win32Functions.Win32]::IsWindow($WindowHandle)) {
        # Check if window is minimized (iconic)
        if ([Win32Functions.Win32]::IsIconic($WindowHandle)) {
            # SW_RESTORE = 9 (restore window if minimized)
            [Win32Functions.Win32]::ShowWindow($WindowHandle, 9) | Out-Null
            Write-Host "Delphi window restored from minimized state for process: $ProcessName"
        } else {
            Write-Host "Delphi window brought to foreground for process: $ProcessName"
        }
        
        # Always set foreground
        [Win32Functions.Win32]::SetForegroundWindow($WindowHandle) | Out-Null
        return $true
    }
    return $false
}

# Main logic
try {
    $delphiProcesses = Get-Process -Name bds
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
