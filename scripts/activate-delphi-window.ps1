# PowerShell script to activate the Delphi window
# Author: mattia72
# Description: Finds and activates the Delphi IDE window

# Define WinUser API functions
Add-Type -MemberDefinition @"
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    [DllImport("user32.dll")]
    public static extern bool IsWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);
"@ -Name WinUser -Namespace Win32Api

# Function to activate a window
function Activate-Window {
    param(
        [IntPtr]$WindowHandle,
        [string]$ProcessName
    )
    
    if ([Win32Api.WinUser]::IsWindow($WindowHandle)) {
        $SW_SHOW = 5 
        $SW_RESTORE = 9 
        # Check if window is minimized (iconic)
        if ([Win32Api.WinUser]::IsIconic($WindowHandle)) {
            $CmdShow = $SW_RESTORE # Restore window if minimized
            Write-Host "Delphi window is minimized"
        }
        else {
            $CmdShow = $SW_SHOW # Use SW_SHOW if not minimized
            Write-Host "Delphi window is not minimized"
        }

        [Win32Api.WinUser]::ShowWindow($WindowHandle, $CmdShow) | Out-Null
        [Win32Api.WinUser]::SetForegroundWindow($WindowHandle) | Out-Null
        Write-Host "Delphi window brought to foreground for process: $ProcessName"
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
    
}
catch {
    Write-Error "Error activating Delphi window: $($_.Exception.Message)"
    exit 1
}
