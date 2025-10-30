# Guia de Instalação Completo - Sistema de Iluminação Viza

## 📋 Pré-requisitos

### Hardware Necessário
- ✅ Raspberry PI 4 Model B (4GB RAM)
- ✅ Cartão microSD 32GB+ (Classe 10)
- ✅ Fonte 5V 3A oficial
- ✅ ESP32 DevKit (para bridge Mesh)
- ✅ RTC DS3231 (módulo I2C)
- ✅ Cabos: USB-A para Micro-USB, jumpers fêmea-fêmea

### Conhecimentos Básicos
- Comandos básicos Linux
- Acesso SSH
- Edição de arquivos de texto

---

## 🚀 PARTE 1: Preparar Raspberry PI OS

### Passo 1.1: Baixar Raspberry Pi OS

1. Acesse: https://www.raspberrypi.com/software/
2. Baixe **Raspberry Pi Imager**
3. Instale no seu computador (Windows/Mac/Linux)

### Passo 1.2: Gravar Imagem no MicroSD

```bash
1. Abra Raspberry Pi Imager
2. Escolher SO → Raspberry Pi OS (64-bit) LITE
3. Escolher Armazenamento → Seu cartão microSD
4. Clique no ícone de engrenagem (configurações avançadas)
```

**Configurações Avançadas:**
```
✅ Ativar SSH
   ○ Usar autenticação por senha
   
✅ Definir nome de usuário e senha
   Usuário: pi
   Senha: viza2025

✅ Configurar WiFi (opcional)
   SSID: Sua_Rede_WiFi
   Senha: sua_senha
   País: BR

✅ Definir localização
   Fuso horário: America/Sao_Paulo
   Layout do teclado: br
```

5. Clique em **GRAVAR**
6. Aguarde conclusão (5-10 minutos)
7. Remova o cartão com segurança

### Passo 1.3: Primeiro Boot

```bash
1. Insira o microSD no Raspberry PI
2. Conecte cabo de rede Ethernet (recomendado)
3. Conecte a fonte de alimentação
4. Aguarde 1-2 minutos para boot inicial
```

### Passo 1.4: Encontrar IP do Raspberry

**Método 1: Acesso via hostname**
```bash
ping raspberrypi.local
```

**Método 2: Varredura de rede**
```bash
# Windows (PowerShell)
arp -a | findstr b8-27-eb

# Linux/Mac
nmap -sn 192.168.1.0/24 | grep -B 2 "Raspberry"

# Ou acesse roteador e veja dispositivos conectados
```

### Passo 1.5: Conectar via SSH

```bash
# Substituir pelo IP encontrado
ssh pi@raspberrypi.local
# ou
ssh pi@192.168.1.150

# Senha: viza2025

# Primeira conexão: aceitar fingerprint (yes)
```

---

## 🔧 PARTE 2: Configuração Inicial do Sistema

### Passo 2.1: Atualizar Sistema

```bash
# Atualizar lista de pacotes
sudo apt update

# Atualizar pacotes instalados (pode demorar)
sudo apt upgrade -y

# Reiniciar se houver atualização de kernel
sudo reboot

# Reconectar após 1 minuto
ssh pi@raspberrypi.local
```

### Passo 2.2: Configurar Localização e Timezone

```bash
# Configurar timezone
sudo timedatectl set-timezone America/Sao_Paulo

# Verificar
timedatectl

# Configurar locale
sudo raspi-config
# 5 Localisation Options → L1 Locale
# Marcar: pt_BR.UTF-8 UTF-8
# Default: pt_BR.UTF-8
```

### Passo 2.3: Expandir Sistema de Arquivos

```bash
# Expandir para usar todo o cartão SD
sudo raspi-config
# 6 Advanced Options → A1 Expand Filesystem
# Finish → Reboot: Yes

# Reconectar
ssh pi@raspberrypi.local
```

### Passo 2.4: Instalar Pacotes Essenciais

```bash
# Git
sudo apt install -y git

# Python 3.10+ (já vem no OS)
python3 --version

# pip (gerenciador de pacotes Python)
sudo apt install -y python3-pip python3-venv

# Ferramentas de desenvolvimento
sudo apt install -y build-essential python3-dev

# I2C para RTC DS3231
sudo apt install -y i2c-tools python3-smbus

# Serial para ESP32
sudo apt install -y minicom

# Editor de texto
sudo apt install -y nano vim
```

---

## 📦 PARTE 3: Instalar Projeto

### Passo 3.1: Baixar Código-Fonte

**Opção A: Via Git (se tiver repositório)**
```bash
cd ~
git clone https://github.com/engemase/sistema-iluminacao-viza.git
cd sistema-iluminacao-viza
```

**Opção B: Copiar Arquivos Manualmente (WinSCP/SCP)**
```bash
# No Windows, usar WinSCP:
# Host: raspberrypi.local
# Port: 22
# Username: pi
# Password: viza2025

# Copiar toda a pasta Sistema_Iluminacao_Raspberry para:
# /home/pi/sistema-iluminacao-viza

# Ou via SCP:
scp -r "C:\Users\Engemase\OneDrive_Old\Área de Trabalho\Sistema_Iluminacao_Raspberry" pi@raspberrypi.local:~/sistema-iluminacao-viza
```

### Passo 3.2: Criar Ambiente Virtual Python

```bash
cd ~/sistema-iluminacao-viza

# Criar virtualenv
python3 -m venv venv

# Ativar
source venv/bin/activate

# Verificar
which python
# Deve mostrar: /home/pi/sistema-iluminacao-viza/venv/bin/python
```

### Passo 3.3: Instalar Dependências Python

```bash
# Com venv ativado
pip install --upgrade pip

# Instalar todas as dependências
pip install -r requirements.txt

# Verificar instalação
pip list
```

---

## 🔌 PARTE 4: Configurar Hardware

### Passo 4.1: Conectar RTC DS3231 (I2C)

**Conexões físicas:**
```
RTC DS3231 → Raspberry PI
VCC        → Pin 1 (3.3V)
GND        → Pin 6 (GND)
SDA        → Pin 3 (GPIO 2 - SDA)
SCL        → Pin 5 (GPIO 3 - SCL)
```

**Habilitar I2C:**
```bash
# Via raspi-config
sudo raspi-config
# 3 Interface Options → I5 I2C → Yes

# Ou editar manualmente
sudo nano /boot/config.txt
# Adicionar ou descomentar:
dtparam=i2c_arm=on

# Reiniciar
sudo reboot

# Reconectar e verificar
ssh pi@raspberrypi.local
sudo i2cdetect -y 1

# Deve mostrar endereço 0x68:
#      0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
# 00:          -- -- -- -- -- -- -- -- -- -- -- -- -- 
# ...
# 60: -- -- -- -- -- -- -- -- 68 -- -- -- -- -- -- --
```

### Passo 4.2: Conectar ESP32 Bridge (USB)

**Conexões físicas:**
```
1. Conectar ESP32 na porta USB do Raspberry
2. Cabo: USB-A (Raspberry) ↔ Micro-USB (ESP32)
```

**Verificar detecção:**
```bash
# Listar dispositivos USB
lsusb

# Deve mostrar algo como:
# Bus 001 Device 004: ID 10c4:ea60 Silicon Labs CP210x UART Bridge

# Verificar porta serial
ls -l /dev/ttyUSB*
# Deve mostrar: /dev/ttyUSB0

# Se não aparecer, instalar driver
sudo apt install -y brltty
sudo systemctl stop brltty
sudo systemctl disable brltty
```

**Dar permissão ao usuário:**
```bash
# Adicionar usuário ao grupo dialout
sudo usermod -a -G dialout pi

# Logout e login novamente
exit
ssh pi@raspberrypi.local

# Verificar
groups
# Deve mostrar: pi adm dialout ...
```

**Testar comunicação serial:**
```bash
# Instalar minicom
sudo apt install -y minicom

# Conectar (Ctrl+A, depois X para sair)
sudo minicom -D /dev/ttyUSB0 -b 115200

# Se ver logs do ESP32, está funcionando!
```

---

## 🗄️ PARTE 5: Configurar Banco de Dados

### Passo 5.1: Criar Banco SQLite

```bash
cd ~/sistema-iluminacao-viza

# Ativar venv
source venv/bin/activate

# Criar banco e tabelas
python3 -c "from app.database import init_db; init_db()"

# Verificar criação
ls -lh data/
# Deve mostrar: iluminacao_viza.db

# Testar banco
sqlite3 data/iluminacao_viza.db
# No prompt sqlite:
.tables
# Deve listar: config, consumo_historico, agendamentos, logs
.quit
```

---

## 🔐 PARTE 6: Configurar WireGuard VPN

### Passo 6.1: Instalar WireGuard

```bash
# Atualizar lista de pacotes
sudo apt update

# Instalar WireGuard
sudo apt install -y wireguard wireguard-tools

# Verificar instalação
wg version
```

### Passo 6.2: Executar Script de Configuração

```bash
cd ~/sistema-iluminacao-viza

# Dar permissão de execução
chmod +x wireguard_setup.sh

# Executar
sudo ./wireguard_setup.sh

# Responder perguntas:
# IP público ou DDNS [ex: seu-dominio.ddns.net]: <SEU_IP_OU_DOMINIO>
# Porta WireGuard [51820]: <ENTER>
# Quantos clientes gerar? [1]: 2
# Nome do cliente 1: celular-tecnico
# Nome do cliente 2: notebook-manutencao
```

### Passo 6.3: Configurar Firewall

```bash
# Instalar UFW
sudo apt install -y ufw

# Regras básicas
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Permitir SSH (IMPORTANTE!)
sudo ufw allow 22/tcp

# Permitir HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Permitir WireGuard
sudo ufw allow 51820/udp

# Ativar firewall
sudo ufw enable

# Verificar status
sudo ufw status verbose
```

### Passo 6.4: Iniciar WireGuard

```bash
# Iniciar interface VPN
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

# Verificar status
sudo systemctl status wg-quick@wg0

# Ver peers conectados
sudo wg show
```

### Passo 6.5: Configurar Port Forwarding no Roteador

**Se Raspberry estiver atrás de roteador (NAT):**

```
1. Acessar interface do roteador (ex: 192.168.1.1)
2. Buscar: Port Forwarding / Redirecionamento de Portas
3. Adicionar regra:
   - Nome: WireGuard
   - Protocolo: UDP
   - Porta Externa: 51820
   - IP Interno: <IP_DO_RASPBERRY>
   - Porta Interna: 51820
4. Salvar e aplicar
```

---

## 🚀 PARTE 7: Configurar Serviços Systemd

### Passo 7.1: Criar Serviço Principal

```bash
# Copiar arquivo de serviço
sudo cp ~/sistema-iluminacao-viza/systemd/iluminacao-viza.service /etc/systemd/system/

# Recarregar daemon
sudo systemctl daemon-reload

# Habilitar inicialização automática
sudo systemctl enable iluminacao-viza

# Iniciar serviço
sudo systemctl start iluminacao-viza

# Verificar status
sudo systemctl status iluminacao-viza

# Ver logs em tempo real
sudo journalctl -u iluminacao-viza -f
```

### Passo 7.2: Criar Serviço Bridge ESP32

```bash
# Copiar arquivo de serviço
sudo cp ~/sistema-iluminacao-viza/systemd/mesh-bridge.service /etc/systemd/system/

# Recarregar, habilitar e iniciar
sudo systemctl daemon-reload
sudo systemctl enable mesh-bridge
sudo systemctl start mesh-bridge

# Verificar
sudo systemctl status mesh-bridge
```

---

## 🌐 PARTE 8: Testar Sistema

### Passo 8.1: Verificar Serviços

```bash
# Status de todos os serviços
sudo systemctl status iluminacao-viza
sudo systemctl status mesh-bridge
sudo systemctl status wg-quick@wg0

# Todos devem estar: active (running)
```

### Passo 8.2: Testar Acesso Local

```bash
# No Raspberry, testar API
curl http://localhost/api/status

# Deve retornar JSON com status do sistema

# Do seu computador (mesma rede)
# Abrir navegador:
http://raspberrypi.local
# ou
http://192.168.1.X
```

### Passo 8.3: Testar Comunicação Mesh

```bash
# Ver logs do bridge
sudo journalctl -u mesh-bridge -f

# Deve mostrar:
# - Conexão com escravos
# - Mensagens recebidas
# - Comandos enviados
```

### Passo 8.4: Configurar Cliente WireGuard

**No celular Android/iOS:**
```
1. Instalar app WireGuard
2. Abrir arquivo de configuração gerado:
   ~/sistema-iluminacao-viza/wireguard/celular-tecnico.conf
3. Copiar conteúdo ou gerar QR code:
   
   # Gerar QR code
   sudo apt install qrencode
   qrencode -t ansiutf8 < wireguard/celular-tecnico.conf
   
4. Escanear QR code no app
5. Ativar túnel VPN
6. Abrir navegador: http://10.0.0.1
```

**No notebook Windows/Linux:**
```bash
# Copiar arquivo .conf para o computador
scp pi@raspberrypi.local:~/sistema-iluminacao-viza/wireguard/notebook-manutencao.conf .

# Importar no WireGuard
# Windows: WireGuard GUI → Importar túnel do arquivo
# Linux: sudo cp notebook-manutencao.conf /etc/wireguard/wg0.conf
#        sudo systemctl start wg-quick@wg0
```

---

## ✅ PARTE 9: Verificação Final

### Checklist Completo

```bash
✅ Raspberry PI iniciando corretamente
✅ SSH funcionando
✅ Sistema atualizado
✅ Python 3.10+ instalado
✅ Dependências instaladas
✅ RTC DS3231 detectado (i2cdetect)
✅ ESP32 detectado (/dev/ttyUSB0)
✅ Banco SQLite criado
✅ WireGuard instalado e configurado
✅ Firewall UFW ativo
✅ Serviço iluminacao-viza rodando
✅ Serviço mesh-bridge rodando
✅ Acesso local funcionando (http://raspberrypi.local)
✅ Acesso remoto VPN funcionando (http://10.0.0.1)
✅ Comunicação com escravos ESP32 OK
✅ Dashboard carregando dados
```

### Comandos de Verificação Rápida

```bash
# Status geral
sudo systemctl status iluminacao-viza mesh-bridge wg-quick@wg0

# Logs em tempo real
sudo journalctl -f

# Testar API
curl http://localhost/api/status | python3 -m json.tool

# Verificar VPN
sudo wg show

# Ver processos
ps aux | grep python

# Uso de recursos
htop
```

---

## 🔄 PARTE 10: Backup e Manutenção

### Configurar Backup Automático

```bash
# Tornar script executável
chmod +x ~/sistema-iluminacao-viza/scripts/backup.sh

# Testar backup manual
~/sistema-iluminacao-viza/scripts/backup.sh

# Agendar backup diário (2:00 AM)
sudo crontab -e
# Adicionar linha:
0 2 * * * /home/pi/sistema-iluminacao-viza/scripts/backup.sh

# Verificar cron
sudo crontab -l
```

### Monitoramento de Saúde

```bash
# Executar script de monitoramento
~/sistema-iluminacao-viza/scripts/monitor.sh

# Agendar verificação a cada hora
crontab -e
# Adicionar:
0 * * * * /home/pi/sistema-iluminacao-viza/scripts/monitor.sh
```

---

## 📞 Suporte

**Problemas na instalação?**

1. Consulte [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Verifique logs: `sudo journalctl -u iluminacao-viza -n 100`
3. Entre em contato: suporte@engemase.com.br

---

## 🎉 Instalação Completa!

O sistema está agora totalmente funcional:

- ✅ **Local**: http://raspberrypi.local
- ✅ **Remoto**: http://10.0.0.1 (via WireGuard)
- ✅ **API**: http://raspberrypi.local/api/status
- ✅ **Documentação**: http://raspberrypi.local/docs

**Próximos passos:**
1. Personalizar configurações em `app/config.py`
2. Criar novos clientes VPN com `wireguard/generate_client.sh`
3. Acessar dashboard e testar controle de luminárias
4. Configurar agendamentos

**Desenvolvido por Engemase Engenharia**
