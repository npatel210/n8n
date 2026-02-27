FROM n8nio/n8n:latest

USER root

# 1. Setup directories
RUN mkdir -p /opt/n8n/config /home/node/.n8n

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

# 3. Set file permissions so user 10001 can execute the script and write data
RUN chmod +x /start.sh && \
    chown -R 10001:10001 /home/node /opt/n8n /start.sh && \
    chmod -R 775 /home/node /opt/n8n

# 4. Force n8n to listen on all network interfaces (Critical for Choreo health checks)
ENV N8N_LISTEN_ADDRESS=0.0.0.0
ENV N8N_PORT=5678

# 5. Switch to the non-root user required by Choreo
USER 10001

# 6. Use our custom script as the main entrypoint
ENTRYPOINT ["/start.sh"]
