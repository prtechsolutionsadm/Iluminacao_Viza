#!/bin/bash

# ============================================
# Configurar Access Point - Raspberry PI
# Sistema de Iluminação Viza
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
    print_error "Execute como root: sudo ./setup_ap.sh"
    exit 1
fi

print_header "Configurar Access Point WiFi"

echo ""
print_warning "ATENÇÃO: Isso transformará o Raspberry em um roteador WiFi"
print_warning "O Raspberry precisará estar conectado via Ethernet para ter internet"
echo ""
read -p "Deseja continuar? [s/N]: " CONTINUAR

if [ "$CONTINUAR" != "s" ] && [ "$CONTINUAR" != "S" ]; then
    echo "Operação cancelada"
    exit 0
fi

# ============================================
# CONFIGURAÇÕES
# ============================================

read -p "SSID do Access Point [Iluminacao_Viza]: " AP_SSID
AP_SSID=${AP_SSID:-Iluminacao_Viza}

read -p "Senha do WiFi [1F#hVL1lM#]: " AP_PASSWORD
AP_PASSWORD=${AP_PASSWORD:-"1F#hVL1lM#"}

read -p "Canal WiFi [6]: " AP_CHANNEL
AP_CHANNEL=${AP_CHANNEL:-6}

AP_IP="192.168.4.1"
AP_NETMASK="255.255.255.0"
DHCP_START="192.168.4.10"
DHCP_END="192.168.4.50"

# ============================================
# INSTALAR PACOTES
# ============================================
print_header "Instalando Pacotes"

apt update
apt install -y hostapd dnsmasq

print_success "Pacotes instalados"

# ============================================
# CONFIGURAR INTERFACE
# ============================================
print_header "Configurando Interface"

# Parar serviços
systemctl stop hostapd
systemctl stop dnsmasq

# Configurar IP estático para wlan0
cat > /etc/dhcpcd.conf.ap <<EOF
# Access Point Configuration
interface wlan0
    static ip_address=${AP_IP}/24
    nohook wpa_supplicant
EOF

# Adicionar ao dhcpcd.conf se não existir
if ! grep -q "# Access Point Configuration" /etc/dhcpcd.conf; then
    cat /etc/dhcpcd.conf.ap >> /etc/dhcpcd.conf
fi

print_success "Interface configurada"

# ============================================
# CONFIGURAR DNSMASQ (DHCP)
# ============================================
print_header "Configurando DHCP"

# Backup
cp /etc/dnsmasq.conf /etc/dnsmasq.conf.bak

# Configurar
cat > /etc/dnsmasq.conf <<EOF
# Interface para servir DHCP
interface=wlan0

# Pool DHCP
dhcp-range=${DHCP_START},${DHCP_END},${AP_NETMASK},24h

# DNS
dhcp-option=6,8.8.8.8,8.8.4.4

# Domain
domain=viza.local
EOF

print_success "DHCP configurado"

# ============================================
# CONFIGURAR HOSTAPD (Access Point)
# ============================================
print_header "Configurando Access Point"

cat > /etc/hostapd/hostapd.conf <<EOF
# Interface
interface=wlan0

# Driver
driver=nl80211

# SSID
ssid=${AP_SSID}

# Canal
channel=${AP_CHANNEL}

# Modo
hw_mode=g

# País
country_code=BR

# 802.11n
ieee80211n=1
wmm_enabled=1

# Segurança WPA2
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_passphrase=${AP_PASSWORD}
EOF

# Configurar daemon
echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' > /etc/default/hostapd

print_success "Access Point configurado"

# ============================================
# CONFIGURAR NAT (se tiver Ethernet)
# ============================================
print_header "Configurando NAT"

# Habilitar IP forwarding
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
echo 1 > /proc/sys/net/ipv4/ip_forward

# Configurar iptables
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

# Salvar regras
sh -c "iptables-save > /etc/iptables.rules"

# Restaurar regras no boot
cat > /etc/network/if-up.d/iptables <<'EOF'
#!/bin/sh
iptables-restore < /etc/iptables.rules
EOF

chmod +x /etc/network/if-up.d/iptables

print_success "NAT configurado"

# ============================================
# HABILITAR SERVIÇOS
# ============================================
print_header "Habilitando Serviços"

systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq

# Reiniciar dhcpcd
systemctl restart dhcpcd

sleep 2

# Iniciar serviços
systemctl start hostapd
systemctl start dnsmasq

print_success "Serviços habilitados"

# ============================================
# RESUMO
# ============================================
echo ""
print_header "ACCESS POINT CONFIGURADO!"

echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════╗"
echo "║   WiFi Access Point Ativo!                     ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo -e "${YELLOW}Informações do Access Point:${NC}"
echo "  SSID: ${AP_SSID}"
echo "  Senha: ${AP_PASSWORD}"
echo "  Canal: ${AP_CHANNEL}"
echo "  IP Raspberry: ${AP_IP}"
echo "  DHCP Range: ${DHCP_START} - ${DHCP_END}"
echo ""

echo -e "${YELLOW}Para acessar o sistema:${NC}"
echo "  1. Conectar no WiFi: ${AP_SSID}"
echo "  2. Acessar: http://${AP_IP}"
echo "  3. Com HTTPS: https://${AP_IP}"
echo ""

echo -e "${YELLOW}Verificar status:${NC}"
echo "  sudo systemctl status hostapd"
echo "  sudo systemctl status dnsmasq"
echo ""

echo -e "${YELLOW}Ver clientes conectados:${NC}"
echo "  sudo tail -f /var/log/syslog | grep DHCP"
echo ""

print_warning "IMPORTANTE: O Raspberry precisa estar conectado via Ethernet para ter internet"
print_warning "Reinicie o Raspberry para aplicar todas as configurações"
echo ""

read -p "Deseja reiniciar agora? [s/N]: " REINICIAR

if [ "$REINICIAR" = "s" ] || [ "$REINICIAR" = "S" ]; then
    print_success "Reiniciando..."
    sleep 2
    reboot
fi
