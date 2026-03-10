#!/bin/bash
# =============================================================================
# build-lambda-layer.sh - Build pymssql Lambda Layer
# =============================================================================
# Builds a Lambda layer with pymssql compiled for Amazon Linux 2023
# Requires Docker
# =============================================================================

set -e

echo "Building Lambda layer for pymssql..."

# Clean up any existing build
rm -f lambda_layer.zip

# Build using Amazon Linux 2023 (matches Lambda runtime)
docker run --rm \
    -v "$(pwd):/output" \
    amazonlinux:2023 \
    bash -c "
        echo 'Installing build dependencies...'
        dnf install -y python3.11 python3.11-pip gcc python3.11-devel unixODBC-devel > /dev/null 2>&1
        
        echo 'Installing pymssql...'
        mkdir -p /tmp/layer/python
        pip3.11 install pymssql==2.2.11 -t /tmp/layer/python --quiet
        
        echo 'Creating zip file...'
        cd /tmp/layer && zip -r /output/lambda_layer.zip python -q
        
        echo 'Done!'
    "

echo ""
echo "Lambda layer built: lambda_layer.zip"
echo ""
echo "Upload to AWS with:"
echo "  aws lambda publish-layer-version \\"
echo "      --layer-name pymssql-py311 \\"
echo "      --description 'pymssql for Python 3.11' \\"
echo "      --zip-file fileb://lambda_layer.zip \\"
echo "      --compatible-runtimes python3.11"
echo ""
