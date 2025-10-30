# 📡 Como Acessar o Sistema - Guia Completo

## ⚠️ MUDANÇA IMPORTANTE!

### Sistema Antigo (ESP32):
```
┌─────────────────┐
│   ESP32 Mestre  │
│   Cria WiFi:    │
│   "Iluminação   │
│   _Viza"        │
└────────┬────────┘
         │ WiFi próprio
    ┌────┴────┐
    ▼         ▼
 Celular   Notebook
```
- ESP32 criava WiFi próprio
- Você conectava diretamente
- Acesso: `http://192.168.4.1`

---

### Sistema Novo (Raspberry PI):
```
┌─────────────────┐
│  Raspberry PI   │
│  NÃO cria WiFi  │
│  Conecta na sua │
│  rede existente │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
 Roteador   Internet
```
- Raspberry **conecta** na sua WiFi
- Acesso pela mesma rede
- OU via VPN de qualquer lugar

---

## 🌐 OPÇÃO 1: Rede Local (Recomendado)

### Como Funciona:
1. Raspberry conecta na **sua WiFi** (da empresa/casa)
2. Você conecta na **mesma WiFi**
3. Acessa via navegador

### Configurar WiFi do Raspberry:

**Método A - Durante Instalação do SD**:
```
Raspberry Pi Imager:
1. Configurações (⚙️)
2. ✅ Ativar WiFi
3. SSID: SUA_REDE_WIFI
4. Senha: SUA_SENHA
5. País: BR
```

**Método B - Arquivo wpa_supplicant.conf**:
```bash
# Criar na partição boot do SD card

country=BR
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="NOME_DA_SUA_WIFI"
    psk="SENHA_DA_SUA_WIFI"
    key_mgmt=WPA-PSK
}
```

### Como Acessar:

**1. Via Hostname** (mais fácil):
```
http://raspberrypi.local
```

**2. Via IP**:
```
http://192.168.1.XXX
```

**Descobrir o IP**:

```bash
# No próprio Raspberry (SSH):
hostname -I

# Resultado: 192.168.1.150 (exemplo)
# Acesse: http://192.168.1.150
```

**Ou pelo roteador**:
- Acessar painel do roteador
- Ver dispositivos conectados
- Procurar "raspberrypi"

**Ou escanear a rede**:

Windows:
```
Advanced IP Scanner
https://www.advanced-ip-scanner.com/
```

Linux/Mac:
```bash
sudo nmap -sn 192.168.1.0/24
# ou
arp -a | grep raspberry
```

---

## 🔐 OPÇÃO 2: VPN WireGuard (Acesso Remoto)

### Para acessar de **qualquer lugar** (internet, 4G, outra WiFi)

```
┌──────────────┐
│  Você        │  ← Qualquer lugar do mundo
│  (4G/WiFi)   │
└──────┬───────┘
       │ Internet
       │ VPN Criptografada
┌──────▼───────┐
│ Raspberry PI │  ← Na sua rede local
└──────────────┘
```

### Configurar VPN:

**No Raspberry**:
```bash
cd ~/sistema-iluminacao-viza
sudo ./wireguard_setup.sh

# Informar:
# - IP público: seu-ip-ou-dominio.ddns.net
# - Porta: 51820 (padrão)
# - Clientes: 2 (ou mais)
# - Nome cliente 1: celular-fulano
# - Nome cliente 2: notebook-ciclano
```

**Arquivos gerados** em: `~/wireguard-clients/`
- `celular-fulano.conf`
- `celular-fulano.png` (QR code)
- `notebook-ciclano.conf`
- etc.

### Instalar no Celular/Notebook:

**Android**:
```
1. Play Store → WireGuard
2. Instalar
3. + (adicionar túnel)
4. Escanear QR code
5. Ativar túnel
6. Acessar: http://10.0.0.1
```

**iOS**:
```
1. App Store → WireGuard
2. Instalar
3. + (adicionar túnel)
4. Escanear QR code
5. Ativar túnel
6. Acessar: http://10.0.0.1
```

**Windows/Mac/Linux**:
```
1. https://www.wireguard.com/install/
2. Instalar WireGuard
3. Importar arquivo .conf
4. Ativar túnel
5. Acessar: http://10.0.0.1
```

### IP na VPN:
```
Raspberry: 10.0.0.1 (fixo)
Clientes: 10.0.0.2, 10.0.0.3, etc.
```

---

## 📡 OPÇÃO 3: Access Point (WiFi Próprio)

### Para criar WiFi igual ao ESP32 (opcional)

**⚠️ ATENÇÃO**: 
- Raspberry precisa estar conectado via **Ethernet** (cabo)
- WiFi será usado para criar o Access Point

### Configurar:

```bash
cd ~/sistema-iluminacao-viza/scripts
chmod +x setup_ap.sh
sudo ./setup_ap.sh

# Informar:
# - SSID: Iluminacao_Viza
# - Senha: 1F#hVL1lM#
# - Canal: 6
```

### Como Funciona:

```
         Internet
            │
            │ Cabo Ethernet
┌───────────▼──────────┐
│   Raspberry PI       │
│   Cria WiFi:         │
│   "Iluminacao_Viza"  │
└───────────┬──────────┘
            │ WiFi
       ┌────┴────┐
       ▼         ▼
   Celular   Notebook
```

### Acessar:
```
1. Conectar no WiFi: Iluminacao_Viza
2. Senha: 1F#hVL1lM#
3. Acessar: http://192.168.4.1
```

**Requisitos**:
- ✅ Raspberry com WiFi
- ✅ Cabo Ethernet conectado (para internet)
- ✅ Script `setup_ap.sh` executado

---

## 📊 Comparação dos Métodos

| Método | Vantagens | Desvantagens | Quando Usar |
|--------|-----------|--------------|-------------|
| **Rede Local** | ✅ Simples<br>✅ Rápido<br>✅ Sem configuração extra | ❌ Só mesma rede | Escritório/casa |
| **VPN WireGuard** | ✅ Acesso remoto<br>✅ Seguro<br>✅ De qualquer lugar | ❌ Requer config inicial<br>❌ Precisa internet | Acesso externo |
| **Access Point** | ✅ WiFi próprio<br>✅ Como ESP32 | ❌ Precisa Ethernet<br>❌ Config complexa | Isolado, sem WiFi |

---

## 🎯 Recomendação por Cenário

### **Cenário 1: Escritório/Loja com WiFi**
```
✅ USAR: Rede Local + VPN

Configuração:
1. Raspberry na WiFi da empresa
2. VPN para acesso remoto (técnicos)

Acesso:
- Local: http://raspberrypi.local
- Remoto: http://10.0.0.1 (VPN)
```

### **Cenário 2: Sem WiFi (só Ethernet)**
```
✅ USAR: Access Point

Configuração:
1. Raspberry com cabo Ethernet
2. Criar WiFi próprio (setup_ap.sh)

Acesso:
- WiFi: Iluminacao_Viza
- IP: http://192.168.4.1
```

### **Cenário 3: Casa/Teste**
```
✅ USAR: Rede Local

Configuração:
1. Raspberry na WiFi de casa
2. Acesso pelo celular na mesma WiFi

Acesso:
- http://raspberrypi.local
```

---

## 🔧 Passo a Passo - Primeiro Acesso

### 1️⃣ Preparar SD Card
```
Raspberry Pi Imager
→ Configurações
→ ✅ SSH habilitado
→ ✅ WiFi configurado (sua rede)
→ Usuário: pi
→ Senha: (sua senha)
```

### 2️⃣ Ligar Raspberry
```
Inserir SD
Conectar energia
Aguardar 2 minutos (boot)
```

### 3️⃣ Descobrir IP
```
Método A: http://raspberrypi.local
Método B: Verificar no roteador
Método C: Scanner de rede
```

### 4️⃣ Acessar via SSH
```bash
ssh pi@raspberrypi.local
# ou
ssh pi@192.168.1.XXX

Senha: (sua senha)
```

### 5️⃣ Instalar Sistema
```bash
# Já no Raspberry via SSH
cd ~
# Copiar projeto (via scp do PC)
# Ou clonar do git

cd sistema-iluminacao-viza
sudo ./setup.sh
```

### 6️⃣ Acessar Dashboard
```
Navegador: http://raspberrypi.local
ou: http://IP_DO_RASPBERRY
```

---

## 🌐 URLs de Acesso (Resumo)

### Rede Local:
```
http://raspberrypi.local
http://192.168.1.XXX (seu IP)

Com HTTPS:
https://raspberrypi.local
https://192.168.1.XXX
```

### VPN WireGuard:
```
http://10.0.0.1
https://10.0.0.1 (com HTTPS)
```

### Access Point:
```
WiFi: Iluminacao_Viza
Senha: 1F#hVL1lM#
URL: http://192.168.4.1
```

---

## 🐛 Troubleshooting

### Raspberry não aparece na rede

**Verificar**:
1. WiFi configurado corretamente?
2. Raspberry ligado? (LED verde piscando)
3. Aguardou 2-3 minutos?
4. Roteador permite novos dispositivos?

**Solução**:
```bash
# Conectar via Ethernet (cabo)
# SSH via IP do cabo
# Reconfigurar WiFi:
sudo raspi-config
→ System Options
→ Wireless LAN
```

---

### `raspberrypi.local` não funciona

**Causa**: mDNS não suportado (Windows antigo, alguns roteadores)

**Solução**: Usar IP direto
```bash
# Descobrir IP via roteador
# ou conectar monitor HDMI no Raspberry
# ou usar scanner de rede
```

---

### VPN não conecta

**Verificar**:
1. Port forwarding configurado? (porta 51820)
2. IP público correto?
3. Firewall liberado?
4. WireGuard rodando? `sudo wg show`

**Solução**:
```bash
# Verificar serviço
sudo systemctl status wg-quick@wg0

# Ver logs
sudo journalctl -u wg-quick@wg0 -f

# Reconfigurar
cd ~/sistema-iluminacao-viza
sudo ./wireguard_setup.sh
```

---

## ✅ Checklist de Acesso

### Primeira Vez:
- [ ] SD card gravado com WiFi configurado
- [ ] Raspberry ligado e na rede
- [ ] IP descoberto (hostname ou scanner)
- [ ] SSH funcionando
- [ ] Sistema instalado (`setup.sh`)
- [ ] Dashboard acessível

### Acesso Remoto:
- [ ] WireGuard configurado no Raspberry
- [ ] Port forwarding no roteador
- [ ] Cliente VPN instalado no dispositivo
- [ ] Túnel VPN ativado
- [ ] Dashboard acessível via `10.0.0.1`

---

## 📱 Instalar PWA (Após Acesso)

### Android/iOS:
```
1. Acessar: http://raspberrypi.local
2. Menu → "Adicionar à tela inicial"
3. App instalado!
4. Abrir pelo ícone
```

### Desktop:
```
1. Acessar pelo navegador
2. Ícone de instalação na barra
3. "Instalar"
4. App desktop criado
```

---

## 🎉 Resumo Final

### Acesso Mais Simples:
```
1. Raspberry na sua WiFi
2. Você na mesma WiFi
3. http://raspberrypi.local
4. Pronto! ✅
```

### Acesso Mais Completo:
```
1. Raspberry na sua WiFi
2. VPN configurada
3. Acesso local: http://raspberrypi.local
4. Acesso remoto: http://10.0.0.1 (VPN)
5. PWA instalado no celular
6. Perfeito! 🎉
```

---

**Desenvolvido por: Engemase Engenharia**  
**Cliente: Viza Atacadista - Caçador/SC**
