# Gunakan Node.js versi 20 yang stabil dan ringan
FROM node:20-bullseye-slim

# Matikan interaksi instalasi dan set environment
ENV DEBIAN_FRONTEND=noninteractive \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    HOME=/app \
    NODE_TLS_REJECT_UNAUTHORIZED=0

WORKDIR /app

# Instal Chromium dan semua dependensinya agar screenshot tidak error
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libglib2.0-0 \
    libnss3 \
    libpango-1.0-0 \
    libx11-6 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    libxss1 \
    libxtst6 \
 && rm -rf /var/lib/apt/lists/*

# Instal OpenClaw versi terbaru
RUN npm install -g openclaw@2026.3.28

# Salin naskah start.sh ke dalam container
COPY start.sh /app/start.sh

# Beri izin eksekusi penuh
RUN chmod +x /app/start.sh && chmod -R 777 /app

# Buka port standar (Northflank biasanya meroute port 8080)
EXPOSE 8080

# Jalankan naskah
CMD ["/app/start.sh"]
