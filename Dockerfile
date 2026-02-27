FROM n8nio/n8n:latest

USER root

# Install 'bash' if needed (alpine base usually has it, but good to be sure)
RUN apk add --no-cache bash

# Set Choreo User
ARG USER_ID=10001
RUN adduser -u $USER_ID -D choreo-user

# Create the specific mount directory you want
RUN mkdir -p /home/choreo-user/.n8n /opt/n8n/config && \
    chown -R $USER_ID:$USER_ID /home/choreo-user /opt/n8n/config

# Create the entrypoint script
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'if [ -f "$ENV_FILE_PATH" ]; then' >> /entrypoint.sh && \
    echo '  echo "Loading environment from $ENV_FILE_PATH"' >> /entrypoint.sh && \
    echo '  export $(grep -v "^#" "$ENV_FILE_PATH" | xargs)' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    echo 'exec n8n start' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

USER 10001
WORKDIR /home/choreo-user

# Exact location for your Choreo mount
ENV ENV_FILE_PATH=/opt/n8n/config/.env
ENV N8N_USER_FOLDER=/home/choreo-user/.n8n

ENTRYPOINT ["/entrypoint.sh"]
