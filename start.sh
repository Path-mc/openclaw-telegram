#!/bin/bash

# 1. Menyiapkan folder untuk Skill AI
mkdir -p $HOME/.openclaw/workspace/skills/image_generator

# 2. Merakit file openclaw.json secara dinamis (Menggunakan Secrets HF agar aman)
cat << EOF > $HOME/.openclaw/openclaw.json
{
  "gateway": {
    "mode": "local",
    "auth": {
      "mode": "token",
      "token": "${GATEWAY_TOKEN}"
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "open",
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "allowFrom": ["*"],
      "groupPolicy": "allowlist",
      "streaming": "partial"
    }
  },
  "models": {
    "providers": {
      "openai": {
        "baseUrl": "https://integrate.api.nvidia.com/v1",
        "apiKey": "${NVIDIA_API_KEY}",
        "models": [
          {
            "id": "openai/gpt-oss-20b",
            "name": "NVIDIA GPT OSS"
          }
        ]
      },
      "openrouter": {
        "baseUrl": "https://openrouter.ai/api/v1",
        "apiKey": "${OPENROUTER_API_KEY}",
        "models": [
          {
            "id": "qwen/qwen3.6-plus:free",
            "name": "Qwen 3.6 Plus"
          },
          {
            "id": "nvidia/nemotron-nano-12b-v2-vl:free",
            "name": "Nemotron Vision"
          },
          {
            "id": "stepfun/step-3.5-flash:free",
            "name": "Step-3.5-Flash"
          }
        ]
      }
    }
  },
  "plugins": {
    "entries": {
      "tavily": {
        "enabled": true,
        "config": {
          "webSearch": {
            "apiKey": "${TAVILY_API_KEY}"
          }
        }
      }
    }
  },
  "tools": {
    "web": {
      "search": {
        "provider": "tavily"
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/qwen/qwen3.6-plus:free",
        "fallbacks": [
          "openai/openai/gpt-oss-20b"
        ]
      },
      "imageModel": {
        "primary": "openrouter/nvidia/nemotron-nano-12b-v2-vl:free"
      }
    }
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto",
    "restart": true,
    "ownerDisplay": "raw"
  },
  "meta": {
    "lastTouchedVersion": "2026.3.28"
  }
}
EOF

# 3. Merakit script generate_image.js (Menyesuaikan output ke photo.png)
cat << 'EOF' > $HOME/.openclaw/workspace/generate_image.js
import fs from "fs";
const apiKey = process.env.NVIDIA_API_KEY; 
if (!apiKey) process.exit(1);

function readInput() {
    return new Promise((resolve) => {
        let data = "";
        process.stdin.on("data", (chunk) => { data += chunk; });
        process.stdin.on("end", () => { resolve(data.trim()); });
    });
}

const invokeUrl = "https://ai.api.nvidia.com/v1/genai/stabilityai/stable-diffusion-3-medium";
// Nama file disesuaikan ke photo.png sesuai instruksi terbarumu
const outputPath = process.env.HOME + "/.openclaw/workspace/photo.png";

async function main() {
    let userPrompt = await readInput();
    let finalPrompt = userPrompt;
    try {
        const parsedJSON = JSON.parse(userPrompt);
        finalPrompt = Object.values(parsedJSON)[0] || userPrompt;
    } catch (e) {}

    if (!finalPrompt) finalPrompt = "beautiful landscape";
    const payload = {
        "prompt": `${finalPrompt}\n`,
        "cfg_scale": 5,
        "aspect_ratio": "16:9",
        "seed": 0,
        "steps": 50,
        "negative_prompt": "buruk, jelek, cacat, buram"
    };

    try {
        let response = await fetch(invokeUrl, {
            method: "post",
            body: JSON.stringify(payload),
            headers: { "Content-Type": "application/json", "Authorization": `Bearer ${apiKey}`, "Accept": "application/json" }
        });
        let response_body = await response.json();
        let base64Image = response_body.image || (response_body.artifacts && response_body.artifacts[0].base64);

        if (base64Image) {
            fs.writeFileSync(outputPath, base64Image, 'base64');
            console.log(`SUKSES: ${outputPath}`);
        }
    } catch (error) {
        console.error("Error:", error);
    }
}
main();
EOF

# 4. Merakit file SKILL.md (Menggunakan langkah mutlak dan path dinamis HF)
cat << EOF > $HOME/.openclaw/workspace/skills/image_generator/SKILL.md
---
name: custom_image_generator
description: Alat khusus untuk membuat atau melukis gambar (image generation).
---
# Image Generator Skill
Ketika pengguna meminta untuk dibuatkan gambar, lukisan, atau foto, kamu WAJIB mengeksekusi script generator.
**Langkah mutlak:**
1. Terjemahkan permintaan ke prompt bahasa Inggris.
2. Eksekusi perintah terminal ini dengan tool exec:
   \`echo '{"prompt": "PROMPT_INGGRIS"}' | node $HOME/.openclaw/workspace/generate_image.js\`
3. Setelah sukses, kirim pesan berisi gambar dengan Markdown persis seperti ini:
   ![Hasil Gambar]($HOME/.openclaw/workspace/photo.png)
EOF

# 5. Trik Anti-Nganggur (Dummy Web Server agar HF tetap hijau)
cat << 'EOF' > $HOME/server.js
import http from 'http';
const server = http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('OpenClaw Bot sedang aktif melayanimu di Telegram!\n');
});
// HF butuh listen di 0.0.0.0 agar status berubah jadi Running
server.listen(7860, '0.0.0.0', () => {
    console.log('Web server pancingan untuk port 7860 sudah menyala.');
});
EOF
node $HOME/server.js &

# 6. Bangunkan si Lobster!
echo "Menyalakan OpenClaw Gateway..."
openclaw gateway
