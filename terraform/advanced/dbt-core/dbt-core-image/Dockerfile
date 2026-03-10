# =============================================================================
# dbt Core on Snowflake - Dockerfile
# =============================================================================
# Clones dbt project from GitHub at RUNTIME (not build time).
# This means you don't need to rebuild the image when dbt models change.
# =============================================================================

FROM python:3.12-slim

LABEL maintainer="data-team@eftsure.com"
LABEL description="dbt Core with Snowflake adapter"
LABEL dbt-version="1.10.2"

# Environment setup
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DBT_PROFILES_DIR=/app/profiles

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    unzip \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2 (multi-arch)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; \
    fi && \
    unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy profiles and scripts (NO dbt project - cloned at runtime)
COPY profiles/ ./profiles/
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Verify installation
RUN dbt --version

ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]
