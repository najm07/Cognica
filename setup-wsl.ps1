# WSL Setup Script for Cognica OS Kernel Development
# This script helps set up WSL and install required tools

Write-Host "=== Cognica OS - WSL Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if WSL is installed
$wslInstalled = $false
$wslDistroInstalled = $false

try {
    $wslVersion = wsl --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $wslInstalled = $true
        Write-Host "[OK] WSL is installed" -ForegroundColor Green
        Write-Host "WSL Version:" -ForegroundColor Cyan
        Write-Host $wslVersion
    }
} catch {
    Write-Host "[INFO] WSL not found" -ForegroundColor Yellow
}

# Check if a distribution is installed
if ($wslInstalled) {
    try {
        $distros = wsl --list --quiet 2>&1
        if ($distros -and $distros.Count -gt 0) {
            $wslDistroInstalled = $true
            Write-Host "[OK] Linux distribution installed" -ForegroundColor Green
            Write-Host "Installed distributions:" -ForegroundColor Cyan
            wsl --list
        } else {
            Write-Host "[INFO] No Linux distribution installed" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[INFO] Could not check for distributions" -ForegroundColor Yellow
    }
}

if (-not $wslInstalled) {
    Write-Host ""
    Write-Host "WSL is not installed. To install:" -ForegroundColor Yellow
    Write-Host "  1. Run PowerShell as Administrator" -ForegroundColor White
    Write-Host "  2. Execute: wsl --install" -ForegroundColor White
    Write-Host "  3. Restart your computer" -ForegroundColor White
    Write-Host "  4. Run this script again" -ForegroundColor White
    Write-Host ""
    $install = Read-Host "Would you like to install WSL now? (requires admin) [y/N]"
    if ($install -eq "y" -or $install -eq "Y") {
        Write-Host "Attempting to install WSL..." -ForegroundColor Cyan
        Start-Process powershell -Verb RunAs -ArgumentList "-Command", "wsl --install"
    }
    exit
}

if (-not $wslDistroInstalled) {
    Write-Host ""
    Write-Host "No Linux distribution is installed." -ForegroundColor Yellow
    Write-Host "Available distributions:" -ForegroundColor Cyan
    wsl --list --online
    Write-Host ""
    Write-Host "To install Ubuntu (recommended):" -ForegroundColor Yellow
    Write-Host "  wsl --install -d Ubuntu" -ForegroundColor White
    Write-Host ""
    Write-Host "Or install a different distribution:" -ForegroundColor Yellow
    Write-Host "  wsl --install -d <DistributionName>" -ForegroundColor White
    Write-Host ""
    $install = Read-Host "Would you like to install Ubuntu now? [y/N]"
    if ($install -eq "y" -or $install -eq "Y") {
        Write-Host "Installing Ubuntu..." -ForegroundColor Cyan
        wsl --install -d Ubuntu
        Write-Host ""
        Write-Host "After installation completes, run this script again." -ForegroundColor Green
    }
    exit
}

Write-Host ""
Write-Host "Setting up build environment in WSL..." -ForegroundColor Cyan
Write-Host ""

# Get the current directory in WSL path format
$currentPath = (Get-Location).Path
$wslPath = $currentPath -replace '^([A-Z]):', '/mnt/$1' -replace '\\', '/' -replace '([A-Z])', {$_.Value.ToLower()}

Write-Host "Current directory (WSL): $wslPath" -ForegroundColor Cyan
Write-Host ""

# Create setup script for WSL
$wslSetupScript = @"
#!/bin/bash
echo '=== Installing build tools ==='
sudo apt-get update
sudo apt-get install -y build-essential nasm grub-pc-bin grub-common qemu-system-x86

echo ''
echo '=== Verifying installation ==='
gcc --version
nasm --version
grub-mkrescue --version

echo ''
echo '=== Build instructions ==='
echo 'To build the kernel, run:'
echo '  cd $wslPath'
echo '  make'
echo '  make iso'
echo ''
echo 'To run in QEMU:'
echo '  make run'
"@

$wslSetupScript | Out-File -FilePath "wsl-setup.sh" -Encoding ASCII -NoNewline
Write-Host "Created wsl-setup.sh" -ForegroundColor Green
Write-Host ""

Write-Host "To complete setup, run in WSL:" -ForegroundColor Yellow
Write-Host "  wsl" -ForegroundColor White
Write-Host "  bash wsl-setup.sh" -ForegroundColor White
Write-Host ""
Write-Host "Or run this command:" -ForegroundColor Yellow
Write-Host "  wsl bash -c 'cd $wslPath && bash wsl-setup.sh'" -ForegroundColor White
Write-Host ""

$runNow = Read-Host "Run setup now in WSL? [y/N]"
if ($runNow -eq "y" -or $runNow -eq "Y") {
    Write-Host "Running setup in WSL..." -ForegroundColor Cyan
    wsl bash -c "cd $wslPath && bash wsl-setup.sh"
}

