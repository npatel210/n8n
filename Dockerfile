# Use the official n8n image
FROM n8nio/n8n:latest

# Switch to root to configure permissions for Choreo
USER root

# 1. Create necessary directories
# 2. Fix permissions for UID 10001 (Choreo requirement)
RUN mkdir -p /home/node/.n8n /opt/n8n/config && \
    chown -R 10001:10001 /home/node /opt/n8n/config

# Create a robust entrypoint script
# This script CHECKS if the file exists before trying to load it
RUN printf '#!/bin/sh\n\
if [ -f "/opt/n8n/config/.env" ]; then\n\
  echo "Loading environment variables from /opt/n8n/config/.env..."\n\
  # Load vars while ignoring comments and empty lines\n\
  export $(grep -v "^#" /opt/n8n/config/.env | xargs)\n\
else\n\
  echo "No .env file found at /opt/n8n/config/.env. Using default settings."\n\
fi\n\
exec n8n start' > /entrypoint.sh && chmod +x /entrypoint.sh

# Choreo Security: Must run as a non-root numeric ID
USER 10001
WORKDIR /home/node

# Set environment variables so n8n knows where to write data
ENV HOME=/home/node
ENV N8N_USER_FOLDER=/home/node/.n8n

# Expose n8n default port
EXPOSE 5678

ENTRYPOINT ["/entrypoint.sh"]
