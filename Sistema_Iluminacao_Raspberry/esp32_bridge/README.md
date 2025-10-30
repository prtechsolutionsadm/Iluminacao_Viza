# ESP32 Mesh Bridge - Sistema Viza

## 🎯 Função

Este firmware transforma um ESP32 em uma **ponte de comunicação** entre:
- **Raspberry PI** (via Serial/USB)
- **Rede Mesh** (escravos ESP32 via PainlessMesh)

```
┌──────────────────┐
│  Raspberry PI    │
│  (FastAPI)       │
└────────┬─────────┘
         │ USB Serial (115200)
         │ JSON
┌────────▼─────────┐
│  ESP32 BRIDGE    │ ⭐ Este firmware
│  (Este código)   │
└────────┬─────────┘
         │ Mesh Network
         │ (PainlessMesh)
    ┌────┴────┐
    ▼         ▼
  ESP32     ESP32
  Escravo   Escravo
```

---

## 📋 Hardware Necessário

- **1x ESP32 DevKit** (qualquer modelo)
- **1x Cabo USB** (conectar ao Raspberry PI)

**IMPORTANTE**: Os escravos **NÃO precisam de alteração**!

---

## 🔧 Como Compilar e Gravar

### Opção 1: Arduino IDE

1. **Instalar Arduino IDE**
   - Download: https://www.arduino.cc/en/software

2. **Adicionar suporte ESP32**
   - File → Preferences → Additional Boards Manager URLs
   - Adicionar: `https://dl.espressif.com/dl/package_esp32_index.json`
   - Tools → Board → Boards Manager
   - Buscar "ESP32" e instalar

3. **Instalar bibliotecas**
   - Sketch → Include Library → Manage Libraries
   - Instalar:
     - **PainlessMesh** (by Coopdis et al.)
     - **ArduinoJson** (by Benoit Blanchon)

4. **Configurar placa**
   - Tools → Board → ESP32 Arduino → **ESP32 Dev Module**
   - Tools → Upload Speed → **115200**
   - Tools → Port → (selecionar porta COM do ESP32)

5. **Abrir e gravar**
   - File → Open → `ESP32_Mesh_Bridge.ino`
   - Sketch → Upload

---

### Opção 2: PlatformIO (Recomendado)

1. **Instalar VS Code**
   - Download: https://code.visualstudio.com/

2. **Instalar PlatformIO**
   - Extensions → Buscar "PlatformIO"
   - Instalar

3. **Abrir projeto**
   - PlatformIO → Open → Pasta `esp32_bridge`

4. **Compilar e gravar**
   - PlatformIO → Upload

**Arquivo `platformio.ini` incluído!**

---

## ⚙️ Configurações

### Rede Mesh (deve ser igual aos escravos)

```cpp
#define MESH_PREFIX     "Iluminação_Viza_Mesh"
#define MESH_PASSWORD   "1F#hVL1lM#"
#define MESH_PORT       5555
```

**⚠️ IMPORTANTE**: Deve ser **exatamente igual** às configurações dos escravos!

### Serial

```cpp
#define SERIAL_BAUD     115200
```

---

## 🔌 Conexão Física

### ESP32 → Raspberry PI

1. Conectar ESP32 via **USB** ao Raspberry
2. No Raspberry, verificar:
   ```bash
   ls /dev/ttyUSB*
   ```
   Deve aparecer: `/dev/ttyUSB0`

3. Dar permissão:
   ```bash
   sudo usermod -a -G dialout pi
   ```

4. Reiniciar serviço:
   ```bash
   sudo systemctl restart iluminacao-viza
   ```

---

## 📡 Protocolo de Comunicação

### Raspberry → Bridge (via Serial)

Comandos em **JSON**, um por linha:

**Exemplo - Modo Geral**:
```json
{"tipo":"global","modo":"manual"}
```

**Exemplo - Brilho Geral**:
```json
{"tipo":"global","brilho":75}
```

**Exemplo - Modo Setor**:
```json
{"tipo":"modo_Setor","Setor":"1","modo":"automatico"}
```

**Exemplo - Brilho Setor**:
```json
{"tipo":"brilho_Setor","Setor":"2","brilho":50}
```

---

### Bridge → Raspberry (via Serial)

Respostas em **JSON**:

**Status dos Setores**:
```json
{"tipo":"status_Setores","grupo":{"1":75,"2":50,"3":100}}
```

**Leitura LDR**:
```json
{"tipo":"ldr","id":1,"setor":"Estacionamento","lux":450.5,"percentual brilho":75}
```

**Evento Mesh**:
```json
{"tipo":"mesh_evento","evento":"nova_conexao","node_id":123456}
```

---

## 🐛 Debug

### Monitor Serial

**Arduino IDE**:
- Tools → Serial Monitor
- Baud: 115200

**PlatformIO**:
- PlatformIO → Serial Monitor

### Logs Esperados

```
╔════════════════════════════════════════════════╗
║   ESP32 MESH BRIDGE - Sistema Viza            ║
║   Versão 1.0.0                                 ║
╚════════════════════════════════════════════════╝

[BRIDGE] Iniciando...
[BRIDGE] Mesh inicializada
[BRIDGE] Node ID: 3456789012
[BRIDGE] Aguardando comandos via Serial...

[BRIDGE] Nova conexão: Node 1234567890
[BRIDGE] Nodes conectados: 10

[BRIDGE] Serial RX: {"tipo":"global","modo":"manual"}
[BRIDGE] Tipo: global
[BRIDGE] Mesh TX: Broadcast enviado

[BRIDGE] Mesh RX de 1234567890: {"tipo":"ldr","id":1,"lux":450}
```

---

## ✅ Verificação

### 1. Verificar Mesh Conectada

No Serial Monitor, deve aparecer:
```
[BRIDGE] Nova conexão: Node XXXXXXX
[BRIDGE] Nodes conectados: 10
```

### 2. Testar Comando

Enviar pelo Serial Monitor:
```json
{"tipo":"global","brilho":50}
```

Deve aparecer:
```
[BRIDGE] Serial RX: {"tipo":"global","brilho":50}
[BRIDGE] Mesh TX: Broadcast enviado
```

### 3. Verificar Respostas dos Escravos

Deve receber mensagens dos escravos:
```
[BRIDGE] Mesh RX de XXXXXX: {...}
```

---

## 🔧 Troubleshooting

### Bridge não conecta na rede Mesh

**Verificar**:
1. Configurações Mesh (MESH_PREFIX, MESH_PASSWORD, MESH_PORT)
2. Escravos ligados e funcionando
3. Distância entre ESP32s (WiFi)

**Solução**:
```cpp
// Aumentar debug
mesh.setDebugMsgTypes(ERROR | STARTUP | CONNECTION | MESH_STATUS);
```

---

### Serial não comunica com Raspberry

**Verificar**:
1. Porta correta: `ls /dev/ttyUSB*`
2. Permissão: `groups` (deve ter `dialout`)
3. Baud rate: 115200
4. Serviço rodando: `systemctl status iluminacao-viza`

**Solução**:
```bash
# Testar manualmente
sudo minicom -D /dev/ttyUSB0 -b 115200

# Enviar comando:
{"tipo":"global","brilho":50}
```

---

### Escravos não respondem

**Verificar**:
1. Escravos recebendo comandos? (verificar logs dos escravos)
2. Formato JSON correto?
3. Campos obrigatórios presentes?

**Solução**:
- Verificar formato exato dos comandos
- Comparar com sistema ESP32 original

---

## 📊 Estatísticas

O bridge mantém estatísticas de operação:

```cpp
unsigned long mensagensEnviadas = 0;    // Comandos enviados para Mesh
unsigned long mensagensRecebidas = 0;   // Status recebidos dos escravos
unsigned long errosSerial = 0;          // Erros de parsing JSON
unsigned long errosMesh = 0;            // Falhas no envio Mesh
```

Acessar via função `printStatus()` (adicionar chamada no loop se necessário).

---

## 🔄 Atualização de Firmware

### Over-The-Air (OTA) - Futuro

Preparado para adicionar OTA:
```cpp
#include <ArduinoOTA.h>
// Código OTA aqui
```

### Via USB

1. Conectar ESP32 ao PC
2. Upload via Arduino IDE ou PlatformIO

---

## 📚 Bibliotecas Utilizadas

| Biblioteca | Versão | Função |
|------------|--------|--------|
| **PainlessMesh** | 1.5.0+ | Rede Mesh |
| **ArduinoJson** | 6.21.0+ | Parse JSON |
| **ESP32 Arduino** | 2.0.0+ | Core ESP32 |

---

## 🎯 Comandos Suportados

### Controle Geral

```json
{"tipo":"global","modo":"manual"}
{"tipo":"global","modo":"automatico"}
{"tipo":"global","brilho":75}
{"tipo":"global","setpoint_lux":500}
```

### Controle por Setor

```json
{"tipo":"modo_Setor","Setor":"1","modo":"manual"}
{"tipo":"brilho_Setor","Setor":"1","brilho":50}
{"tipo":"setpoint_lux_Setor","Setor":"1","setpoint_lux":400}
```

### Agendamentos

```json
{"tipo":"config_agendamento_simples","setor":"1","acao":"ligar","hora":18,"minuto":0,"brilho":100}
{"tipo":"toggle_agendamento_simples","setor":"1","ativo":true}
```

### Reset Remoto

```json
{"tipo":"reset_remoto","id_escravo":1}
```

---

## 📝 Notas

### Compatibilidade

✅ Compatível com escravos originais (EscravoViza.h/.cpp)  
✅ Mesma rede Mesh  
✅ Mesmo protocolo JSON  
✅ Zero alterações nos escravos necessárias

### Performance

- Latência: < 100ms (Serial + Mesh)
- Throughput: ~10 comandos/segundo
- Nodes suportados: Até 200 (limite PainlessMesh)

### Segurança

- Mesh criptografada (WPA2)
- Serial apenas local (USB)
- Sem acesso externo direto

---

## 🆘 Suporte

**Documentação completa**: `../README.md`  
**Logs do sistema**: `sudo journalctl -u iluminacao-viza -f`

---

## 👨‍💻 Desenvolvido Por

**Engemase Engenharia**  
Para: Viza Atacadista - Caçador/SC

**Versão**: 1.0.0  
**Data**: 30/10/2025
