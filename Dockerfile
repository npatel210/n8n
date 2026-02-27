# Stage 1: Patching with Node 24 LTS
# Pinning the version to satisfy DL3007
FROM node:25.7.0-alpine3.23 AS builder

# 1. Update npm and patch libraries identified in your scans
# Using --force to bypass the peer dependency warnings seen in your logs
RUN npm install -g npm@11.1.0 && \
    npm install -g n8n@1.94.3 fast-xml-parser@5.3.5 form-data@4.0.4 --force

# Stage 2: Final n8n Production Image
# Pinning the version for build stability
FROM n8nio/n8n:1.123.23

USER root

# Overwrite global modules AND binaries from the builder
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin /usr/local/bin

# Choreo Compliance: Direct permission handling for UID 10001
RUN mkdir -p /home/node/.n8n /opt/n8n/config && \
    chmod -R 777 /home/node/.n8n /opt/n8n/config

# Fixed Shell Syntax: Uses double quotes to satisfy SC2016
RUN printf "#!/bin/sh\n\
if [ -f \"/opt/n8n/config/.env\" ]; then\n\
  echo \"Loading environment from /opt/n8n/config/.env...\"\n\
  export \$(grep -v '^#' /opt/n8n/config/.env | xargs)\n\
fi\n\
exec n8n start" > /entrypoint.sh && chmod +x /entrypoint.sh

# Choreo Security Requirement (UID 10001)
USER 10001
WORKDIR /home/node

ENV HOME=/home/node
ENV N8N_USER_FOLDER=/home/node/.n8n

# Port exposure for Choreo reverse proxy
EXPOSE 5678

ENTRYPOINT ["/entrypoint.sh"]
