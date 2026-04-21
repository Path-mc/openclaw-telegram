# Gunakan versi Node.js yang paling ramping
FROM node:20-bullseye-slim

ENV HOME=/app \
    NODE_TLS_REJECT_UNAUTHORIZED=0

WORKDIR /app

# Hanya instal 'curl' untuk kebutuhan screenshot via API (sangat ringan)
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# Instal OpenClaw
RUN npm install -g openclaw@latest

# Salin naskah
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh && chmod -R 777 /app

EXPOSE 8080

# KUNCI HEMAT RAM: Batasi Node.js agar tidak memakai memori lebih dari 300MB
CMD ["sh", "-c", "export NODE_OPTIONS='--max-old-space-size=300' && /app/start.sh"]
