# ============================================================
# notify.ps1 - Windows lower-right toast notification
# Usage (PowerShell or cmd):
#   powershell -ExecutionPolicy Bypass -File notify.ps1 -Title "Task done" -Message "xx committed & pushed"
# Params:
#   -Title      toast title (default: Task done)
#   -Message    toast body (default: Reasonix finished the task)
#   -DurationMs show duration in ms (default: 5000)
# Note: uses .NET System.Windows.Forms.NotifyIcon; no 3rd-party module needed
# ============================================================
param(
    [string]$Title = 'Task done',
    [string]$Message = 'Reasonix finished the task',
    [int]$DurationMs = 5000,
    [string]$MessageFile = ''  # optional: UTF-8 file to read message from (avoids CLI encoding issues)
)

try {
    if ($MessageFile -ne '' -and (Test-Path $MessageFile)) {
        $Message = [System.IO.File]::ReadAllText($MessageFile, [System.Text.Encoding]::UTF8)
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.SystemIcons]::Information
    $notify.Visible = $true
    $notify.BalloonTipTitle = $Title
    $notify.BalloonTipText = $Message
    $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $notify.ShowBalloonTip($DurationMs)

    # keep process alive long enough for the balloon to show fully
    Start-Sleep -Milliseconds $DurationMs
    $notify.Dispose()
} catch {
    Write-Error "Notification failed: $($_.Exception.Message)"
    exit 1
}