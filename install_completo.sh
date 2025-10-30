#!/bin/bash

# ============================================
# INSTALAÇÃO COMPLETA - SISTEMA VIZA
# Um único script que faz TUDO!
# ============================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
}

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Verificar root
if [ "$EUID" -ne 0 ]; then
    print_error "Execute como root: sudo ./install_completo.sh"
    exit 1
fi

# Usuário real
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
PROJECT_DIR="$REAL_HOME/sistema-iluminacao-viza"

clear
echo -e "${MAGENTA}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   🚀 INSTALAÇÃO COMPLETA - SISTEMA DE ILUMINAÇÃO VIZA           ║
║                                                                  ║
║   Este script fará TUDO automaticamente:                        ║
║   ✓ Atualizar sistema                                           ║
║   ✓ Instalar dependências                                       ║
║   ✓ Configurar hardware (I2C, Serial)                           ║
║   ✓ Criar ambiente Python                                       ║
║   ✓ Criar banco de dados                                        ║
║   ✓ Configurar WireGuard VPN (opcional)                         ║
║   ✓ Configurar HTTPS (opcional)                                 ║
║   ✓ Configurar serviços systemd                                 ║
║   ✓ Configurar firewall                                         ║
║   ✓ Iniciar aplicação                                           ║
║                                                                  ║
║   Tempo estimado: 10-15 minutos                                 ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
read -p "Pressione ENTER para iniciar a instalação..." 

# ============================================
# 1. CONFIGURAÇÕES INICIAIS
# ============================================
print_header "1/10 - Configurações Iniciais"

echo "Usuário: $REAL_USER"
echo "Diretório: $PROJECT_DIR"
echo "Hostname atual: $(hostname)"
echo ""

read -p "Deseja alterar o hostname? [s/N]: " alterar_hostname
alterar_hostname=${alterar_hostname:-N}

if [[ $alterar_hostname =~ ^[Ss]$ ]]; then
    read -p "Novo hostname [iluminacao-viza]: " novo_hostname
    novo_hostname=${novo_hostname:-iluminacao-viza}
    
    if [[ "$novo_hostname" =~ ^[a-z0-9-]+$ ]]; then
        HOSTNAME_ATUAL=$(hostname)
        echo "$novo_hostname" > /etc/hostname
        sed -i "s/127.0.1.1.*$HOSTNAME_ATUAL/127.0.1.1\t$novo_hostname/" /etc/hosts
        
        if ! grep -q "127.0.1.1" /etc/hosts; then
            echo "127.0.1.1       $novo_hostname" >> /etc/hosts
        fi
        
        print_success "Hostname configurado: $novo_hostname"
        HOSTNAME_FINAL="$novo_hostname"
    else
        print_error "Hostname inválido! Mantendo: $(hostname)"
        HOSTNAME_FINAL=$(hostname)
    fi
else
    HOSTNAME_FINAL=$(hostname)
    print_warning "Hostname mantido: $HOSTNAME_FINAL"
fi

sleep 2

# ============================================
# 2. ATUALIZAR SISTEMA
# ============================================
print_header "2/10 - Atualizando Sistema"

print_step "Atualizando lista de pacotes..."
apt update -qq

print_step "Atualizando pacotes instalados..."
DEBIAN_FRONTEND=noninteractive apt upgrade -yqq

print_success "Sistema atualizado"
sleep 1

# ============================================
# 3. INSTALAR PACOTES
# ============================================
print_header "3/10 - Instalando Pacotes"

print_step "Instalando pacotes essenciais..."
DEBIAN_FRONTEND=noninteractive apt install -yqq \
    python3 python3-pip python3-venv python3-dev \
    build-essential git i2c-tools python3-smbus \
    minicom sqlite3 nginx ufw fail2ban qrencode \
    htop vim nano curl wget net-tools 2>/dev/null

print_success "Pacotes instalados"
sleep 1

# ============================================
# 4. CONFIGURAR HARDWARE
# ============================================
print_header "4/10 - Configurando Hardware"

print_step "Habilitando I2C..."
if ! grep -q "^dtparam=i2c_arm=on" /boot/config.txt; then
    echo "dtparam=i2c_arm=on" >> /boot/config.txt
    print_success "I2C habilitado"
else
    print_warning "I2C já estava habilitado"
fi

print_step "Configurando permissões de usuário..."
usermod -a -G dialout,i2c,gpio $REAL_USER

print_success "Hardware configurado"
sleep 1

# ============================================
# 5. AMBIENTE PYTHON
# ============================================
print_header "5/10 - Configurando Ambiente Python"

cd "$PROJECT_DIR"

print_step "Criando ambiente virtual..."
sudo -u $REAL_USER python3 -m venv venv

print_step "Instalando dependências Python..."
sudo -u $REAL_USER bash -c "source venv/bin/activate && pip install --upgrade pip -q && pip install -r requirements.txt -q"

print_success "Ambiente Python configurado"
sleep 1

# ============================================
# 6. BANCO DE DADOS
# ============================================
print_header "6/10 - Criando Banco de Dados"

print_step "Criando diretório de dados..."
mkdir -p "$PROJECT_DIR/data"
chown $REAL_USER:$REAL_USER "$PROJECT_DIR/data"

print_step "Inicializando banco de dados..."
sudo -u $REAL_USER bash -c "cd $PROJECT_DIR && source venv/bin/activate && python3 criar_banco.py" 2>/dev/null || {
    sudo -u $REAL_USER bash -c "cd $PROJECT_DIR && source venv/bin/activate && python3 -c 'import sys; sys.path.insert(0, \".\"); from app.database import init_db; init_db()'"
}

print_success "Banco de dados criado"
sleep 1

# ============================================
# 7. WIREGUARD VPN
# ============================================
print_header "7/10 - WireGuard VPN"

read -p "Deseja configurar WireGuard VPN? [s/N]: " config_vpn
config_vpn=${config_vpn:-N}

if [[ $config_vpn =~ ^[Ss]$ ]]; then
    print_step "Instalando WireGuard..."
    apt install -yqq wireguard wireguard-tools
    
    print_warning "Execute depois: sudo ./wireguard_setup.sh"
    print_success "WireGuard instalado (configuração manual necessária)"
else
    print_warning "WireGuard não configurado"
fi

sleep 1

# ============================================
# 8. HTTPS
# ============================================
print_header "8/10 - HTTPS"

read -p "Deseja configurar HTTPS agora? [s/N]: " config_https
config_https=${config_https:-N}

if [[ $config_https =~ ^[Ss]$ ]]; then
    print_warning "Execute depois: sudo ./scripts/setup_https.sh"
    print_success "Lembre-se de configurar HTTPS"
else
    print_warning "HTTPS não configurado (pode fazer depois)"
fi

sleep 1

# ============================================
# 9. SERVIÇOS SYSTEMD
# ============================================
print_header "9/10 - Configurando Serviços"

print_step "Instalando serviço principal..."
cp "$PROJECT_DIR/systemd/iluminacao-viza.service" /etc/systemd/system/

print_step "Instalando serviço bridge..."
cp "$PROJECT_DIR/systemd/mesh-bridge.service" /etc/systemd/system/

print_step "Recarregando systemd..."
systemctl daemon-reload

print_step "Habilitando serviços..."
systemctl enable iluminacao-viza
systemctl enable mesh-bridge

print_success "Serviços configurados"
sleep 1

# ============================================
# 10. FIREWALL
# ============================================
print_header "10/10 - Configurando Firewall"

print_step "Configurando UFW..."
ufw --force reset >/dev/null 2>&1
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 51820/udp comment 'WireGuard VPN'

print_step "Ativando firewall..."
ufw --force enable

print_success "Firewall configurado"
sleep 1

# ============================================
# RESUMO FINAL
# ============================================
clear
echo -e "${GREEN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   ✅ INSTALAÇÃO COMPLETA!                                       ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
print_header "📊 RESUMO DA INSTALAÇÃO"
echo ""

echo -e "${CYAN}Sistema Configurado:${NC}"
echo "  ✓ Sistema atualizado"
echo "  ✓ Pacotes instalados"
echo "  ✓ Hardware configurado (I2C + Serial)"
echo "  ✓ Ambiente Python criado"
echo "  ✓ Banco de dados inicializado"
echo "  ✓ Serviços systemd configurados"
echo "  ✓ Firewall ativado"
echo ""

echo -e "${CYAN}Informações de Acesso:${NC}"
echo "  Hostname: $HOSTNAME_FINAL"
echo "  Local:    http://$HOSTNAME_FINAL.local"
echo "  HTTPS:    https://$HOSTNAME_FINAL.local (após configurar)"
echo "  VPN:      http://10.0.0.1 (após configurar WireGuard)"
echo ""

echo -e "${CYAN}Próximos Passos:${NC}"
echo ""

echo -e "${YELLOW}1. CONECTAR ESP32 BRIDGE${NC}"
echo "   - Gravar firmware: esp32_bridge/ESP32_Mesh_Bridge.ino"
echo "   - Conectar via USB ao Raspberry"
echo "   - Verificar: ls /dev/ttyUSB0"
echo ""

echo -e "${YELLOW}2. INICIAR SERVIÇOS${NC}"
echo "   sudo systemctl start iluminacao-viza"
echo "   sudo systemctl start mesh-bridge"
echo ""

echo -e "${YELLOW}3. VERIFICAR STATUS${NC}"
echo "   sudo systemctl status iluminacao-viza"
echo "   sudo journalctl -u iluminacao-viza -f"
echo ""

echo -e "${YELLOW}4. ACESSAR SISTEMA${NC}"
echo "   Navegador: http://$HOSTNAME_FINAL.local"
echo ""

echo -e "${YELLOW}5. CONFIGURAÇÕES OPCIONAIS${NC}"
echo "   WireGuard VPN: sudo ./wireguard_setup.sh"
echo "   HTTPS:         sudo ./scripts/setup_https.sh"
echo "   Hostname:      sudo ./scripts/setup_hostname.sh"
echo ""

print_warning "IMPORTANTE: Reinicie o Raspberry para aplicar todas as configurações"
echo ""

read -p "Deseja reiniciar agora? [s/N]: " reiniciar
reiniciar=${reiniciar:-N}

if [[ $reiniciar =~ ^[Ss]$ ]]; then
    print_success "Reiniciando em 3 segundos..."
    sleep 3
    reboot
else
    echo ""
    print_warning "Lembre-se de reiniciar manualmente:"
    echo "  sudo reboot"
    echo ""
fi

print_success "Instalação concluída!"
