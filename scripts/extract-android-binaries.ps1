# PowerShell script to build OpenFang for Android aarch64 and extract binaries
# Usage: .\scripts\extract-android-binaries.ps1

param(
    [string]$OutputDir = ".\android-binaries",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

Write-Host "🔨 OpenFang Android aarch64 Build Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Check if Docker is available
Write-Host "`n📋 Checking Docker installation..." -ForegroundColor Yellow
docker --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Create output directory
Write-Host "`n📁 Creating output directory: $OutputDir" -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# Build Docker image
if (-not $SkipBuild) {
    Write-Host "`n🏗️  Building Docker image..." -ForegroundColor Yellow
    $imageTag = "openfang-android-build:latest"
    
    docker build -f Dockerfile.android-build -t $imageTag .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Docker build failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Docker image built successfully" -ForegroundColor Green
} else {
    $imageTag = "openfang-android-build:latest"
    Write-Host "`n⏭️  Skipping Docker build (using existing image)" -ForegroundColor Yellow
}

# Extract binaries using a temporary container
Write-Host "`n📦 Extracting binaries..." -ForegroundColor Yellow

$containerId = docker create $imageTag

# Extract openfang binary
Write-Host "  - Extracting openfang binary..." -ForegroundColor Cyan
docker cp "$($containerId):/usr/local/bin/openfang" "$OutputDir\openfang"
if ($LASTEXITCODE -eq 0) {
    Write-Host "    ✅ openfang extracted" -ForegroundColor Green
} else {
    Write-Host "    ❌ Failed to extract openfang" -ForegroundColor Red
}

# Cleanup container
docker rm $containerId > $null

# Check extracted binary
Write-Host "`n🔍 Verifying extracted binary..." -ForegroundColor Yellow

$binary = @{ Name = "openfang"; Path = "$OutputDir\openfang" }

if (Test-Path $binary.Path) {
    $fileInfo = Get-Item $binary.Path
    Write-Host "  ✅ $($binary.Name): $($fileInfo.Length) bytes" -ForegroundColor Green
    
    # Try to get file info (may fail for cross-compiled binaries)
    try {
        $fileType = file $binary.Path 2>$null
        if ($fileType) {
            Write-Host "     Type: $fileType" -ForegroundColor Gray
        }
    } catch {
        Write-Host "     Type: aarch64-linux-android binary (cross-compiled)" -ForegroundColor Gray
    }
} else {
    Write-Host "  ❌ $($binary.Name): not found" -ForegroundColor Red
}

# Create checksums
Write-Host "`n🔒 Creating checksums..." -ForegroundColor Yellow
Get-FileHash -Path "$OutputDir\openfang" -Algorithm SHA256 | Select-Object Hash, @{Name="File";Expression={"openfang"}} | Export-Csv "$OutputDir\checksums.csv" -NoTypeInformation

Write-Host "  ✅ Checksums saved to $OutputDir\checksums.csv" -ForegroundColor Green

# Display summary
Write-Host "`n📊 Build Summary" -ForegroundColor Cyan
Write-Host "==============" -ForegroundColor Cyan
Write-Host "  Output Directory: $OutputDir" -ForegroundColor White
Write-Host "  Binary extracted:" -ForegroundColor White
Write-Host "    - openfang" -ForegroundColor Green
Write-Host "    - checksums.csv" -ForegroundColor Green

Write-Host "`n🎉 Build completed successfully!" -ForegroundColor Green
Write-Host "`nTo use the binary on Android aarch64:" -ForegroundColor Yellow
Write-Host "  1. Transfer the binary to your Android device" -ForegroundColor White
Write-Host "  2. Make it executable: chmod +x openfang" -ForegroundColor White
Write-Host "  3. Run it on your device" -ForegroundColor White