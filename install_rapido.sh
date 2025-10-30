#!/bin/bash

# ============================================
# INSTALAÇÃO RÁPIDA - SISTEMA VIZA
# Versão com saída detalhada para debug
# ============================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; exit 1; }

# Verificar root
if [ "$EUID" -ne 0 ]; then
    print_error "Execute como root: sudo bash install_rapido.sh"
fi

REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
PROJECT_DIR="$REAL_HOME/sistema-iluminacao-viza"

clear
echo -e "${BLUE}🚀 INSTALAÇÃO RÁPIDA - SISTEMA VIZA${NC}"
echo ""

# ============================================
# 1. TESTE DE CONEXÃO
# ============================================
print_header "1. Testando Conexão"

echo "Verificando internet..."
if ping -c 1 8.8.8.8 &>/dev/null; then
    print_success "Internet OK"
else
    print_error "SEM INTERNET! Conecte o Raspberry à rede"
fi

sleep 1

# ============================================
# 2. ATUALIZAR SISTEMA
# ============================================
print_header "2. Atualizando Sistema"

echo "Atualizando repositórios (pode demorar 1-2 min)..."
apt update || print_error "Falha no apt update"
print_success "Repositórios atualizados"

echo "Atualizando pacotes (pode demorar 3-5 min)..."
apt upgrade -y || print_error "Falha no apt upgrade"
print_success "Sistema atualizado"

sleep 1

# ============================================
# 3. INSTALAR PACOTES
# ============================================
print_header "3. Instalando Pacotes"

echo "Instalando dependências (pode demorar 2-3 min)..."
apt install -y \
    python3 python3-pip python3-venv python3-dev \
    build-essential git i2c-tools python3-smbus \
    minicom sqlite3 nginx ufw qrencode \
    htop vim nano curl wget || print_error "Falha ao instalar pacotes"

print_success "Pacotes instalados"
sleep 1

# ============================================
# 4. CONFIGURAR HARDWARE
# ============================================
print_header "4. Configurando Hardware"

if ! grep -q "^dtparam=i2c_arm=on" /boot/config.txt; then
    echo "dtparam=i2c_arm=on" >> /boot/config.txt
    print_success "I2C habilitado"
else
    echo "I2C já habilitado"
fi

usermod -a -G dialout,i2c,gpio $REAL_USER
print_success "Permissões configuradas"

sleep 1

# ============================================
# 5. PYTHON
# ============================================
print_header "5. Configurando Python"

cd "$PROJECT_DIR" || print_error "Diretório $PROJECT_DIR não existe"

echo "Criando ambiente virtual..."
sudo -u $REAL_USER python3 -m venv venv

echo "Instalando dependências Python..."
sudo -u $REAL_USER bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"

print_success "Python configurado"
sleep 1

# ============================================
# 6. BANCO DE DADOS
# ============================================
print_header "6. Criando Banco de Dados"

mkdir -p "$PROJECT_DIR/data"
chown $REAL_USER:$REAL_USER "$PROJECT_DIR/data"

echo "Inicializando banco..."
sudo -u $REAL_USER bash -c "cd $PROJECT_DIR && source venv/bin/activate && python3 criar_banco.py"

print_success "Banco criado"
sleep 1

# ============================================
# 7. SERVIÇOS
# ============================================
print_header "7. Configurando Serviços"

cp "$PROJECT_DIR/systemd/iluminacao-viza.service" /etc/systemd/system/
cp "$PROJECT_DIR/systemd/mesh-bridge.service" /etc/systemd/system/

systemctl daemon-reload
systemctl enable iluminacao-viza
systemctl enable mesh-bridge

print_success "Serviços configurados"
sleep 1

# ============================================
# 8. FIREWALL
# ============================================
print_header "8. Configurando Firewall"

ufw --force reset >/dev/null 2>&1
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 51820/udp
ufw --force enable

print_success "Firewall configurado"

# ============================================
# RESUMO
# ============================================
echo ""
print_header "✅ INSTALAÇÃO CONCLUÍDA!"
echo ""
echo "Próximos passos:"
echo "1. Conectar ESP32 Bridge via USB"
echo "2. sudo systemctl start iluminacao-viza"
echo "3. Acessar: http://$(hostname).local"
echo ""
echo "IMPORTANTE: Reinicie o Raspberry:"
echo "  sudo reboot"
echo ""
