FROM n8nio/n8n:latest

USER root

# 1. Setup directories (Now using /tmp/n8n for writable storage)
RUN mkdir -p /opt/n8n/config /tmp/n8n/.n8n

# 2. Create a dedicated, debuggable startup script
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'echo "--- Starting Initialization ---"' >> /start.sh && \
    echo 'if [ -f /opt/n8n/config/.env ]; then' >> /start.sh && \
    echo '  echo "Success: .env file found. Loading variables..."' >> /start.sh && \
    echo '  set -a' >> /start.sh && \
    echo '  . /opt/n8n/config/.env' >> /start.sh && \
    echo '  set +a' >> /start.sh && \
    echo 'else' >> /start.sh && \
    echo '  echo "WARNING: .env file NOT found at /opt/n8n/config/.env"' >> /start.sh && \
    echo 'fi' >> /start.sh && \
    echo 'echo "--- Starting n8n process ---"' >> /start.sh && \
    echo 'exec n8n' >> /start.sh

# 3. Set file permissions so user 10001 can execute and write
RUN chmod +x /start.sh && \
    chown -R 10001:10001 /tmp/n8n /opt/n8n /start.sh && \
    chmod -R 775 /tmp/n8n /opt/n8n

# 4. Environment Variables
ENV N8N_LISTEN_ADDRESS=0.0.0.0
ENV N8N_PORT=5678
# FIX: Explicitly route the home and user folders to the writable /tmp directory
ENV HOME=/tmp/n8n
ENV N8N_USER_FOLDER=/tmp/n8n

# 5. Switch to the non-root user required by Choreo
USER 10001

# 6. Use our custom script as the main entrypoint
ENTRYPOINT ["/start.sh"]
