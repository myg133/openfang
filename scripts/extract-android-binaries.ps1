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

# Extract openfang-api binary
Write-Host "  - Extracting openfang-api binary..." -ForegroundColor Cyan
docker cp "$($containerId):/usr/local/bin/openfang-api" "$OutputDir\openfang-api"
if ($LASTEXITCODE -eq 0) {
    Write-Host "    ✅ openfang-api extracted" -ForegroundColor Green
} else {
    Write-Host "    ❌ Failed to extract openfang-api" -ForegroundColor Red
}

# Cleanup container
docker rm $containerId > $null

# Check extracted binaries
Write-Host "`n🔍 Verifying extracted binaries..." -ForegroundColor Yellow

$binaries = @(
    @{ Name = "openfang"; Path = "$OutputDir\openfang" },
    @{ Name = "openfang-api"; Path = "$OutputDir\openfang-api" }
)

foreach ($binary in $binaries) {
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
}

# Create checksums
Write-Host "`n🔒 Creating checksums..." -ForegroundColor Yellow
Get-FileHash -Path "$OutputDir\openfang" -Algorithm SHA256 | Select-Object Hash, @{Name="File";Expression={"openfang"}} | Export-Csv "$OutputDir\checksums.csv" -NoTypeInformation
Get-FileHash -Path "$OutputDir\openfang-api" -Algorithm SHA256 | Select-Object Hash, @{Name="File";Expression={"openfang-api"}} | Export-Csv "$OutputDir\checksums.csv" -Append -NoTypeInformation

Write-Host "  ✅ Checksums saved to $OutputDir\checksums.csv" -ForegroundColor Green

# Display summary
Write-Host "`n📊 Build Summary" -ForegroundColor Cyan
Write-Host "==============" -ForegroundColor Cyan
Write-Host "  Output Directory: $OutputDir" -ForegroundColor White
Write-Host "  Binaries extracted:" -ForegroundColor White
Write-Host "    - openfang" -ForegroundColor Green
Write-Host "    - openfang-api" -ForegroundColor Green
Write-Host "    - checksums.csv" -ForegroundColor Green

Write-Host "`n🎉 Build completed successfully!" -ForegroundColor Green
Write-Host "`nTo use the binaries on Android aarch64:" -ForegroundColor Yellow
Write-Host "  1. Transfer the binaries to your Android device" -ForegroundColor White
Write-Host "  2. Make them executable: chmod +x openfang openfang-api" -ForegroundColor White
Write-Host "  3. Run them on your device" -ForegroundColor White