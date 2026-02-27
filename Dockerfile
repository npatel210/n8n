# Stage 1: Build & Patch
FROM n8nio/n8n:latest AS builder

USER root

# Update the OS package manager and upgrade all installed packages
# This fixes OS-level vulnerabilities (like OpenSSL or libc)
RUN apt-get update && apt-get upgrade -y && \
    npm install -g npm@latest

# Proactively update the specific library causing issues 
# and audit all other global packages
RUN npm install -g fast-xml-parser@5.3.5 && \
    npm update -g

# Stage 2: Final Secure Image
FROM n8nio/n8n:latest

USER root

# Copy the patched global node_modules from the builder stage
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules

# Apply OS-level security patches to the final image as well
RUN apt-get update && apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# Choreo Compliance: Setup directories and UID 10001
RUN mkdir -p /home/node/.n8n /opt/n8n/config && \
    chown -R 10001:10001 /home/node/.n8n /opt/n8n/config

# Optimized Entrypoint for your Neon DB .env file
RUN printf '#!/bin/sh\n\
if [ -f "/opt/n8n/config/.env" ]; then\n\
  echo "Loading environment from /opt/n8n/config/.env..."\n\
  export $(grep -v "^#" /opt/n8n/config/.env | xargs)\n\
fi\n\
exec n8n start' > /entrypoint.sh && chmod +x /entrypoint.sh

# Choreo Security requirement
USER 10001
WORKDIR /home/node

ENV HOME=/home/node
ENV N8N_USER_FOLDER=/home/node/.n8n

# Port exposure for Choreo reverse proxy
EXPOSE 5678

ENTRYPOINT ["/entrypoint.sh"]
