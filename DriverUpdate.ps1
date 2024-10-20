# Windows Driver Updater
# Author: CHXRITH
# Usage: irm https://raw.githubusercontent.com/CHXRITH/DriverUpdate/main/DriverUpdate.ps1 | iex

function Show-AdminWarning {
    $host.UI.WriteErrorLine("Please run as administrator! Right-click PowerShell and select 'Run as Administrator'")
    Start-Sleep -Seconds 3
    exit
}

# Check for admin privileges first
$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
if (-not $isAdmin) {
    Show-AdminWarning
}

# Required assemblies for GUI
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
} catch {
    Write-Host "Error loading Windows Forms assemblies. Error: $_" -ForegroundColor Red
    exit
}

# Error handling preference
$ErrorActionPreference = "Stop"

# Check and install required module
function Install-RequiredModule {
    if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Host "Installing PSWindowsUpdate module..." -ForegroundColor Cyan
        try {
            Install-Module PSWindowsUpdate -Force -Confirm:$false
            Write-Host "PSWindowsUpdate module installed successfully!" -ForegroundColor Green
        } catch {
            Write-Host "Failed to install PSWindowsUpdate module. Error: $_" -ForegroundColor Red
            exit
        }
    }
}

# Create form function
function Initialize-DriverUpdateForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Windows Driver Updater by CHXRITH"
    $form.Size = New-Object System.Drawing.Size(600,450)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::FromArgb(240,240,240)
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    return $form
}

# Create header panel function
function Initialize-HeaderPanel {
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(600,60)
    $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(0,120,215)
    $headerPanel.Dock = "Top"
    return $headerPanel
}

# Initialize all controls
$form = Initialize-DriverUpdateForm
$headerPanel = Initialize-HeaderPanel

# Header label
$headerLabel = New-Object System.Windows.Forms.Label
$headerLabel.Text = "Windows Driver Update Utility"
$headerLabel.ForeColor = [System.Drawing.Color]::White
$headerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$headerLabel.Size = New-Object System.Drawing.Size(400,30)
$headerLabel.Location = New-Object System.Drawing.Point(20,15)
$headerPanel.Controls.Add($headerLabel)

# GitHub Link Label
$githubLink = New-Object System.Windows.Forms.LinkLabel
$githubLink.Text = "GitHub Repository"
$githubLink.Location = New-Object System.Drawing.Point(450,25)
$githubLink.Size = New-Object System.Drawing.Size(120,20)
$githubLink.LinkColor = [System.Drawing.Color]::White
$githubLink.ActiveLinkColor = [System.Drawing.Color]::LightGray
$githubLink.Add_Click({Start-Process "https://github.com/CHXRITH/DriverUpdate"})
$headerPanel.Controls.Add($githubLink)

# Status TextBox
$statusBox = New-Object System.Windows.Forms.RichTextBox
$statusBox.Location = New-Object System.Drawing.Point(20,80)
$statusBox.Size = New-Object System.Drawing.Size(545,180)
$statusBox.ReadOnly = $true
$statusBox.BackColor = [System.Drawing.Color]::White
$statusBox.Font = New-Object System.Drawing.Font("Consolas", 10)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20,270)
$progressBar.Size = New-Object System.Drawing.Size(545,23)
$progressBar.Style = "Continuous"

# Quick Install Command TextBox
$quickInstallBox = New-Object System.Windows.Forms.TextBox
$quickInstallBox.Location = New-Object System.Drawing.Point(20,310)
$quickInstallBox.Size = New-Object System.Drawing.Size(545,23)
$quickInstallBox.ReadOnly = $true
$quickInstallBox.Text = "irm https://raw.githubusercontent.com/CHXRITH/DriverUpdate/main/DriverUpdate.ps1 | iex"

# Copy Button
$copyButton = New-Object System.Windows.Forms.Button
$copyButton.Location = New-Object System.Drawing.Point(445,340)
$copyButton.Size = New-Object System.Drawing.Size(120,30)
$copyButton.Text = "Copy Command"
$copyButton.BackColor = [System.Drawing.Color]::FromArgb(0,120,215)
$copyButton.ForeColor = [System.Drawing.Color]::White
$copyButton.FlatStyle = "Flat"
$copyButton.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText($quickInstallBox.Text)
    Update-StatusBox -Message "Quick install command copied to clipboard!" -Color "Blue"
})

# Start Button
$startButton = New-Object System.Windows.Forms.Button
$startButton.Location = New-Object System.Drawing.Point(20,380)
$startButton.Size = New-Object System.Drawing.Size(120,40)
$startButton.Text = "Start Update"
$startButton.BackColor = [System.Drawing.Color]::FromArgb(0,120,215)
$startButton.ForeColor = [System.Drawing.Color]::White
$startButton.FlatStyle = "Flat"

# Cancel Button
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,380)
$cancelButton.Size = New-Object System.Drawing.Size(120,40)
$cancelButton.Text = "Cancel"
$cancelButton.BackColor = [System.Drawing.Color]::FromArgb(200,0,0)
$cancelButton.ForeColor = [System.Drawing.Color]::White
$cancelButton.FlatStyle = "Flat"
$cancelButton.Enabled = $false

# Function to update status box with colors
function Update-StatusBox {
    param(
        [string]$Message,
        [string]$Color = "Black"
    )
    $statusBox.SelectionStart = $statusBox.TextLength
    $statusBox.SelectionLength = 0
    $statusBox.SelectionColor = $Color
    $statusBox.AppendText("$Message`r`n")
    $statusBox.SelectionColor = $statusBox.ForeColor
    $statusBox.ScrollToCaret()
}

# Function to update drivers
function Update-Drivers {
    param($statusBox, $progressBar)
    
    try {
        # Install required module
        Install-RequiredModule
        Update-StatusBox -Message "✓ Required modules installed" -Color "Green"
        $progressBar.Value = 10

        Update-StatusBox -Message "✓ Administrator privileges confirmed" -Color "Green"
        $progressBar.Value = 20

        # Import Windows Update module
        Update-StatusBox -Message "Loading Windows Update module..." -Color "Blue"
        Import-Module PSWindowsUpdate -Force
        $progressBar.Value = 30
        
        # Scan for updates
        Update-StatusBox -Message "Scanning for available driver updates..." -Color "Blue"
        $updates = Get-WindowsUpdate -MicrosoftUpdate -Category Drivers
        $progressBar.Value = 50

        if ($updates.Count -eq 0) {
            Update-StatusBox -Message "No driver updates found. Your system is up to date!" -Color "Green"
            $progressBar.Value = 100
            return
        }

        Update-StatusBox -Message "Found $($updates.Count) driver updates" -Color "Blue"
        foreach ($update in $updates) {
            Update-StatusBox -Message "• $($update.Title)" -Color "Black"
        }
        
        # Install updates
        Update-StatusBox -Message "`r`nInstalling driver updates..." -Color "Blue"
        $progressBar.Value = 70
        
        Install-WindowsUpdate -MicrosoftUpdate -Category Drivers -AcceptAll -AutoReboot
        
        Update-StatusBox -Message "✓ Driver updates completed successfully!" -Color "Green"
        $progressBar.Value = 100
        
    } catch {
        Update-StatusBox -Message "Error: $($_.Exception.Message)" -Color "Red"
        $progressBar.Value = 0
    }
}

# Button click events
$startButton.Add_Click({
    $statusBox.Clear()
    $progressBar.Value = 0
    $startButton.Enabled = $false
    $cancelButton.Enabled = $true
    Update-Drivers -statusBox $statusBox -progressBar $progressBar
    $startButton.Enabled = $true
    $cancelButton.Enabled = $false
})

$cancelButton.Add_Click({
    Update-StatusBox -Message "Operation cancelled by user." -Color "Orange"
    $progressBar.Value = 0
    $startButton.Enabled = $true
    $cancelButton.Enabled = $false
})

# Add controls to form
$form.Controls.AddRange(@(
    $headerPanel,
    $statusBox,
    $progressBar,
    $quickInstallBox,
    $copyButton,
    $startButton,
    $cancelButton
))

# Show the form
[System.Windows.Forms.Application]::Run($form)
