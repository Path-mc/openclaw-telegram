#!/bin/bash

echo "Menyiapkan OpenClaw di Northflank..."

# 1. Menyiapkan folder untuk Skill AI
mkdir -p $HOME/.openclaw/workspace/skills/image_generator

# 2. Merakit file openclaw.json secara dinamis (Mengambil dari Environment Variables Northflank)
cat << EOF > $HOME/.openclaw/openclaw.json
{
  "gateway": {
    "mode": "local",
    "port": 8080,
    "auth": {
      "mode": "token",
      "token": "${GATEWAY_TOKEN:-buka_pintu}"
    }
  },
  "browser": {
    "enabled": true,
    "executablePath": "/usr/bin/chromium",
    "headless": true,
    "noSandbox": true,
    "viewport": { "width": 1280, "height": 720 }
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
      "nvidia": {
        "baseUrl": "https://integrate.api.nvidia.com/v1",
        "apiKey": "${NVIDIA_API_KEY}",
        "api": "openai-completions",
        "models": [
          { "id": "qwen/qwen3.5-397b-a17b", "name": "qwen" }
        ]
      },
      "openrouter": {
        "baseUrl": "https://openrouter.ai/api/v1",
        "apiKey": "${OPENROUTER_API_KEY}",
        "models": [
          { "id": "qwen/qwen3-coder:free", "name": "Qwen Coder" },
          { "id": "nvidia/nemotron-3-super-120b-a12b:free", "name": "Nemotron 3" },
          { "id": "nvidia/nemotron-nano-12b-v2-vl:free", "name": "Nemotron Vision" }
        ]
      }
    }
  },
  "plugins": {
    "entries": {
      "tavily": {
        "enabled": true,
        "config": { "webSearch": { "apiKey": "${TAVILY_API_KEY}" } }
      }
    }
  },
  "tools": {
    "web": { "search": { "provider": "tavily" } }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/qwen/qwen3-coder:free",
        "fallbacks": [
          "openrouter/nvidia/nemotron-3-super-120b-a12b:free",
          "nvidia/qwen/qwen3.5-397b-a17b"
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

# 3. Merakit script generate_image.js untuk Flux Schnell
cat << 'EOF' > $HOME/.openclaw/workspace/generate_image.js
import fs from "fs";
const apiKey = process.env.NVIDIA_API_KEY;
if (!apiKey) {
  console.error("Missing NVIDIA_API_KEY");
  process.exit(1);
}

function readInput() {
  return new Promise((resolve) => {
    let data = "";
    process.stdin.on("data", (chunk) => { data += chunk; });
    process.stdin.on("end", () => { resolve(data.trim()); });
  });
}

const invokeUrl = "https://ai.api.nvidia.com/v1/genai/black-forest-labs/flux.1-schnell";
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
    "seed": Math.floor(Math.random() * 1000000),
    "steps": 4
  };

  try {
    let response = await fetch(invokeUrl, {
      method: "post",
      body: JSON.stringify(payload),
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`,
        "Accept": "application/json"
      }
    });

    if (response.status !== 200) return;

    let response_body = JSON.parse(await response.text());
    let base64Image = response_body.image || (response_body.artifacts && response_body.artifacts[0].base64);
    
    if (base64Image) {
      fs.writeFileSync(outputPath, base64Image, 'base64');
      console.log(`SUKSES: ${outputPath}`);
    }
  } catch (error) {}
}
main();
EOF

# 4. Merakit file SKILL.md Gambar
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
3. Setelah sukses, kirim gambar sebagai attachment Telegram:
   \`openclaw message send --channel telegram --target <TARGET> --media $HOME/.openclaw/workspace/photo.png --force-document\`
EOF

# 5. Bangunkan si Lobster di Port 8080!
echo "Menyalakan OpenClaw Gateway..."
openclaw gateway
