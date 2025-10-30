#!/bin/bash

# ============================================
# WireGuard VPN Setup - Sistema Iluminação Viza
# Configuração automatizada do servidor VPN
# ============================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }

# Verificar root
if [ "$EUID" -ne 0 ]; then
    print_error "Execute como root: sudo ./wireguard_setup.sh"
    exit 1
fi

print_header "WireGuard VPN - Configuração"

# Diretórios
WG_DIR="/etc/wireguard"
KEYS_DIR="$WG_DIR/keys"
CLIENTS_DIR="$(dirname $0)/wireguard"

mkdir -p "$KEYS_DIR"
mkdir -p "$CLIENTS_DIR"
chmod 700 "$KEYS_DIR"

# ============================================
# PARTE 1: Obter Informações
# ============================================

# IP público ou DDNS
echo ""
echo -e "${YELLOW}Qual o seu IP público ou domínio DDNS?${NC}"
echo "Exemplos: 201.45.123.89 ou meudominio.ddns.net"
read -p "IP/Domínio: " SERVER_ENDPOINT

if [ -z "$SERVER_ENDPOINT" ]; then
    print_error "IP/Domínio é obrigatório"
    exit 1
fi

# Porta WireGuard
read -p "Porta WireGuard [51820]: " WG_PORT
WG_PORT=${WG_PORT:-51820}

# Rede interna VPN
VPN_NETWORK="10.0.0.0/24"
SERVER_IP="10.0.0.1"

print_success "Configurações definidas"

# ============================================
# PARTE 2: Gerar Chaves do Servidor
# ============================================
print_header "Gerando Chaves do Servidor"

if [ ! -f "$KEYS_DIR/server_private.key" ]; then
    wg genkey | tee "$KEYS_DIR/server_private.key" | wg pubkey > "$KEYS_DIR/server_public.key"
    chmod 600 "$KEYS_DIR/server_private.key"
    print_success "Chaves do servidor geradas"
else
    print_warning "Chaves do servidor já existem"
fi

SERVER_PRIVATE_KEY=$(cat "$KEYS_DIR/server_private.key")
SERVER_PUBLIC_KEY=$(cat "$KEYS_DIR/server_public.key")

# ============================================
# PARTE 3: Criar Configuração do Servidor
# ============================================
print_header "Criando Configuração do Servidor"

cat > "$WG_DIR/wg0.conf" <<EOF
# ============================================
# WireGuard Server - Sistema Iluminação Viza
# Gerado automaticamente em $(date)
# ============================================

[Interface]
# Chave privada do servidor
PrivateKey = $SERVER_PRIVATE_KEY

# IP interno da VPN
Address = $SERVER_IP/24

# Porta de escuta
ListenPort = $WG_PORT

# Regras de firewall (NAT)
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; iptables -t nat -D POSTROUTING -o wlan0 -j MASQUERADE

# ============================================
# CLIENTES CONFIGURADOS
# ============================================

EOF

chmod 600 "$WG_DIR/wg0.conf"
print_success "Configuração do servidor criada"

# ============================================
# PARTE 4: Habilitar IP Forwarding
# ============================================
print_header "Habilitando IP Forwarding"

if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p
    print_success "IP Forwarding habilitado"
else
    print_warning "IP Forwarding já estava habilitado"
fi

# ============================================
# PARTE 5: Gerar Clientes
# ============================================
print_header "Gerando Configurações de Clientes"

read -p "Quantos clientes deseja gerar? [1]: " NUM_CLIENTS
NUM_CLIENTS=${NUM_CLIENTS:-1}

for i in $(seq 1 $NUM_CLIENTS); do
    echo ""
    read -p "Nome do cliente $i: " CLIENT_NAME
    
    if [ -z "$CLIENT_NAME" ]; then
        CLIENT_NAME="cliente$i"
    fi
    
    CLIENT_IP="10.0.0.$((i+1))"
    CLIENT_PRIVATE_KEY=$(wg genkey)
    CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
    CLIENT_PRESHARED_KEY=$(wg genpsk)
    
    # Salvar chaves do cliente
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
    
    # Criar configuração do cliente
    cat > "$CLIENTS_DIR/${CLIENT_NAME}.conf" <<EOF
# ============================================
# WireGuard Client: $CLIENT_NAME
# Sistema de Iluminação Viza
# ============================================

[Interface]
# Chave privada do cliente (MANTER SEGREDO!)
PrivateKey = $CLIENT_PRIVATE_KEY

# IP interno na VPN
Address = $CLIENT_IP/24

# DNS (usar DNS público)
DNS = 1.1.1.1, 8.8.8.8

[Peer]
# Servidor VPN
PublicKey = $SERVER_PUBLIC_KEY

# Chave pré-compartilhada (segurança extra)
PresharedKey = $CLIENT_PRESHARED_KEY

# Endereço do servidor (IP público ou DDNS)
Endpoint = $SERVER_ENDPOINT:$WG_PORT

# Redirecionar apenas tráfego VPN (split tunnel)
AllowedIPs = 10.0.0.0/24

# Manter conexão ativa
PersistentKeepalive = 25
EOF
    
    print_success "Cliente $CLIENT_NAME configurado (IP: $CLIENT_IP)"
done

# ============================================
# PARTE 6: Iniciar WireGuard
# ============================================
print_header "Iniciando WireGuard"

systemctl enable wg-quick@wg0
systemctl restart wg-quick@wg0

if systemctl is-active --quiet wg-quick@wg0; then
    print_success "WireGuard iniciado com sucesso"
else
    print_error "Erro ao iniciar WireGuard"
    systemctl status wg-quick@wg0
    exit 1
fi

# ============================================
# PARTE 7: Gerar QR Codes
# ============================================
print_header "Gerando QR Codes para Celulares"

cd "$CLIENTS_DIR"
for conf_file in *.conf; do
    if [ -f "$conf_file" ]; then
        client_name=$(basename "$conf_file" .conf)
        qrencode -t ansiutf8 < "$conf_file" > "${client_name}_qr.txt"
        print_success "QR code gerado: ${client_name}_qr.txt"
    fi
done

# ============================================
# RESUMO FINAL
# ============================================
echo ""
print_header "WIREGUARD VPN CONFIGURADO!"

echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════╗"
echo "║   WireGuard VPN Pronto para Uso!              ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo -e "${YELLOW}Informações do Servidor:${NC}"
echo "IP Interno: $SERVER_IP"
echo "Porta: $WG_PORT"
echo "Endpoint: $SERVER_ENDPOINT:$WG_PORT"
echo "Rede VPN: $VPN_NETWORK"

echo ""
echo -e "${YELLOW}Clientes Configurados:${NC}"
for i in $(seq 1 $NUM_CLIENTS); do
    conf_file=$(ls "$CLIENTS_DIR"/*.conf | sed -n "${i}p")
    if [ -f "$conf_file" ]; then
        client_name=$(basename "$conf_file" .conf)
        client_ip="10.0.0.$((i+1))"
        echo "  - $client_name (IP: $client_ip)"
    fi
done

echo ""
echo -e "${YELLOW}Arquivos de Configuração:${NC}"
echo "Servidor: $WG_DIR/wg0.conf"
echo "Clientes: $CLIENTS_DIR/*.conf"

echo ""
echo -e "${YELLOW}QR Codes (para celular):${NC}"
for conf_file in "$CLIENTS_DIR"/*.conf; do
    if [ -f "$conf_file" ]; then
        client_name=$(basename "$conf_file" .conf)
        echo ""
        echo -e "${BLUE}QR Code: $client_name${NC}"
        cat "$CLIENTS_DIR/${client_name}_qr.txt"
    fi
done

echo ""
echo -e "${YELLOW}Status do Servidor:${NC}"
wg show

echo ""
echo -e "${YELLOW}Próximos Passos:${NC}"
echo "1. Configure port forwarding no roteador:"
echo "   - Protocolo: UDP"
echo "   - Porta Externa: $WG_PORT"
echo "   - IP Interno: $(hostname -I | awk '{print $1}')"
echo "   - Porta Interna: $WG_PORT"
echo ""
echo "2. Nos clientes (celular/notebook):"
echo "   - Instale WireGuard"
echo "   - Importe o arquivo .conf ou escaneie QR code"
echo "   - Ative o túnel VPN"
echo ""
echo "3. Teste a conexão:"
echo "   - Conecte via VPN"
echo "   - Acesse: http://10.0.0.1"
echo ""

echo -e "${YELLOW}Adicionar Novos Clientes:${NC}"
echo "cd $CLIENTS_DIR"
echo "sudo ./generate_client.sh nome-do-cliente"
echo ""

echo -e "${GREEN}Configuração concluída com sucesso!${NC}"
