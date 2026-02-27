# Use the official n8n image
FROM n8nio/n8n:latest

# Switch to root to perform security patches
USER root

# 1. Update OS packages (Alpine use 'apk')
# 2. Update npm and the vulnerable fast-xml-parser
RUN apk update && apk upgrade && \
    npm install -g npm@latest fast-xml-parser@5.3.5

# 3. Create directories and set permissions for UID 10001
# Note: In Alpine/n8n image, the default home is /home/node
RUN mkdir -p /home/node/.n8n /opt/n8n/config && \
    chown -R 10001:10001 /home/node /opt/n8n/config

# 4. Entrypoint script to source your mounted Neon DB .env file
RUN printf '#!/bin/sh\n\
if [ -f "/opt/n8n/config/.env" ]; then\n\
  echo "Loading environment from /opt/n8n/config/.env..."\n\
  export $(grep -v "^#" /opt/n8n/config/.env | xargs)\n\
fi\n\
exec n8n start' > /entrypoint.sh && chmod +x /entrypoint.sh

# Choreo security requirement: Run as UID 10001
USER 10001
WORKDIR /home/node

ENV HOME=/home/node
ENV N8N_USER_FOLDER=/home/node/.n8n

# Expose the internal port for the Choreo reverse proxy
EXPOSE 5678

ENTRYPOINT ["/entrypoint.sh"]
