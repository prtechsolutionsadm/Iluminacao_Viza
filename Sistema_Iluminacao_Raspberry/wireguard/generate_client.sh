#!/bin/bash

# ============================================
# Gerar Novo Cliente WireGuard
# Sistema de Iluminação Viza
# ============================================

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Execute como root: sudo ./generate_client.sh nome-do-cliente${NC}"
    exit 1
fi

# Verificar argumento
if [ -z "$1" ]; then
    echo -e "${RED}Uso: sudo ./generate_client.sh nome-do-cliente${NC}"
    exit 1
fi

CLIENT_NAME="$1"
WG_DIR="/etc/wireguard"
KEYS_DIR="$WG_DIR/keys"
CLIENTS_DIR="$(dirname $0)"

# Verificar se cliente já existe
if [ -f "$CLIENTS_DIR/${CLIENT_NAME}.conf" ]; then
    echo -e "${YELLOW}Cliente $CLIENT_NAME já existe!${NC}"
    read -p "Deseja sobrescrever? [s/N]: " overwrite
    if [[ ! $overwrite =~ ^[Ss]$ ]]; then
        echo "Operação cancelada"
        exit 0
    fi
fi

echo -e "${GREEN}Gerando configuração para: $CLIENT_NAME${NC}"

# Ler configurações do servidor
if [ ! -f "$WG_DIR/wg0.conf" ]; then
    echo -e "${RED}Servidor WireGuard não configurado!${NC}"
    echo "Execute primeiro: sudo ./wireguard_setup.sh"
    exit 1
fi

# Extrair chave pública do servidor
SERVER_PUBLIC_KEY=$(grep "PrivateKey" "$WG_DIR/wg0.conf" | awk '{print $3}' | wg pubkey)
SERVER_ENDPOINT=$(grep "# Endpoint" "$WG_DIR/wg0.conf" | awk '{print $3}' || echo "SEU_IP:51820")
WG_PORT=51820

# Encontrar próximo IP disponível
LAST_IP=$(grep "AllowedIPs" "$WG_DIR/wg0.conf" | awk -F'[./]' '{print $4}' | sort -n | tail -1)
NEXT_IP=$((LAST_IP + 1))
CLIENT_IP="10.0.0.$NEXT_IP"

echo "IP do cliente: $CLIENT_IP"

# Gerar chaves do cliente
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
CLIENT_PRESHARED_KEY=$(wg genpsk)

# Salvar chaves
mkdir -p "$KEYS_DIR"
echo "$CLIENT_PRIVATE_KEY" > "$KEYS_DIR/${CLIENT_NAME}_private.key"
echo "$CLIENT_PUBLIC_KEY" > "$KEYS_DIR/${CLIENT_NAME}_public.key"
echo "$CLIENT_PRESHARED_KEY" > "$KEYS_DIR/${CLIENT_NAME}_preshared.key"
chmod 600 "$KEYS_DIR/${CLIENT_NAME}"*.key

# Adicionar peer ao servidor
cat >> "$WG_DIR/wg0.conf" <<EOF

# Cliente: $CLIENT_NAME
[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
PresharedKey = $CLIENT_PRESHARED_KEY
AllowedIPs = $CLIENT_IP/32

EOF

# Criar arquivo de configuração do cliente
cat > "$CLIENTS_DIR/${CLIENT_NAME}.conf" <<EOF
# ============================================
# WireGuard Client: $CLIENT_NAME
# Sistema de Iluminação Viza
# ============================================

[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP/24
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
PresharedKey = $CLIENT_PRESHARED_KEY
Endpoint = $SERVER_ENDPOINT
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
EOF

echo -e "${GREEN}✓ Cliente criado com sucesso!${NC}"

# Gerar QR Code
if command -v qrencode &> /dev/null; then
    echo ""
    echo -e "${GREEN}QR Code (para celular):${NC}"
    qrencode -t ansiutf8 < "$CLIENTS_DIR/${CLIENT_NAME}.conf"
    qrencode -t ansiutf8 < "$CLIENTS_DIR/${CLIENT_NAME}.conf" > "$CLIENTS_DIR/${CLIENT_NAME}_qr.txt"
else
    echo -e "${YELLOW}⚠ qrencode não instalado. QR Code não gerado.${NC}"
fi

# Reiniciar WireGuard para aplicar mudanças
systemctl restart wg-quick@wg0

echo ""
echo -e "${GREEN}Configuração salva em: $CLIENTS_DIR/${CLIENT_NAME}.conf${NC}"
echo ""
echo -e "${YELLOW}Para usar:${NC}"
echo "1. Celular: Importar arquivo .conf ou escanear QR code"
echo "2. Linux: sudo cp ${CLIENT_NAME}.conf /etc/wireguard/"
echo "         sudo wg-quick up ${CLIENT_NAME}"
echo "3. Windows: Importar arquivo .conf no WireGuard GUI"
echo ""
echo -e "${GREEN}Servidor WireGuard reiniciado!${NC}"
