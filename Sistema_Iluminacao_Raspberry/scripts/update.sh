#!/bin/bash

# ============================================
# Script de Atualização do Sistema
# Sistema de Iluminação Viza
# ============================================

set -e

PROJECT_DIR="$HOME/sistema-iluminacao-viza"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Atualização - Sistema de Iluminação Viza${NC}"
echo -e "${BLUE}============================================${NC}"

# Verificar se está no diretório correto
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Diretório do projeto não encontrado: $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

# Backup antes de atualizar
echo -e "${YELLOW}Criando backup...${NC}"
./scripts/backup.sh

# Parar serviços
echo -e "${YELLOW}Parando serviços...${NC}"
sudo systemctl stop iluminacao-viza
sudo systemctl stop mesh-bridge

# Atualizar código (Git)
if [ -d .git ]; then
    echo -e "${YELLOW}Atualizando código do repositório...${NC}"
    git pull
else
    echo -e "${YELLOW}Não é um repositório Git - pulando atualização de código${NC}"
fi

# Atualizar dependências Python
echo -e "${YELLOW}Atualizando dependências Python...${NC}"
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt --upgrade

# Aplicar migrações de banco (se houver)
if [ -f "app/migrations.py" ]; then
    echo -e "${YELLOW}Aplicando migrações de banco...${NC}"
    python app/migrations.py
fi

# Reiniciar serviços
echo -e "${YELLOW}Reiniciando serviços...${NC}"
sudo systemctl start mesh-bridge
sleep 2
sudo systemctl start iluminacao-viza

# Verificar status
echo -e "${YELLOW}Verificando status dos serviços...${NC}"
sleep 3

if systemctl is-active --quiet iluminacao-viza; then
    echo -e "  iluminacao-viza: ${GREEN}[ATIVO]${NC}"
else
    echo -e "  iluminacao-viza: ${RED}[INATIVO - VERIFICAR LOGS]${NC}"
fi

if systemctl is-active --quiet mesh-bridge; then
    echo -e "  mesh-bridge: ${GREEN}[ATIVO]${NC}"
else
    echo -e "  mesh-bridge: ${RED}[INATIVO - VERIFICAR LOGS]${NC}"
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Atualização concluída!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${YELLOW}Ver logs:${NC}"
echo "  sudo journalctl -u iluminacao-viza -f"
echo "  sudo journalctl -u mesh-bridge -f"
