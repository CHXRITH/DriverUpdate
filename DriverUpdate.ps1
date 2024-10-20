# Windows Driver Updater
# Author: CHXRITH
# Usage: irm https://raw.githubusercontent.com/CHXRITH/DriverUpdate/main/DriverUpdate.ps1 | iex

# Check for admin privileges first
$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
if (-not $isAdmin) {
    Write-Host "Please run as administrator! Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Red
    Start-Sleep -Seconds 3
    exit
}

# Required assemblies for GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Error handling preference
$ErrorActionPreference = "Stop"

# Check and install required module
function Install-RequiredModule {
    if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Host "Installing PSWindowsUpdate module..."
        Install-Module PSWindowsUpdate -Force -Confirm:$false
    }
}

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Driver Updater by CHXRITH"
$form.Size = New-Object System.Drawing.Size(600,450)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(240,240,240)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# Create header panel
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Size = New-Object System.Drawing.Size(600,60)
$headerPanel.BackColor = [System.Drawing.Color]::FromArgb(0,120,215)
$headerPanel.Dock = "Top"

# Header label
$headerLabel = New-Object System.Windows.Forms.Label
$headerLabel.Text = "Windows Driver Update Utility"
$headerLabel.ForegroundColor = [System.Drawing.Color]::White
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
    $statusBox.AppendText("Quick install command copied to clipboard!`r`n")
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

# Function to update drivers
function Update-Drivers {
    param($statusBox, $progressBar)
    
    try {
        # Install required module
        Install-RequiredModule
        $statusBox.AppendText("✓ Required modules installed`r`n")
        $progressBar.Value = 10

        $statusBox.AppendText("✓ Administrator privileges confirmed`r`n")
        $progressBar.Value = 20

        # Import Windows Update module
        $statusBox.AppendText("Loading Windows Update module...`r`n")
        Import-Module PSWindowsUpdate -Force
        $progressBar.Value = 30
        
        # Scan for updates
        $statusBox.AppendText("Scanning for available driver updates...`r`n")
        $updates = Get-WindowsUpdate -MicrosoftUpdate -Category Drivers
        $progressBar.Value = 50

        if ($updates.Count -eq 0) {
            $statusBox.AppendText("No driver updates found. Your system is up to date!`r`n")
            $progressBar.Value = 100
            return
        }

        $statusBox.AppendText("Found $($updates.Count) driver updates`r`n")
        foreach ($update in $updates) {
            $statusBox.AppendText("• $($update.Title)`r`n")
        }
        
        # Install updates
        $statusBox.AppendText("`r`nInstalling driver updates...`r`n")
        $progressBar.Value = 70
        
        Install-WindowsUpdate -MicrosoftUpdate -Category Drivers -AcceptAll -AutoReboot
        
        $statusBox.AppendText("✓ Driver updates completed successfully!`r`n")
        $progressBar.Value = 100
        
    } catch {
        $statusBox.AppendText("Error: $($_.Exception.Message)`r`n")
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
    $statusBox.AppendText("Operation cancelled by user.`r`n")
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
