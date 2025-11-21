# Cognica OS Kernel Build Script for PowerShell
# This script builds the kernel and creates a bootable ISO

param(
    [switch]$Clean,
    [switch]$Iso,
    [switch]$Run,
    [switch]$CheckDeps
)

$ErrorActionPreference = "Stop"

# Refresh PATH from registry to pick up newly added paths
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Colors for output
function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

# Check for required tools
function Test-Dependencies {
    Write-Info "Checking dependencies..."
    
    $missing = @()
    
    # Check GCC
    try {
        $gcc = Get-Command gcc -ErrorAction Stop
        Write-Success "[OK] GCC found: $($gcc.Source)"
    } catch {
        $missing += "GCC (MinGW)"
    }
    
    # Check NASM
    $nasmFound = $false
    try {
        $nasm = Get-Command nasm -ErrorAction Stop
        Write-Success "[OK] NASM found: $($nasm.Source)"
        $nasmFound = $true
    } catch {
        # Try alternative method using where.exe
        $nasmPath = & where.exe nasm 2>&1 | Where-Object { $_ -notmatch "INFO:" }
        if ($nasmPath) {
            Write-Success "[OK] NASM found: $nasmPath"
            $nasmFound = $true
        }
    }
    if (-not $nasmFound) {
        $missing += "NASM"
        Write-Warning "  NASM not found. Install from: https://www.nasm.us/"
    }
    
    # Check LD
    try {
        $ld = Get-Command ld -ErrorAction Stop
        Write-Success "[OK] LD found: $($ld.Source)"
    } catch {
        $missing += "LD (MinGW)"
    }
    
    # Check GRUB (for ISO creation)
    try {
        $grub = Get-Command grub-mkrescue -ErrorAction Stop
        Write-Success "[OK] GRUB tools found: $($grub.Source)"
    } catch {
        Write-Warning "  GRUB tools not found. ISO creation will fail."
        Write-Warning "  Install GRUB or use WSL for ISO creation."
    }
    
    if ($missing.Count -gt 0) {
        Write-Error "Missing dependencies: $($missing -join ', ')"
        Write-Info ""
        Write-Info "Installation options:"
        Write-Info "  1. Install NASM: https://www.nasm.us/"
        Write-Info "  2. Use WSL (Windows Subsystem for Linux)"
        Write-Info "  3. Use MSYS2: https://www.msys2.org/"
        return $false
    }
    
    Write-Success "All dependencies found!"
    return $true
}

# Clean build directory
function Invoke-Clean {
    Write-Info "Cleaning build artifacts..."
    if (Test-Path "build") {
        Remove-Item -Recurse -Force "build"
        Write-Success "Build directory cleaned."
    }
    if (Test-Path "isodir") {
        Remove-Item -Recurse -Force "isodir"
        Write-Success "ISO directory cleaned."
    }
}

# Build kernel
function Build-Kernel {
    Write-Info "Building kernel..."
    
    # Create build directory
    if (-not (Test-Path "build")) {
        New-Item -ItemType Directory -Path "build" | Out-Null
    }
    
    # Compile C files
    Write-Info "Compiling C sources..."
    $cFiles = @("kernel.c", "vga.c")
    foreach ($file in $cFiles) {
        if (Test-Path $file) {
            Write-Info "  Compiling $file..."
            $objectFile = "build\$($file.Replace('.c', '.o'))"
            & gcc -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector `
                  -nostartfiles -nodefaultlibs -Wall -Wextra -c `
                  -o $objectFile $file
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to compile $file"
            }
        }
    }
    
    # Assemble ASM files
    Write-Info "Assembling ASM sources..."
    $asmFiles = @("boot.asm")
    foreach ($file in $asmFiles) {
        if (Test-Path $file) {
            Write-Info "  Assembling $file..."
            $objectFile = "build\$($file.Replace('.asm', '.o'))"
            & nasm -f elf32 -o $objectFile $file
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to assemble $file"
            }
        }
    }
    
    # Link kernel
    Write-Info "Linking kernel..."
    $objects = Get-ChildItem "build\*.o" | ForEach-Object { $_.FullName }
    
    # Try to use cross-compiler linker if available, otherwise MinGW ld
    $linkerFound = $false
    $crossLinkers = @("i686-elf-ld", "x86_64-elf-ld", "i586-elf-ld")
    
    foreach ($linkerName in $crossLinkers) {
        try {
            $linker = Get-Command $linkerName -ErrorAction Stop
            Write-Info "  Using cross-compiler linker: $linkerName"
            & $linkerName -m elf_i386 -T linker.ld -o "build\kernel.bin" $objects
            if ($LASTEXITCODE -eq 0) {
                $linkerFound = $true
                break
            }
        } catch {
            # Continue to next linker
        }
    }
    
    if (-not $linkerFound) {
        Write-Warning "Cross-compiler linker not found. MinGW ld only supports PE format."
        Write-Warning "For kernel development, you need:"
        Write-Warning "  1. Install a cross-compiler (i686-elf-gcc or x86_64-elf-gcc)"
        Write-Warning "  2. Or use WSL with: sudo apt-get install gcc-multilib nasm grub-pc-bin"
        Write-Warning ""
        Write-Warning "Attempting with MinGW ld (will likely fail)..."
        & ld -m elf_i386 -T linker.ld -o "build\kernel.bin" $objects
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to link kernel. MinGW ld does not support ELF format. Please install a cross-compiler or use WSL."
        }
    }
    
    Write-Success "Kernel built successfully: build\kernel.bin"
}

# Create ISO
function New-Iso {
    Write-Info "Creating ISO image..."
    
    if (-not (Test-Path "build\kernel.bin")) {
        throw "Kernel not built. Run build first."
    }
    
    # Create ISO directory structure
    $bootDir = "isodir\boot"
    $grubDir = "$bootDir\grub"
    
    if (-not (Test-Path $grubDir)) {
        New-Item -ItemType Directory -Path $grubDir -Force | Out-Null
    }
    
    # Copy kernel
    Copy-Item "build\kernel.bin" "$bootDir\kernel.bin"
    
    # Create GRUB config
    $grubCfgPath = Join-Path $grubDir "grub.cfg"
    $grubConfig = @'
set timeout=0
set default=0

menuentry "Cognica OS" {
    multiboot /boot/kernel.bin
    boot
}
'@
    Set-Content -Path $grubCfgPath -Value $grubConfig -Encoding ASCII
    
    # Create ISO (requires grub-mkrescue)
    try {
        $grub = Get-Command grub-mkrescue -ErrorAction Stop
        Write-Info "Running grub-mkrescue..."
        & grub-mkrescue -o "build\cognica-os.iso" "isodir"
        if ($LASTEXITCODE -ne 0) {
            throw "grub-mkrescue failed"
        }
        Write-Success "ISO created: build\cognica-os.iso"
    } catch {
        Write-Warning "GRUB tools not available. Cannot create ISO."
        Write-Info "You can:"
        Write-Info "  1. Install GRUB for Windows"
        Write-Info "  2. Use WSL to create the ISO"
        Write-Info "  3. Use a Linux VM to create the ISO"
    }
}

# Main execution
if ($CheckDeps) {
    Test-Dependencies
    exit
}

if ($Clean) {
    Invoke-Clean
    exit
}

# Check dependencies first
if (-not (Test-Dependencies)) {
    Write-Error "Cannot build: missing dependencies"
    exit 1
}

# Build kernel
try {
    Build-Kernel
    
    if ($Iso) {
        New-Iso
    }
    
    if ($Run) {
        if (Test-Path "build\cognica-os.iso") {
            Write-Info "Starting QEMU..."
            $qemuUrl = "https://www.qemu.org/"
            Write-Warning "Note: QEMU may not be installed. Install from: $qemuUrl"
            & qemu-system-i386 -cdrom "build\cognica-os.iso"
        } else {
            Write-Warning "ISO not found. Create it first with: .\build.ps1 -Iso"
        }
    }
    
    $successMsg = "Build completed successfully!"
    Write-Success $successMsg
}
catch {
    $errorMsg = $_.Exception.Message
    Write-Host ('Build failed: ' + $errorMsg) -ForegroundColor Red
    exit 1
}

