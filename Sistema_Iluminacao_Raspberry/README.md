# Sistema de Iluminação Viza - Raspberry PI + WireGuard VPN

## 🚀 Descrição do Projeto

Sistema completo de controle de iluminação industrial migrado de ESP32 para **Raspberry PI**, com acesso remoto via **WireGuard VPN**.

### Arquitetura do Sistema

```
┌─────────────────────────────────────────────┐
│   CELULAR/NOTEBOOK (Acesso Remoto)         │
│   WireGuard Client                          │
└──────────────┬──────────────────────────────┘
               │
               │ Túnel VPN Criptografado
               │ (ChaCha20, porta 51820)
               │
┌──────────────▼──────────────────────────────┐
│   RASPBERRY PI (Servidor Mestre)            │
│                                             │
│   ✓ FastAPI Web Server (Python 3.10+)      │
│   ✓ WireGuard VPN Server                   │
│   ✓ SQLite Database                        │
│   ✓ ESP32 Mesh Bridge (Serial USB)         │
│   ✓ Dashboard Web Responsivo               │
│   ✓ RTC DS3231 (I2C)                       │
│   ✓ PWA + HTTPS (Instalável como App)     │
│   ✓ Service Worker (Offline First)        │
│                                             │
└──────────────┬──────────────────────────────┘
               │
               │ ESP-NOW Mesh Protocol
               │ (via ESP32 USB Bridge)
               │
     ┌─────────┴──────────┐
     │                    │
┌────▼───┐         ┌──────▼──┐
│ ESP32  │   ...   │ ESP32   │  (10 escravos)
│ Escravo│         │ Escravo │
│ 1      │         │ 10      │
└────────┘         └─────────┘
  225 Luminárias LED Industriais
```

---

## 📦 Estrutura do Projeto

```
Sistema_Iluminacao_Raspberry/
├── README.md                      # Este arquivo
├── INSTALL.md                     # Guia de instalação detalhado
├── requirements.txt               # Dependências Python
├── setup.sh                       # Script de instalação automatizada
├── wireguard_setup.sh            # Configuração WireGuard VPN
│
├── app/                          # Aplicação principal
│   ├── __init__.py
│   ├── main.py                   # Servidor FastAPI
│   ├── config.py                 # Configurações
│   ├── database.py               # Gerenciamento SQLite
│   ├── mesh_bridge.py            # Comunicação ESP32 Mesh
│   ├── models.py                 # Modelos de dados
│   ├── routes/                   # Endpoints API
│   │   ├── __init__.py
│   │   ├── controle.py           # Controle de luminárias
│   │   ├── dashboard.py          # Dados dashboard
│   │   ├── agendamentos.py       # Sistema de agendamentos
│   │   └── monitor.py            # Monitoramento sistema
│   └── utils/                    # Utilitários
│       ├── __init__.py
│       ├── rtc.py                # Integração RTC DS3231
│       └── consumo.py            # Cálculos de consumo
│
├── static/                       # Arquivos estáticos (migrados ESP32)
│   ├── css/
│   │   └── style.css
│   ├── js/
│   │   └── app.js
│   └── img/
│       └── logo_viza.png
│
├── templates/                    # Páginas HTML (migradas ESP32)
│   ├── index.html               # Dashboard principal
│   ├── controle.html            # Controle manual
│   ├── visualizacao.html        # Visualização detalhada
│   ├── consumo.html             # Análise de consumo
│   ├── agendamentos.html        # Configuração de agendamentos
│   └── 404.html                 # Página de erro
│
├── systemd/                      # Serviços Linux
│   ├── iluminacao-viza.service  # Serviço principal
│   └── mesh-bridge.service      # Serviço bridge ESP32
│
├── wireguard/                    # Configurações VPN
│   ├── wg0.conf                 # Config servidor
│   ├── cliente-exemplo.conf     # Config cliente exemplo
│   └── generate_client.sh       # Gerar novos clientes
│
├── scripts/                      # Scripts auxiliares
│   ├── backup.sh                # Backup automático
│   ├── update.sh                # Atualização sistema
│   └── monitor.sh               # Monitoramento saúde
│
└── docs/                         # Documentação adicional
    ├── API.md                   # Documentação API REST
    ├── VPN.md                   # Guia configuração VPN
    ├── TROUBLESHOOTING.md       # Solução de problemas
    └── CHANGELOG.md             # Histórico de versões
```

---

## 🛠️ Requisitos de Hardware

### Raspberry PI (Recomendado)
- **Modelo**: Raspberry PI 4 Model B (4GB RAM)
- **Armazenamento**: microSD 32GB+ (Classe 10) ou SSD USB
- **Fonte**: 5V 3A oficial Raspberry PI
- **Extras**: Case com ventilação, dissipadores

### Periféricos
- **ESP32 DevKit** (1 unidade) - Bridge Mesh via USB
- **RTC DS3231** - Relógio de tempo real (I2C)
- **Cabo USB-A para Micro-USB** - Conexão ESP32

### Escravos ESP32 (Mantidos)
- 10x ESP32 (sem alterações necessárias)
- Sensores BH1750 (mantidos)
- Módulos de controle PWM (mantidos)

---

## 🚀 Instalação Rápida (10 minutos)

### Passo 1: Preparar Raspberry PI

```bash
# 1. Baixar Raspberry Pi OS Lite (64-bit)
# https://www.raspberrypi.com/software/

# 2. Gravar no microSD com Raspberry Pi Imager
# - Habilitar SSH
# - Configurar WiFi (opcional)
# - Definir usuário: pi / senha: raspberry

# 3. Inserir cartão e ligar Raspberry PI
```

### Passo 2: Conectar via SSH

```bash
# Do seu computador
ssh pi@raspberrypi.local
# ou
ssh pi@<IP_DO_RASPBERRY>

# Senha padrão: raspberry
```

### Passo 3: Executar Instalação Automatizada

```bash
# Baixar projeto
cd ~
git clone https://github.com/engemase/sistema-iluminacao-viza.git
cd sistema-iluminacao-viza

# OU copiar arquivos via SCP/WinSCP

# Executar instalação completa
chmod +x setup.sh
sudo ./setup.sh

# Responder perguntas:
# - Configurar WireGuard? [S/n]: S
# - IP público ou DDNS: seu-dominio.ddns.net
# - Porta ESP32: /dev/ttyUSB0
```

### Passo 4: Acessar Sistema

```bash
# Local (na rede)
http://raspberrypi.local
http://192.168.1.X

# Remoto (via WireGuard)
http://10.0.0.1
```

---

## 🔧 Instalação Manual (Detalhada)

Consulte [INSTALL.md](INSTALL.md) para instruções passo a passo detalhadas.

---

## 🔐 Configuração WireGuard VPN

### Servidor (Raspberry PI)

```bash
# Instalar WireGuard
sudo apt update
sudo apt install wireguard

# Gerar chaves
cd ~/sistema-iluminacao-viza/wireguard
sudo ./wireguard_setup.sh

# Iniciar VPN
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

# Verificar status
sudo wg show
```

### Cliente (Celular/Notebook)

```bash
# Gerar configuração para novo cliente
cd ~/sistema-iluminacao-viza/wireguard
sudo ./generate_client.sh "celular-tecnico"

# Arquivo gerado: celular-tecnico.conf
# Copiar e importar no app WireGuard
```

**Apps WireGuard:**
- Android: [Google Play Store](https://play.google.com/store/apps/details?id=com.wireguard.android)
- iOS: [App Store](https://apps.apple.com/app/wireguard/id1441195209)
- Windows: [wireguard.com/install](https://www.wireguard.com/install/)
- Linux: `sudo apt install wireguard`

---

## 📡 API REST Endpoints

### Controle de Iluminação

```bash
# Alterar modo (manual/automático)
POST /api/modo
{
  "modo": "manual"
}

# Ajustar brilho geral
POST /api/brilho
{
  "brilho": 75
}

# Controlar setor específico
POST /api/modo_setor
{
  "Setor": "Estacionamento",
  "modo": "manual"
}

POST /api/brilho_setor
{
  "Setor": "Estacionamento",
  "brilho": 80
}

# Setpoint em lux (modo automático)
POST /api/setpoint_lux_geral
{
  "setpoint_lux": 500.0
}
```

### Dashboard e Monitoramento

```bash
# Dados do dashboard
GET /api/dados_dashboard

# Status do sistema
GET /api/status

# Monitoramento Raspberry PI
GET /api/monitor/system
```

### Agendamentos

```bash
# Criar agendamento
POST /api/agendar_simples
{
  "setor": "1",
  "acao": "ligar",
  "hora": 18,
  "minuto": 0,
  "brilho": 100
}

# Ativar/desativar agendamento
POST /api/toggle_agendamento_simples
{
  "setor": "1",
  "ativo": true
}
```

Documentação completa: [docs/API.md](docs/API.md)

---

## 🔄 Bridge ESP32 Mesh

O Raspberry PI se comunica com os escravos ESP32 através de um **ESP32 Bridge** conectado via USB.

### Como Funciona

1. Raspberry envia comando JSON via Serial (USB)
2. ESP32 Bridge recebe e transmite via Mesh
3. Escravos processam e respondem
4. Bridge encaminha resposta ao Raspberry

### Firmware do Bridge

```cpp
// Firmware específico para ESP32 Bridge
// Localização: firmware_bridge/bridge.ino
// Flash via Arduino IDE antes de conectar
```

### Comandos Suportados

```json
// Formato padrão (compatível com Mestre.ino original)
{
  "tipo": "brilho_Setor",
  "Setor": "Estacionamento",
  "brilho": 75
}
```

---

## 📊 Banco de Dados SQLite

### Estrutura

```sql
-- Configurações
CREATE TABLE config (
    chave TEXT PRIMARY KEY,
    valor TEXT NOT NULL,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Histórico de consumo
CREATE TABLE consumo_historico (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    setor TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    luminarias_ativas INTEGER,
    brilho_medio INTEGER,
    consumo_kwh REAL,
    custo_real REAL
);

-- Agendamentos
CREATE TABLE agendamentos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    setor TEXT NOT NULL,
    hora_ligar INTEGER,
    minuto_ligar INTEGER,
    hora_desligar INTEGER,
    minuto_desligar INTEGER,
    brilho_ligar INTEGER,
    ativo BOOLEAN DEFAULT 1
);

-- Logs do sistema
CREATE TABLE logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    nivel TEXT,
    modulo TEXT,
    mensagem TEXT
);
```

---

## 🔒 Segurança

### Implementado

✅ **WireGuard VPN** - Criptografia ChaCha20  
✅ **Firewall UFW** - Portas específicas  
✅ **Fail2Ban** - Proteção contra brute force  
✅ **HTTPS** (opcional) - Certificado Let's Encrypt  
✅ **Autenticação HTTP** - Basic Auth em endpoints críticos  
✅ **Rate Limiting** - Proteção DDoS  

### Configuração Firewall

```bash
# Permitir apenas portas necessárias
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS (opcional)
sudo ufw allow 51820/udp   # WireGuard
sudo ufw enable
```

---

## 📈 Monitoramento e Logs

### Logs em Tempo Real

```bash
# Aplicação principal
sudo journalctl -u iluminacao-viza -f

# Bridge Mesh
sudo journalctl -u mesh-bridge -f

# WireGuard
sudo journalctl -u wg-quick@wg0 -f

# Todos
sudo journalctl -f
```

### Saúde do Sistema

```bash
# Executar script de monitoramento
./scripts/monitor.sh

# Dashboard web
http://raspberrypi.local/monitor
```

### Backup Automático

```bash
# Configurar backup diário (cron)
sudo crontab -e

# Adicionar linha:
0 2 * * * /home/pi/sistema-iluminacao-viza/scripts/backup.sh
```

---

## 🐛 Solução de Problemas

### ESP32 Bridge não conecta

```bash
# Verificar porta USB
ls -l /dev/ttyUSB*
sudo chmod 666 /dev/ttyUSB0

# Testar comunicação
sudo minicom -D /dev/ttyUSB0 -b 115200
```

### WireGuard não conecta

```bash
# Verificar status
sudo wg show
sudo systemctl status wg-quick@wg0

# Logs
sudo journalctl -u wg-quick@wg0 -n 50

# Reconfigurar
sudo ./wireguard_setup.sh
```

### Serviço não inicia

```bash
# Verificar erros
sudo systemctl status iluminacao-viza
sudo journalctl -u iluminacao-viza -n 50

# Reiniciar
sudo systemctl restart iluminacao-viza
```

Mais soluções: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

## 📱 Acesso Remoto (Guia Rápido)

### 1. Instalar WireGuard no Celular

- Android: Google Play Store
- iOS: App Store

### 2. Importar Configuração

```bash
# No Raspberry, gerar config
cd ~/sistema-iluminacao-viza/wireguard
sudo ./generate_client.sh "meu-celular"

# Copiar conteúdo do arquivo meu-celular.conf
cat meu-celular.conf
```

### 3. Adicionar no App

- Abrir WireGuard
- "+" → "Criar do código QR" ou "Criar do arquivo"
- Colar configuração
- Ativar túnel

### 4. Acessar Dashboard

```
http://10.0.0.1
```

---

## 🔄 Atualização do Sistema

```bash
cd ~/sistema-iluminacao-viza

# Baixar atualizações
git pull

# Executar script de atualização
sudo ./scripts/update.sh

# Reiniciar serviços
sudo systemctl restart iluminacao-viza
```

---

## 👥 Equipe de Desenvolvimento

**Desenvolvido por:**
- Pablo Gonçalves Ribas
- Eduardo Matheus Santos

**Empresa:**  
Engemase Engenharia

**Cliente:**  
Viza Atacadista - Caçador/SC

---

## 📄 Licença

Projeto proprietário © 2025 Engemase Engenharia  
Todos os direitos reservados.

---

## 📞 Suporte

**Email**: suporte@engemase.com.br  
**Telefone**: (XX) XXXX-XXXX  
**Documentação**: [docs/](docs/)

---

## 📱 PWA + HTTPS

### Progressive Web App

O sistema é um **PWA completo** instalável em qualquer dispositivo!

**Recursos**:
- ✅ **HTTPS** configurável (auto-assinado ou Let's Encrypt)
- ✅ **Service Worker** com cache inteligente
- ✅ **Instalável** em Android, iOS e Desktop
- ✅ **Offline First** - interface funcional sem internet
- ✅ **Manifest.json** completo
- ✅ **Ícones** adaptivos em múltiplos tamanhos
- ✅ **Push Notifications** preparado (futuro)

**Configurar HTTPS**:
```bash
cd ~/sistema-iluminacao-viza
sudo ./scripts/setup_https.sh
```

**Instalar como App**:
- **Android**: Menu → "Adicionar à tela inicial"
- **iOS**: Compartilhar → "Adicionar à Tela de Início"
- **Desktop**: Ícone na barra de endereço → "Instalar"

📚 **Documentação completa**: [PWA_HTTPS.md](PWA_HTTPS.md)

---

## 🎯 Roadmap

### ✅ Versão 1.0 (Atual)
- [x] Migração completa para Raspberry PI
- [x] WireGuard VPN funcional
- [x] Dashboard responsivo
- [x] API REST completa
- [x] Banco de dados SQLite
- [x] PWA com HTTPS
- [x] Service Worker offline
- [x] Instalável como app

### 🚧 Versão 1.1 (Em Desenvolvimento)
- [ ] Gráficos interativos avançados
- [ ] App móvel nativo (Flutter)
- [ ] Integração com Alexa/Google Home
- [ ] Machine Learning para otimização

### 🔮 Versão 2.0 (Planejado)
- [ ] Multi-instalação (várias lojas)
- [ ] Dashboard corporativo central
- [ ] Relatórios gerenciais PDF
- [ ] Integração ERP

---

**Última atualização**: 30/10/2025  
**Versão**: 1.0.0
