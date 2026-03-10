FROM mcr.microsoft.com/mssql/server:2022-latest

# Switch to root for installations
USER root

# Install required utilities
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    unzip \
    gzip \
    bc \
    dnsutils \
    telnet \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Create directories
RUN mkdir -p /scripts /tmp/exports

# Copy export scripts
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# Add mssql-tools to PATH for BCP and SQLCMD
ENV PATH="$PATH:/opt/mssql-tools18/bin"

# Change ownership
RUN chown -R mssql:mssql /scripts /tmp/exports

# Switch back to mssql user for security
USER mssql

WORKDIR /scripts

ENTRYPOINT ["/scripts/entrypoint.sh"]
