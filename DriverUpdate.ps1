# Driver Update Tool by CHXRITH (Rewritten Version)
# Run as Administrator
# Usage: irm https://raw.githubusercontent.com/CHXRITH/DriverUpdate/main/DriverUpdate_v2.ps1 | iex

# UI Requirements
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Require-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        [System.Windows.Forms.MessageBox]::Show("Run as administrator!", "Permission Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        exit
    }
}
Require-Admin

# UI Setup
$form = New-Object Windows.Forms.Form
$form.Text = "Driver Updater by CHXRITH"
$form.Size = '500,400'
$form.StartPosition = "CenterScreen"
$form.BackColor = 'WhiteSmoke'
$form.Font = New-Object Drawing.Font("Segoe UI", 10)

$status = New-Object Windows.Forms.RichTextBox
$status.Dock = 'Top'
$status.Height = 260
$status.ReadOnly = $true
$status.BackColor = 'White'
$form.Controls.Add($status)

$progress = New-Object Windows.Forms.ProgressBar
$progress.Dock = 'Top'
$progress.Style = 'Continuous'
$form.Controls.Add($progress)

$startBtn = New-Object Windows.Forms.Button
$startBtn.Text = "Start Update"
$startBtn.Dock = 'Top'
$startBtn.Height = 40
$startBtn.BackColor = "#0078D7"
$startBtn.ForeColor = "White"
$startBtn.FlatStyle = "Flat"
$form.Controls.Add($startBtn)

# Status Updater
function Write-Status {
    param([string]$msg)
    $status.AppendText("$msg`r`n")
    $status.ScrollToCaret()
}

# Main Update Function
function Run-DriverUpdate {
    Write-Status "✓ Administrator privileges confirmed"
    $progress.Value = 10

    Write-Status "→ Checking for driver updates..."
    $progress.Value = 20

    # Trigger update scan using Windows Update Agent
    wuauclt.exe /detectnow
    usoclient.exe StartScan

    Write-Status "✓ Update scan triggered"
    Start-Sleep -Seconds 5
    $progress.Value = 50

    Write-Status "→ Starting driver updates..."
    usoclient.exe StartDownload
    Start-Sleep -Seconds 2
    usoclient.exe StartInstall

    $progress.Value = 90
    Write-Status "✓ Driver updates initiated. Please check Windows Update for installation progress."
    $progress.Value = 100
}

# Event
$startBtn.Add_Click({
    $status.Clear()
    $progress.Value = 0
    Run-DriverUpdate
})

# Show Form
$form.Topmost = $true
$form.Add_Shown({$form.Activate()})
$form.ShowDialog()
