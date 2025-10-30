#!/bin/bash

# ============================================
# Script de Backup Automático
# Sistema de Iluminação Viza
# ============================================

set -e

# Configurações
PROJECT_DIR="$HOME/sistema-iluminacao-viza"
BACKUP_DIR="$PROJECT_DIR/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="backup_$TIMESTAMP.tar.gz"
RETENTION_DAYS=30

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Backup - Sistema de Iluminação Viza${NC}"
echo -e "${GREEN}$(date)${NC}"
echo -e "${GREEN}============================================${NC}"

# Criar diretório de backups
mkdir -p "$BACKUP_DIR"

# Arquivos e diretórios para backup
BACKUP_ITEMS=(
    "$PROJECT_DIR/data"
    "$PROJECT_DIR/app/config.py"
    "$PROJECT_DIR/wireguard/*.conf"
    "/etc/wireguard/wg0.conf"
    "$PROJECT_DIR/.env"
)

# Criar arquivo temporário com lista de itens
TEMP_LIST=$(mktemp)
for item in "${BACKUP_ITEMS[@]}"; do
    if [ -e "$item" ] || ls $item 1> /dev/null 2>&1; then
        echo "$item" >> "$TEMP_LIST"
    fi
done

# Criar backup
echo -e "${YELLOW}Criando backup...${NC}"
tar -czf "$BACKUP_DIR/$BACKUP_NAME" -T "$TEMP_LIST" 2>/dev/null || true

rm "$TEMP_LIST"

# Verificar criação
if [ -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
    SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)
    echo -e "${GREEN}✓ Backup criado com sucesso!${NC}"
    echo "  Arquivo: $BACKUP_NAME"
    echo "  Tamanho: $SIZE"
else
    echo -e "${RED}✗ Erro ao criar backup${NC}"
    exit 1
fi

# Remover backups antigos
echo -e "${YELLOW}Removendo backups antigos (>${RETENTION_DAYS} dias)...${NC}"
find "$BACKUP_DIR" -name "backup_*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete

# Listar backups disponíveis
echo -e "${YELLOW}Backups disponíveis:${NC}"
ls -lh "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null | tail -5 || echo "Nenhum backup encontrado"

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Backup concluído!${NC}"
echo -e "${GREEN}============================================${NC}"
