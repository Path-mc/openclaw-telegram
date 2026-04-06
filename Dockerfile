# Menggunakan mesin Node.js versi 24
FROM node:24-bullseye-slim

# Menginstal OpenClaw secara global (sebagai root)
RUN npm install -g openclaw@2026.3.28

# Di image ini, user 'node' sudah punya UID 1000.
# Kita langsung pakai saja tanpa buat baru.
USER node
ENV HOME=/home/node
WORKDIR $HOME

# Menyalin start.sh ke folder home user node
COPY --chown=node:node start.sh $HOME/start.sh
RUN chmod +x $HOME/start.sh

# Port standar HF
EXPOSE 7860

# Jalankan naskah
CMD ["./start.sh"]
