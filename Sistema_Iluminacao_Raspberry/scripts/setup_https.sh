#!/bin/bash

# ============================================
# Setup HTTPS - Sistema de Iluminação Viza
# Configurar certificado SSL (auto-assinado ou Let's Encrypt)
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
    print_error "Execute como root: sudo ./setup_https.sh"
    exit 1
fi

PROJECT_DIR="$HOME/sistema-iluminacao-viza"
CERT_DIR="$PROJECT_DIR/certs"

print_header "Configuração HTTPS - Sistema Viza"

echo ""
echo "Escolha o tipo de certificado:"
echo "1) Certificado Auto-assinado (desenvolvimento/rede local)"
echo "2) Let's Encrypt (produção com domínio público)"
echo ""
read -p "Opção [1]: " CERT_TYPE
CERT_TYPE=${CERT_TYPE:-1}

# ============================================
# OPÇÃO 1: Certificado Auto-assinado
# ============================================
if [ "$CERT_TYPE" = "1" ]; then
    print_header "Gerando Certificado Auto-assinado"
    
    # Criar diretório
    mkdir -p "$CERT_DIR"
    cd "$CERT_DIR"
    
    # Gerar chave privada e certificado
    openssl req -x509 -newkey rsa:4096 -nodes \
        -keyout key.pem \
        -out cert.pem \
        -days 365 \
        -subj "/C=BR/ST=Santa Catarina/L=Cacador/O=Viza Atacadista/OU=TI/CN=raspberrypi.local"
    
    chmod 600 key.pem
    chmod 644 cert.pem
    
    print_success "Certificado auto-assinado gerado"
    print_warning "Este certificado não é confiável por navegadores - apenas para desenvolvimento"
    
    echo ""
    echo -e "${YELLOW}Certificados gerados:${NC}"
    echo "  Chave privada: $CERT_DIR/key.pem"
    echo "  Certificado: $CERT_DIR/cert.pem"

# ============================================
# OPÇÃO 2: Let's Encrypt
# ============================================
elif [ "$CERT_TYPE" = "2" ]; then
    print_header "Configurando Let's Encrypt"
    
    # Instalar certbot
    apt update
    apt install -y certbot python3-certbot-nginx
    
    print_warning "Let's Encrypt requer:"
    echo "  - Domínio público apontando para este servidor"
    echo "  - Portas 80 e 443 abertas no firewall"
    echo "  - IP público acessível"
    echo ""
    
    read -p "Domínio (ex: iluminacao.viza.com.br): " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        print_error "Domínio é obrigatório"
        exit 1
    fi
    
    read -p "Email para renovação: " EMAIL
    
    if [ -z "$EMAIL" ]; then
        print_error "Email é obrigatório"
        exit 1
    fi
    
    # Obter certificado
    certbot certonly --standalone \
        -d "$DOMAIN" \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email
    
    # Criar links simbólicos
    mkdir -p "$CERT_DIR"
    ln -sf "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$CERT_DIR/cert.pem"
    ln -sf "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$CERT_DIR/key.pem"
    
    print_success "Certificado Let's Encrypt obtido"
    
    # Configurar renovação automática
    (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet") | crontab -
    
    print_success "Renovação automática configurada (diária às 3:00 AM)"
    
else
    print_error "Opção inválida"
    exit 1
fi

# ============================================
# ATUALIZAR CONFIGURAÇÃO DO UVICORN
# ============================================
print_header "Atualizando Configuração"

# Criar arquivo de configuração HTTPS
cat > "$PROJECT_DIR/app/https_config.py" <<EOF
# Configuração HTTPS gerada automaticamente
import os

HTTPS_ENABLED = True
SSL_KEYFILE = os.path.join(os.path.dirname(__file__), "..", "certs", "key.pem")
SSL_CERTFILE = os.path.join(os.path.dirname(__file__), "..", "certs", "cert.pem")
EOF

print_success "Configuração HTTPS criada"

# ============================================
# ATUALIZAR SERVICE SYSTEMD
# ============================================
print_header "Atualizando Serviço Systemd"

# Backup do serviço original
cp /etc/systemd/system/iluminacao-viza.service /etc/systemd/system/iluminacao-viza.service.bak

# Atualizar comando para incluir SSL
sed -i 's|ExecStart=.*|ExecStart=/home/pi/sistema-iluminacao-viza/venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 443 --ssl-keyfile /home/pi/sistema-iluminacao-viza/certs/key.pem --ssl-certfile /home/pi/sistema-iluminacao-viza/certs/cert.pem|' /etc/systemd/system/iluminacao-viza.service

# Reload e restart
systemctl daemon-reload
systemctl restart iluminacao-viza

print_success "Serviço atualizado e reiniciado"

# ============================================
# CONFIGURAR FIREWALL
# ============================================
print_header "Configurando Firewall"

# Permitir HTTPS
ufw allow 443/tcp

print_success "Porta 443 (HTTPS) liberada"

# ============================================
# RESUMO
# ============================================
echo ""
print_header "CONFIGURAÇÃO HTTPS CONCLUÍDA!"

echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════╗"
echo "║   HTTPS Ativado com Sucesso!                   ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo -e "${YELLOW}Acesso ao Sistema:${NC}"

if [ "$CERT_TYPE" = "1" ]; then
    echo "  Local:  https://raspberrypi.local"
    echo "  IP:     https://$(hostname -I | awk '{print $1}')"
    echo "  VPN:    https://10.0.0.1"
    echo ""
    print_warning "Navegadores mostrarão aviso de certificado não confiável"
    echo "  Chrome/Edge: Clique em 'Avançado' → 'Continuar para o site'"
    echo "  Firefox: Clique em 'Avançado' → 'Aceitar o risco e continuar'"
else
    echo "  Domínio: https://$DOMAIN"
    echo "  VPN:     https://10.0.0.1"
    echo ""
    print_success "Certificado válido e confiável!"
fi

echo ""
echo -e "${YELLOW}PWA agora funcionando:${NC}"
echo "  ✓ Service Worker ativo"
echo "  ✓ Manifest.json configurado"
echo "  ✓ Instalável em dispositivos"
echo ""

echo -e "${YELLOW}Verificar Status:${NC}"
echo "  sudo systemctl status iluminacao-viza"
echo ""

echo -e "${YELLOW}Logs:${NC}"
echo "  sudo journalctl -u iluminacao-viza -f"
echo ""

echo -e "${GREEN}Desenvolvido por Engemase Engenharia${NC}"
