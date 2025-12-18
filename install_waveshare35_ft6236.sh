#!/bin/bash
set -e

REPO_URL="https://github.com/Norton-breman/waveshare35capacitive_rpi.git"
WORKDIR="/opt/waveshare35"
CONFIG_FILE="/boot/firmware/config.txt"
FIRMWARE_DST="/lib/firmware/st7796s.bin"
OVERLAY_DST="/boot/firmware/overlays/ft6236.dtbo"

echo "=== Installation Waveshare 3.5\" ST7796S + FT6236 (DietPi) ==="

# Vérification root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Lancer ce script avec sudo"
  exit 1
fi

# Dépendances
echo "📦 Installation des dépendances..."
apt update
apt install -y git device-tree-compiler

cd "$WORKDIR"

# Firmware écran
if [ -f "st7796s.bin" ]; then
  echo "📄 Copie du firmware st7796s.bin..."
  cp st7796s.bin "$FIRMWARE_DST"
else
  echo "❌ st7796s.bin introuvable"
  exit 1
fi

# Compilation overlay FT6236
if [ -f "ft6236-overlay.dts" ]; then
  echo "🛠️ Compilation de l'overlay FT6236..."
  dtc -@ -I dts -O dtb -o ft6236.dtbo ft6236-overlay.dts
  cp ft6236.dtbo "$OVERLAY_DST"
else
  echo "❌ ft6236-overlay.dts introuvable"
  exit 1
fi

# Sauvegarde config.txt
if [ ! -f "${CONFIG_FILE}.bak" ]; then
  echo "💾 Sauvegarde de config.txt..."
  cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
fi

# Ajout configuration
if ! grep -q "ST7796S" "$CONFIG_FILE"; then
  echo "✏️ Ajout configuration écran + tactile..."

  cat << 'EOF' >> "$CONFIG_FILE"

# === Waveshare 3.5" ST7796S + FT6236 ===
dtparam=spi=on
dtoverlay=mipi-dbi-spi,speed=48000000
dtparam=compatible=st7796s\0panel-mipi-dbi-spi
dtparam=width=320,height=480,width-mm=49,height-mm=79
dtparam=reset-gpio=27,dc-gpio=25,backlight-gpio=22
dtoverlay=ft6236
# ======================================
EOF

else
  echo "ℹ️ Configuration déjà présente"
fi

echo "✅ Installation terminée."

read -p "🔄 Redémarrer maintenant ? (y/N) : " REBOOT
if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
  reboot
else
  echo "➡️ Redémarre manuellement pour activer l’écran tactile."
fi
