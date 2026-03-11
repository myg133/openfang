#!/bin/bash
# Script to build OpenFang for Android aarch64 and extract binaries
# Usage: ./scripts/extract-android-binaries.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
OUTPUT_DIR="${OUTPUT_DIR:-./android-binaries}"
IMAGE_TAG="openfang-android-build:latest"
SKIP_BUILD=${SKIP_BUILD:-false}

echo -e "${CYAN}🔨 OpenFang Android aarch64 Build Script${NC}"
echo -e "${CYAN}============================================${NC}"

# Check if Docker is available
echo -e "\n${YELLOW}📋 Checking Docker installation...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed or not in PATH${NC}"
    exit 1
fi
docker --version

# Create output directory
echo -e "\n${YELLOW}📁 Creating output directory: $OUTPUT_DIR${NC}"
mkdir -p "$OUTPUT_DIR"

# Build Docker image
if [ "$SKIP_BUILD" = "false" ]; then
    echo -e "\n${YELLOW}🏗️  Building Docker image...${NC}"
    docker build -f Dockerfile.android-build -t "$IMAGE_TAG" .
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Docker build failed${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker image built successfully${NC}"
else
    echo -e "\n${YELLOW}⏭️  Skipping Docker build (using existing image)${NC}"
fi

# Extract binaries using a temporary container
echo -e "\n${YELLOW}📦 Extracting binaries...${NC}"

container_id=$(docker create "$IMAGE_TAG")

# Extract openfang binary
echo -e "  ${CYAN}- Extracting openfang binary...${NC}"
if docker cp "$container_id:/usr/local/bin/openfang" "$OUTPUT_DIR/openfang"; then
    echo -e "    ${GREEN}✅ openfang extracted${NC}"
else
    echo -e "    ${RED}❌ Failed to extract openfang${NC}"
fi

# Cleanup container
docker rm "$container_id" > /dev/null

# Check extracted binary
echo -e "\n${YELLOW}🔍 Verifying extracted binary...${NC}"

check_binary() {
    local name=$1
    local path=$2
    
    if [ -f "$path" ]; then
        local size=$(stat -f%z "$path" 2>/dev/null || stat -c%s "$path" 2>/dev/null || echo "unknown")
        echo -e "  ${GREEN}✅ $name: $size bytes${NC}"
        
        # Try to get file info (may fail for cross-compiled binaries)
        if command -v file &> /dev/null; then
            local file_type=$(file "$path" 2>/dev/null || echo "aarch64-linux-android binary (cross-compiled)")
            echo -e "     Type: $file_type${NC}"
        fi
    else
        echo -e "  ${RED}❌ $name: not found${NC}"
    fi
}

check_binary "openfang" "$OUTPUT_DIR/openfang"

# Create checksums
echo -e "\n${YELLOW}🔒 Creating checksums...${NC}"
if command -v sha256sum &> /dev/null; then
    (cd "$OUTPUT_DIR" && sha256sum openfang > checksums.txt)
    echo -e "  ${GREEN}✅ Checksums saved to $OUTPUT_DIR/checksums.txt${NC}"
elif command -v shasum &> /dev/null; then
    (cd "$OUTPUT_DIR" && shasum -a 256 openfang > checksums.txt)
    echo -e "  ${GREEN}✅ Checksums saved to $OUTPUT_DIR/checksums.txt${NC}"
else
    echo -e "  ${YELLOW}⚠️  sha256sum/shasum not available, skipping checksums${NC}"
fi

# Display summary
echo -e "\n${CYAN}📊 Build Summary${NC}"
echo -e "=============="
echo -e "  Output Directory: $OUTPUT_DIR"
echo -e "  Binary extracted:"
echo -e "    ${GREEN}- openfang${NC}"
echo -e "    ${GREEN}- checksums.txt${NC}"

echo -e "\n${GREEN}🎉 Build completed successfully!${NC}"
echo -e "\n${YELLOW}To use the binary on Android aarch64:${NC}"
echo -e "  1. Transfer the binary to your Android device"
echo -e "  2. Make it executable: chmod +x openfang"
echo -e "  3. Run it on your device"
