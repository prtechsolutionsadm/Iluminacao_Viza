#!/bin/bash

# ============================================
# Setup Automatizado - Sistema Iluminação Viza
# Raspberry PI + WireGuard VPN
# ============================================

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
print_header() {
    echo -e "${BLUE}"
    echo "============================================"
    echo "$1"
    echo "============================================"
    echo -e "${NC}"
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

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    print_error "Este script precisa ser executado com sudo"
    echo "Execute: sudo ./setup.sh"
    exit 1
fi

# Obter usuário real (não root)
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
PROJECT_DIR="$REAL_HOME/sistema-iluminacao-viza"

print_header "Sistema de Iluminação Viza - Instalação"
echo "Usuário: $REAL_USER"
echo "Diretório: $PROJECT_DIR"
echo ""

# ============================================
# PARTE 1: Atualizar Sistema
# ============================================
print_header "1/8 - Atualizando Sistema"

apt update
apt upgrade -y

print_success "Sistema atualizado"

# ============================================
# PARTE 2: Instalar Pacotes Essenciais
# ============================================
print_header "2/8 - Instalando Pacotes Essenciais"

apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    git \
    i2c-tools \
    python3-smbus \
    minicom \
    sqlite3 \
    nginx \
    ufw \
    fail2ban \
    qrencode \
    htop \
    vim \
    nano

print_success "Pacotes essenciais instalados"

# ============================================
# PARTE 2.5: Configurar Hostname
# ============================================
print_header "2.5/8 - Configurando Hostname"

HOSTNAME_ATUAL=$(hostname)
echo "Hostname atual: $HOSTNAME_ATUAL"
echo ""
read -p "Deseja alterar o hostname? [s/N]: " alterar_hostname
alterar_hostname=${alterar_hostname:-N}

if [[ $alterar_hostname =~ ^[Ss]$ ]]; then
    read -p "Novo hostname [iluminacao-viza]: " novo_hostname
    novo_hostname=${novo_hostname:-iluminacao-viza}
    
    # Validar hostname
    if [[ "$novo_hostname" =~ ^[a-z0-9-]+$ ]]; then
        echo "$novo_hostname" > /etc/hostname
        sed -i "s/127.0.1.1.*$HOSTNAME_ATUAL/127.0.1.1\t$novo_hostname/" /etc/hosts
        
        # Verificar se linha existe
        if ! grep -q "127.0.1.1" /etc/hosts; then
            echo "127.0.1.1       $novo_hostname" >> /etc/hosts
        fi
        
        print_success "Hostname configurado: $novo_hostname"
        print_warning "Sistema acessível em: http://$novo_hostname.local"
    else
        print_error "Hostname inválido! Mantendo: $HOSTNAME_ATUAL"
    fi
else
    print_warning "Hostname mantido: $HOSTNAME_ATUAL"
    print_warning "Sistema acessível em: http://$HOSTNAME_ATUAL.local"
fi

echo ""

# ============================================
# PARTE 3: Habilitar I2C e Serial
# ============================================
print_header "3/8 - Configurando Hardware (I2C e Serial)"

# Habilitar I2C
if ! grep -q "^dtparam=i2c_arm=on" /boot/config.txt; then
    echo "dtparam=i2c_arm=on" >> /boot/config.txt
    print_success "I2C habilitado"
else
    print_warning "I2C já estava habilitado"
fi

# Adicionar usuário ao grupo dialout (serial)
usermod -a -G dialout $REAL_USER
usermod -a -G i2c $REAL_USER
usermod -a -G gpio $REAL_USER

print_success "Usuário adicionado aos grupos: dialout, i2c, gpio"

# ============================================
# PARTE 4: Criar Ambiente Virtual Python
# ============================================
print_header "4/8 - Configurando Ambiente Python"

cd "$PROJECT_DIR"

# Criar venv como usuário real
sudo -u $REAL_USER python3 -m venv venv

# Ativar venv e instalar dependências
sudo -u $REAL_USER bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"

print_success "Ambiente Python configurado"

# ============================================
# PARTE 5: Configurar Banco de Dados
# ============================================
print_header "5/8 - Criando Banco de Dados"

# Criar diretório de dados
mkdir -p "$PROJECT_DIR/data"
chown $REAL_USER:$REAL_USER "$PROJECT_DIR/data"

# Criar banco de dados
sudo -u $REAL_USER bash -c "cd $PROJECT_DIR && source venv/bin/activate && python3 -c 'from app.database import init_db; init_db()'"

print_success "Banco de dados SQLite criado"

# ============================================
# PARTE 6: Configurar WireGuard VPN
# ============================================
print_header "6/8 - Configurando WireGuard VPN"

read -p "Deseja configurar WireGuard VPN agora? [S/n]: " configure_vpn
configure_vpn=${configure_vpn:-S}

if [[ $configure_vpn =~ ^[Ss]$ ]]; then
    # Instalar WireGuard
    apt install -y wireguard wireguard-tools
    
    # Executar script de configuração
    if [ -f "$PROJECT_DIR/wireguard_setup.sh" ]; then
        chmod +x "$PROJECT_DIR/wireguard_setup.sh"
        bash "$PROJECT_DIR/wireguard_setup.sh"
        print_success "WireGuard VPN configurado"
    else
        print_warning "Script wireguard_setup.sh não encontrado"
    fi
else
    print_warning "WireGuard VPN pulado - configure manualmente depois"
fi

# ============================================
# PARTE 7: Configurar Firewall
# ============================================
print_header "7/8 - Configurando Firewall (UFW)"

# Configurar regras básicas
ufw default deny incoming
ufw default allow outgoing

# Permitir SSH
ufw allow 22/tcp

# Permitir HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Permitir WireGuard
ufw allow 51820/udp

# Ativar firewall (não interativo)
ufw --force enable

print_success "Firewall configurado"

# ============================================
# PARTE 8: Configurar Serviços Systemd
# ============================================
print_header "8/8 - Configurando Serviços Automáticos"

# Copiar arquivos de serviço
if [ -f "$PROJECT_DIR/systemd/iluminacao-viza.service" ]; then
    cp "$PROJECT_DIR/systemd/iluminacao-viza.service" /etc/systemd/system/
    print_success "Serviço iluminacao-viza copiado"
fi

if [ -f "$PROJECT_DIR/systemd/mesh-bridge.service" ]; then
    cp "$PROJECT_DIR/systemd/mesh-bridge.service" /etc/systemd/system/
    print_success "Serviço mesh-bridge copiado"
fi

# Recarregar daemon
systemctl daemon-reload

# Habilitar serviços
systemctl enable iluminacao-viza
systemctl enable mesh-bridge

# Iniciar serviços
systemctl start iluminacao-viza
systemctl start mesh-bridge

print_success "Serviços configurados e iniciados"

# ============================================
# PARTE 9: Configurar Backup Automático
# ============================================
print_header "Configurando Backup Automático"

# Tornar scripts executáveis
chmod +x "$PROJECT_DIR/scripts/"*.sh

# Adicionar ao crontab do usuário
(crontab -u $REAL_USER -l 2>/dev/null; echo "0 2 * * * $PROJECT_DIR/scripts/backup.sh") | crontab -u $REAL_USER -

print_success "Backup diário configurado (2:00 AM)"

# ============================================
# RESUMO FINAL
# ============================================
echo ""
print_header "INSTALAÇÃO CONCLUÍDA!"

echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════╗"
echo "║   Sistema de Iluminação Viza                   ║"
echo "║   Raspberry PI + WireGuard VPN                 ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo "Status dos Serviços:"
systemctl status iluminacao-viza --no-pager | head -3
systemctl status mesh-bridge --no-pager | head -3

echo ""
echo -e "${YELLOW}Próximos Passos:${NC}"
echo "1. Reinicie o Raspberry PI: sudo reboot"
echo "2. Conecte o ESP32 Bridge na porta USB"
echo "3. Conecte o RTC DS3231 via I2C"
echo "4. Acesse o dashboard:"
echo "   Local:  http://raspberrypi.local"
echo "   Remoto: http://10.0.0.1 (via WireGuard)"
echo ""

echo -e "${YELLOW}Verificar Logs:${NC}"
echo "sudo journalctl -u iluminacao-viza -f"
echo "sudo journalctl -u mesh-bridge -f"
echo ""

echo -e "${YELLOW}Gerenciar Serviços:${NC}"
echo "sudo systemctl restart iluminacao-viza"
echo "sudo systemctl status iluminacao-viza"
echo ""

echo -e "${YELLOW}Configurar Clientes VPN:${NC}"
echo "cd $PROJECT_DIR/wireguard"
echo "sudo ./generate_client.sh nome-do-cliente"
echo ""

echo -e "${GREEN}Desenvolvido por Engemase Engenharia${NC}"
echo -e "${GREEN}Para Viza Atacadista - Caçador/SC${NC}"
echo ""

read -p "Deseja reiniciar agora? [s/N]: " reboot_now
if [[ $reboot_now =~ ^[Ss]$ ]]; then
    print_warning "Reiniciando em 5 segundos..."
    sleep 5
    reboot
else
    print_warning "Lembre-se de reiniciar: sudo reboot"
fi
