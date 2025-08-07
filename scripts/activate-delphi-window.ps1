# PowerShell script to activate the Delphi window
# Author: mattia72
# Description: Finds and activates the Delphi IDE window

[CmdletBinding()]
param (
    [switch]$ForceOldSetForegroundMethod
)

# Define WinUser API functions
Add-Type -MemberDefinition @"
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    [DllImport("user32.dll")]
    public static extern bool IsWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern long GetWindowLong(IntPtr hWnd, int nIndex);
    
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
    
    [DllImport("user32.dll")]
    public static extern IntPtr GetParent(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
"@ -Name WinUser -Namespace Win32Api

# Function to get window title
function Get-WindowTitle {
    param([IntPtr]$hWnd)
    
    $windowTitle = New-Object System.Text.StringBuilder 256
    [Win32Api.WinUser]::GetWindowText($hWnd, $windowTitle, 256) | Out-Null
    return $windowTitle.ToString()
}

function Get-IsVisible {
    param([IntPtr]$hWnd)

    if ($hWnd -eq [IntPtr]::Zero) {
        return $false
    }

    # Check visibility using GetWindowLong
    $GWL_STYLE = -0x10
    $WS_VISIBLE = 0x10000000
    $windowStyle = [Win32Api.WinUser]::GetWindowLong($hWnd, $GWL_STYLE)
    return ($windowStyle -band $WS_VISIBLE) -eq $WS_VISIBLE
}

function Get-HasParent {
    param([IntPtr]$hWnd)

    if ($hWnd -eq [IntPtr]::Zero) {
        return $false
    }

    $parent = [Win32Api.WinUser]::GetParent($hWnd)
    return $parent -ne [IntPtr]::Zero
}

# Function to find the main Delphi IDE window
function Find-DelphiMainWindow {
    param([System.UInt32]$ProcessId)
    
    $script:foundWindows = @()
    
    # Create a script block for the enum callback
    $enumCallback = {
        param([IntPtr]$hWnd, [IntPtr]$lParam)
        [System.UInt32]$windowProcessId = 0
        [Win32Api.WinUser]::GetWindowThreadProcessId($hWnd, [ref]$windowProcessId) | Out-Null

        if (($windowProcessId -eq $ProcessId) `
                -and $(-not (Get-HasParent -hWnd $hWnd)) `
                -and $(Get-IsVisible -hWnd $hWnd)) {
            $title = Get-WindowTitle -hWnd $hWnd
            
            # Check if window has non-empty title and no parent (visibility already checked above)
            if (-not [string]::IsNullOrWhiteSpace($title)) {
                Write-Host "Found candidate window: 0x$($hWnd.ToString('X8')) - Title: '$title'"
                $script:foundWindows += @{Handle = $hWnd; Title = $title }
            }
        }
        return $true
    }
    
    # Convert script block to delegate
    $delegate = [Win32Api.WinUser+EnumWindowsProc]$enumCallback
    [Win32Api.WinUser]::EnumWindows($delegate, [IntPtr]::Zero) | Out-Null
    
    return $script:foundWindows
} 

function Set-WindowActive {
    param(
        [IntPtr]$hWnd,
        [string]$ProcessName
    )
    
    if ([Win32Api.WinUser]::IsWindow($hWnd)) {
        $SW_SHOW = 0x5 
        $SW_RESTORE = 0x9 
        $GWL_STYLE = -0x10
        $WS_MINIMIZE = 0x20000000
        
        # Check if window is minimized using GetWindowLong
        $windowStyle = [Win32Api.WinUser]::GetWindowLong($hWnd, $GWL_STYLE)
        Write-Host "Window style: 0x$($windowStyle.ToString('X8'))"
        if (($windowStyle -band $WS_MINIMIZE) -eq $WS_MINIMIZE) {
            $CmdShow = $SW_RESTORE # Restore window if minimized
            Write-Host "Delphi window is minimized"
        }
        else {
            $CmdShow = $SW_SHOW # Use SW_SHOW if not minimized
            Write-Host "Delphi window is not minimized"
        }

        [Win32Api.WinUser]::ShowWindow($hWnd, $CmdShow) | Out-Null
        [Win32Api.WinUser]::SetForegroundWindow($hWnd) | Out-Null
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
        Write-Host "Checking Delphi process: $($process.Id)"
        
        # Find all top-level windows with non-empty titles for this process
        $candidateWindows = @()
        if (-not $ForceOldSetForegroundMethod) {
            $candidateWindows = Find-DelphiMainWindow -ProcessId $process.Id
        }
        if ($candidateWindows.Count -eq 0) {
            $delphiHwnd = $process.MainWindowHandle
        }
        else {
            $window = $candidateWindows | Select-Object -Last 1
            $delphiHwnd = $window.Handle
        }
        Write-Host "Attempting to activate window: 0x$($delphiHwnd.ToString('X8')) - Title: '$($window.Title)'"
        if (Set-WindowActive -hWnd $delphiHwnd -ProcessName $process.ProcessName) {
            $activated = $true
            break
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
