# 🚀 Guia Rápido - ESP32 Bridge (5 Minutos)

## 📋 O que você precisa

- ✅ 1x ESP32 DevKit
- ✅ 1x Cabo USB
- ✅ Arduino IDE ou PlatformIO
- ✅ 5 minutos

---

## ⚡ Passo a Passo

### 1️⃣ Instalar Arduino IDE (2 min)

```
1. Download: https://www.arduino.cc/en/software
2. Instalar
3. Abrir Arduino IDE
```

---

### 2️⃣ Adicionar Suporte ESP32 (1 min)

```
1. File → Preferences
2. Additional Boards Manager URLs:
   https://dl.espressif.com/dl/package_esp32_index.json
3. OK
4. Tools → Board → Boards Manager
5. Buscar: "ESP32"
6. Instalar: "esp32 by Espressif Systems"
```

---

### 3️⃣ Instalar Bibliotecas (1 min)

```
1. Sketch → Include Library → Manage Libraries
2. Buscar e instalar:
   - PainlessMesh (by Coopdis)
   - ArduinoJson (by Benoit Blanchon)
```

---

### 4️⃣ Configurar Placa (30 seg)

```
1. Tools → Board → ESP32 Arduino → ESP32 Dev Module
2. Tools → Upload Speed → 115200
3. Tools → Port → (selecionar porta COM do ESP32)
```

---

### 5️⃣ Gravar Firmware (1 min)

```
1. File → Open → ESP32_Mesh_Bridge.ino
2. Sketch → Upload
3. Aguardar "Done uploading"
4. Tools → Serial Monitor
5. Verificar logs do bridge
```

---

## ✅ Pronto!

Deve aparecer:

```
╔════════════════════════════════════════════════╗
║   ESP32 MESH BRIDGE - Sistema Viza            ║
║   Versão 1.0.0                                 ║
╚════════════════════════════════════════════════╝

[BRIDGE] Iniciando...
[BRIDGE] Mesh inicializada
[BRIDGE] Node ID: 3456789012
[BRIDGE] Aguardando comandos via Serial...
```

---

## 🔌 Conectar ao Raspberry

```bash
1. Desconectar ESP32 do PC
2. Conectar ESP32 via USB ao Raspberry
3. No Raspberry:
   ls /dev/ttyUSB*
   # Deve mostrar: /dev/ttyUSB0

4. Reiniciar serviço:
   sudo systemctl restart iluminacao-viza

5. Verificar logs:
   sudo journalctl -u iluminacao-viza -f
   # Deve mostrar comunicação com ESP32
```

---

## 🧪 Testar

### No Raspberry PI:

```bash
# Abrir Python
python3

# Testar comunicação
import serial
ser = serial.Serial('/dev/ttyUSB0', 115200)
ser.write(b'{"tipo":"global","brilho":50}\n')
response = ser.readline()
print(response)
```

Deve retornar: `{"status":"ok","acao":"enviado"}`

---

## 🎯 Configurações (Se Necessário)

**Se suas configurações Mesh forem diferentes**, editar no `ESP32_Mesh_Bridge.ino`:

```cpp
#define MESH_PREFIX     "Iluminação_Viza_Mesh"  // ← Seu SSID Mesh
#define MESH_PASSWORD   "1F#hVL1lM#"            // ← Sua senha Mesh
#define MESH_PORT       5555                     // ← Sua porta Mesh
```

---

## 🐛 Problemas?

### ESP32 não aparece na porta COM

**Windows**:
- Instalar driver CP210x: https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers

**Linux**:
```bash
sudo usermod -a -G dialout $USER
# Logout e login novamente
```

---

### Erro ao compilar

**Verificar**:
1. Bibliotecas instaladas? (PainlessMesh + ArduinoJson)
2. Placa selecionada? (ESP32 Dev Module)
3. Porta correta?

---

### Bridge não conecta na rede Mesh

**Verificar**:
1. Configurações Mesh corretas? (MESH_PREFIX, MESH_PASSWORD, MESH_PORT)
2. Escravos ligados?
3. Distância WiFi OK?

---

## 📚 Documentação Completa

- **README.md** - Documentação detalhada
- **../INSTALL.md** - Instalação do sistema completo
- **platformio.ini** - Configuração PlatformIO (alternativa ao Arduino IDE)

---

## 🎉 Sucesso!

Agora você tem:
- ✅ ESP32 Bridge programado
- ✅ Comunicação Serial funcionando
- ✅ Conectado na rede Mesh
- ✅ Pronto para conectar ao Raspberry!

**Próximo passo**: Conectar ao Raspberry PI e testar o sistema completo!
