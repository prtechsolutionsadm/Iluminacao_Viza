#!/bin/bash

# ============================================
# Script de Monitoramento de Saúde
# Sistema de Iluminação Viza
# ============================================

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Limites de alerta
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
TEMP_THRESHOLD=75
DISK_THRESHOLD=85

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Monitor de Saúde - Sistema Iluminação Viza${NC}"
echo -e "${BLUE}$(date)${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# ============================================
# CPU
# ============================================
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
CPU_INT=${CPU_USAGE%.*}

echo -e "${YELLOW}CPU:${NC}"
echo -n "  Uso: $CPU_USAGE% "
if [ "$CPU_INT" -gt "$CPU_THRESHOLD" ]; then
    echo -e "${RED}[ALERTA!]${NC}"
else
    echo -e "${GREEN}[OK]${NC}"
fi

# ============================================
# TEMPERATURA
# ============================================
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
    TEMP_C=$((TEMP/1000))
    
    echo -e "${YELLOW}Temperatura:${NC}"
    echo -n "  CPU: ${TEMP_C}°C "
    if [ "$TEMP_C" -gt "$TEMP_THRESHOLD" ]; then
        echo -e "${RED}[ALERTA!]${NC}"
    else
        echo -e "${GREEN}[OK]${NC}"
    fi
fi

# ============================================
# MEMÓRIA
# ============================================
MEMORY=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
MEMORY_INT=${MEMORY%.*}

echo -e "${YELLOW}Memória:${NC}"
echo -n "  Uso: $MEMORY_INT% "
if [ "$MEMORY_INT" -gt "$MEMORY_THRESHOLD" ]; then
    echo -e "${RED}[ALERTA!]${NC}"
else
    echo -e "${GREEN}[OK]${NC}"
fi

# ============================================
# DISCO
# ============================================
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')

echo -e "${YELLOW}Disco:${NC}"
echo -n "  Uso: $DISK_USAGE% "
if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
    echo -e "${RED}[ALERTA!]${NC}"
else
    echo -e "${GREEN}[OK]${NC}"
fi

# ============================================
# SERVIÇOS
# ============================================
echo -e "${YELLOW}Serviços:${NC}"

# Iluminação Viza
if systemctl is-active --quiet iluminacao-viza; then
    echo -e "  iluminacao-viza: ${GREEN}[ATIVO]${NC}"
else
    echo -e "  iluminacao-viza: ${RED}[INATIVO]${NC}"
fi

# Mesh Bridge
if systemctl is-active --quiet mesh-bridge; then
    echo -e "  mesh-bridge: ${GREEN}[ATIVO]${NC}"
else
    echo -e "  mesh-bridge: ${RED}[INATIVO]${NC}"
fi

# WireGuard
if systemctl is-active --quiet wg-quick@wg0; then
    echo -e "  wireguard: ${GREEN}[ATIVO]${NC}"
    PEERS=$(sudo wg show wg0 2>/dev/null | grep peer | wc -l)
    echo "    Peers conectados: $PEERS"
else
    echo -e "  wireguard: ${RED}[INATIVO]${NC}"
fi

# ============================================
# REDE
# ============================================
echo -e "${YELLOW}Rede:${NC}"
IP_LOCAL=$(hostname -I | awk '{print $1}')
echo "  IP Local: $IP_LOCAL"

if systemctl is-active --quiet wg-quick@wg0; then
    IP_VPN=$(ip addr show wg0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
    echo "  IP VPN: $IP_VPN"
fi

# ============================================
# PORTA SERIAL (ESP32)
# ============================================
echo -e "${YELLOW}ESP32 Bridge:${NC}"
if [ -e /dev/ttyUSB0 ]; then
    echo -e "  Porta: /dev/ttyUSB0 ${GREEN}[DETECTADO]${NC}"
else
    echo -e "  Porta: /dev/ttyUSB0 ${RED}[NÃO ENCONTRADO]${NC}"
fi

# ============================================
# UPTIME
# ============================================
UPTIME=$(uptime -p)
echo -e "${YELLOW}Uptime:${NC}"
echo "  $UPTIME"

echo ""
echo -e "${BLUE}============================================${NC}"
