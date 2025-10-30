#!/bin/bash

# ============================================
# Configurar Hostname - Raspberry PI
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
    print_error "Execute como root: sudo ./setup_hostname.sh"
    exit 1
fi

print_header "Configurar Hostname Personalizado"

# Hostname atual
HOSTNAME_ATUAL=$(hostname)
echo ""
echo -e "${YELLOW}Hostname atual:${NC} $HOSTNAME_ATUAL"
echo ""

# Novo hostname
read -p "Novo hostname [iluminacao-viza]: " NOVO_HOSTNAME
NOVO_HOSTNAME=${NOVO_HOSTNAME:-iluminacao-viza}

# Validar hostname
if [[ ! "$NOVO_HOSTNAME" =~ ^[a-z0-9-]+$ ]]; then
    print_error "Hostname inválido! Use apenas letras minúsculas, números e hífens"
    exit 1
fi

echo ""
print_warning "O hostname será alterado para: $NOVO_HOSTNAME"
print_warning "Após a mudança, o sistema estará acessível em:"
echo "  http://$NOVO_HOSTNAME.local"
echo ""

read -p "Confirmar mudança? [s/N]: " CONFIRMAR

if [ "$CONFIRMAR" != "s" ] && [ "$CONFIRMAR" != "S" ]; then
    echo "Operação cancelada"
    exit 0
fi

# ============================================
# ALTERAR HOSTNAME
# ============================================
print_header "Alterando Hostname"

# Arquivo /etc/hostname
echo "$NOVO_HOSTNAME" > /etc/hostname

# Arquivo /etc/hosts
sed -i "s/127.0.1.1.*$HOSTNAME_ATUAL/127.0.1.1\t$NOVO_HOSTNAME/" /etc/hosts

# Verificar se linha existe, se não, adicionar
if ! grep -q "127.0.1.1" /etc/hosts; then
    echo "127.0.1.1       $NOVO_HOSTNAME" >> /etc/hosts
fi

print_success "Arquivos de configuração atualizados"

# ============================================
# ATUALIZAR SERVIÇOS
# ============================================
print_header "Atualizando Serviços"

# Reiniciar hostname service
systemctl restart avahi-daemon

print_success "Serviços atualizados"

# ============================================
# RESUMO
# ============================================
echo ""
print_header "HOSTNAME CONFIGURADO!"

echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════╗"
echo "║   Hostname Alterado com Sucesso!               ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo -e "${YELLOW}Hostname anterior:${NC} $HOSTNAME_ATUAL"
echo -e "${YELLOW}Hostname novo:${NC} $NOVO_HOSTNAME"
echo ""

echo -e "${YELLOW}Acesso ao sistema:${NC}"
echo "  Local:  http://$NOVO_HOSTNAME.local"
echo "  HTTPS:  https://$NOVO_HOSTNAME.local"
echo "  SSH:    ssh pi@$NOVO_HOSTNAME.local"
echo ""

echo -e "${YELLOW}Acesso via VPN (se configurado):${NC}"
echo "  http://10.0.0.1"
echo ""

print_warning "É NECESSÁRIO REINICIAR o Raspberry para aplicar completamente"
echo ""

read -p "Deseja reiniciar agora? [s/N]: " REINICIAR

if [ "$REINICIAR" = "s" ] || [ "$REINICIAR" = "S" ]; then
    print_success "Reiniciando..."
    sleep 2
    reboot
else
    echo ""
    print_warning "Lembre-se de reiniciar manualmente:"
    echo "  sudo reboot"
    echo ""
fi
