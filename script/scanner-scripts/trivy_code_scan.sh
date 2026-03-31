#!/bin/bash -e

validate_build_script=$VALIDATE_BUILD_SCRIPT
cloned_package=$CLONED_PACKAGE
cd package-cache

if [ "$validate_build_script" == true ]; then

    echo "[INFO] Fetching latest Trivy version..."
    TRIVY_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    FILE_NAME="trivy_${TRIVY_VERSION#v}_Linux-PPC64LE.tar.gz"
    CHECKSUM_FILE="trivy_${TRIVY_VERSION#v}_checksums.txt"

    echo "[INFO] Downloading Trivy binary..."
    wget -q https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/${FILE_NAME}

    echo "[INFO] Downloading checksum file..."
    wget -q https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/${CHECKSUM_FILE}
    echo "[INFO] Verifying checksum..."

    if grep "${FILE_NAME}" "${CHECKSUM_FILE}" | sha256sum --check --status; then
        echo "[INFO] Checksum verification successful."
        echo "[INFO] Installing Trivy..."
        tar -xzf ${FILE_NAME}
        chmod +x trivy
        sudo mv trivy /usr/bin
        echo "[INFO] Executing Trivy scanner..."
        sudo trivy -q fs --timeout 30m -f json ${cloned_package} > trivy_source_vulnerabilities_results.json
        sudo trivy -q fs --timeout 30m -f cyclonedx ${cloned_package} > trivy_source_sbom_results.cyclonedx
    else
        echo "[ERROR] Checksum verification FAILED for ${FILE_NAME}."
        echo "[ERROR] Trivy will NOT be installed due to integrity verification failure."
        exit 1
    fi
fi
