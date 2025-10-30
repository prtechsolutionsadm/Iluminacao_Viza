#!/bin/bash

# ============================================
# Gerar Ícones PWA - Sistema de Iluminação Viza
# Cria ícones em diversos tamanhos a partir de uma imagem
# ============================================

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_header "Gerador de Ícones PWA"

# Verificar ImageMagick
if ! command -v convert &> /dev/null; then
    print_error "ImageMagick não instalado"
    echo "Instale com: sudo apt install imagemagick"
    exit 1
fi

# Diretório de imagens
IMAGES_DIR="../static/images"
SOURCE_IMAGE=""

# Verificar se há logo Viza
if [ -f "$IMAGES_DIR/Viza_Logo.png" ]; then
    SOURCE_IMAGE="$IMAGES_DIR/Viza_Logo.png"
    print_success "Usando: Viza_Logo.png"
elif [ -f "$IMAGES_DIR/logo.png" ]; then
    SOURCE_IMAGE="$IMAGES_DIR/logo.png"
    print_success "Usando: logo.png"
else
    print_error "Nenhum logo encontrado"
    echo "Coloque um arquivo logo.png ou Viza_Logo.png em $IMAGES_DIR"
    exit 1
fi

# Tamanhos necessários para PWA
SIZES=(72 96 128 144 152 192 384 512)

echo ""
print_header "Gerando Ícones"

for size in "${SIZES[@]}"; do
    output="$IMAGES_DIR/icon-${size}x${size}.png"
    
    convert "$SOURCE_IMAGE" \
        -resize ${size}x${size} \
        -background white \
        -gravity center \
        -extent ${size}x${size} \
        "$output"
    
    print_success "Gerado: icon-${size}x${size}.png"
done

# Gerar favicon
convert "$SOURCE_IMAGE" \
    -resize 32x32 \
    -background white \
    -gravity center \
    -extent 32x32 \
    "$IMAGES_DIR/favicon.ico"

print_success "Gerado: favicon.ico"

echo ""
print_header "Ícones Gerados com Sucesso!"
echo ""
echo "Arquivos criados em: $IMAGES_DIR"
echo "Total: $((${#SIZES[@]} + 1)) ícones"
echo ""
print_success "Pronto para PWA!"
