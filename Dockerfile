# Start from the official n8n image
FROM n8nio/n8n:latest

# Switch to root to handle patching and directory setup
USER root

# 1. Patch OS-level vulnerabilities (Fixes libpng)
RUN apk update && apk upgrade --no-cache

# 2. Patch Node.js dependencies (Fixes fast-xml-parser, minimatch, tar)
# We navigate to n8n's global installation directory to force the patched versions
RUN cd /usr/local/lib/node_modules/n8n && \
    npm install fast-xml-parser@^5.3.6 minimatch@^10.2.3 tar@^7.5.8

# 3. Create the configuration directory for Choreo
RUN mkdir -p /opt/n8n/config

# 4. Grant ownership of directories to user 10001
RUN chown -R 10001:10001 /home/node /opt/n8n /usr/local/lib/node_modules/n8n && \
    chmod -R 775 /home/node /opt/n8n /usr/local/lib/node_modules/n8n

# 5. Switch to the non-root user required by Choreo Cloud
USER 10001

# 6. Runtime script to source .env and start n8n
CMD ["sh", "-c", "if [ -f /opt/n8n/config/.env ]; then set -a; . /opt/n8n/config/.env; set +a; fi; exec n8n"]
