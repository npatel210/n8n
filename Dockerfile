# Start from the official n8n image
FROM n8nio/n8n:latest

# Switch to root temporarily to set up directories and permissions
USER root

# 1. Create the configuration directory where Choreo will mount the .env file
RUN mkdir -p /opt/n8n/config

# 2. Grant ownership of the n8n home directory and custom config dir to user 10001
# (n8n stores its internal data/encryption keys in /home/node/.n8n)
RUN chown -R 10001:10001 /home/node /opt/n8n && \
    chmod -R 775 /home/node /opt/n8n

# 3. Switch to the non-root user required by Choreo Cloud
USER 10001

# 4. Override the CMD to source the .env file before starting n8n.
# This safely wraps inside n8n's default entrypoint.
CMD ["sh", "-c", "if [ -f /opt/n8n/config/.env ]; then set -a; . /opt/n8n/config/.env; set +a; fi; exec n8n"]
