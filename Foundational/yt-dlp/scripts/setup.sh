#!/usr/bin/env bash
set -euo pipefail

echo "📥 yt-dlp Setup"
echo "==============="

# 1. Install yt-dlp
echo ""
echo "📦 Installing yt-dlp..."
if command -v yt-dlp &>/dev/null; then
  echo "   Already installed: $(yt-dlp --version)"
  echo "   Updating..."
  pip3 install --break-system-packages -U yt-dlp 2>&1 | tail -1
else
  pip3 install --break-system-packages -U yt-dlp 2>&1 | tail -1
fi
echo "   ✅ yt-dlp $(yt-dlp --version)"

# 2. Verify ffmpeg
echo ""
echo "🎬 Checking ffmpeg..."
if command -v ffmpeg &>/dev/null; then
  echo "   ✅ ffmpeg installed"
else
  echo "   ❌ ffmpeg not found — required for merging video+audio and format conversion"
  echo "   Install: sudo apt install ffmpeg"
  exit 1
fi

# 3. Create default output directory
echo ""
DOWNLOAD_DIR="${HOME}/Downloads/yt-dlp"
mkdir -p "$DOWNLOAD_DIR"
echo "📁 Default download directory: $DOWNLOAD_DIR"

# 4. Create config with sensible defaults
echo ""
CONFIG_DIR="${HOME}/.config/yt-dlp"
CONFIG_FILE="${CONFIG_DIR}/config"
mkdir -p "$CONFIG_DIR"

if [ ! -f "$CONFIG_FILE" ]; then
  cat > "$CONFIG_FILE" << 'CONF'
# yt-dlp defaults — edit as needed
--embed-metadata
--embed-thumbnail
--embed-subs
--sub-langs all
--merge-output-format mp4
-o %(title)s [%(id)s].%(ext)s
CONF
  echo "⚙️  Created config: $CONFIG_FILE"
else
  echo "⚙️  Config already exists: $CONFIG_FILE"
fi

echo ""
echo "✅ Ready! Try: yt-dlp \"https://www.youtube.com/watch?v=dQw4w9WgXcQ\""
