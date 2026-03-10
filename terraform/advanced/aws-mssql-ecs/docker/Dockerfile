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
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Create directories
RUN mkdir -p /scripts /var/opt/mssql/backup /var/opt/mssql/data /tmp/exports

# Copy export scripts
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# SQL Server environment variables
ENV ACCEPT_EULA=Y
ENV MSSQL_PID=Developer
# NOTE: MSSQL_SA_PASSWORD is NOT set here - it comes from Secrets Manager at runtime

# Add mssql-tools to PATH for BCP and SQLCMD
ENV PATH="$PATH:/opt/mssql-tools18/bin"

# Change ownership to mssql user
RUN chown -R mssql:mssql /scripts /var/opt/mssql /tmp/exports

# Switch back to mssql user for security
USER mssql

WORKDIR /scripts

ENTRYPOINT ["/scripts/entrypoint.sh"]
