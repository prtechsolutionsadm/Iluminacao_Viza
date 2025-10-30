# 🧪 Testes do ESP32 Bridge

## 🎯 Objetivo

Validar comunicação entre Raspberry PI ↔ Bridge ↔ Escravos

---

## 📋 Pré-requisitos

- ✅ ESP32 Bridge programado e conectado ao Raspberry
- ✅ Escravos ESP32 ligados e funcionando
- ✅ Raspberry com sistema instalado

---

## 🔬 Teste 1: Bridge Standalone (Serial Monitor)

### Abrir Serial Monitor

**Arduino IDE**:
- Tools → Serial Monitor
- Baud: 115200

### Enviar Comandos de Teste

**Teste 1.1 - Modo Manual**:
```json
{"tipo":"global","modo":"manual"}
```

**Esperado**:
```
[BRIDGE] Serial RX: {"tipo":"global","modo":"manual"}
[BRIDGE] Tipo: global
[BRIDGE] Mesh TX: Broadcast enviado
```

---

**Teste 1.2 - Brilho Geral**:
```json
{"tipo":"global","brilho":75}
```

**Esperado**:
```
[BRIDGE] Serial RX: {"tipo":"global","brilho":75}
[BRIDGE] Tipo: global
[BRIDGE] Mesh TX: Broadcast enviado
[BRIDGE] Mesh RX de XXXXXXX: {"tipo":"status_Setores",...}
```

---

**Teste 1.3 - Brilho Setor**:
```json
{"tipo":"brilho_Setor","Setor":"1","brilho":50}
```

**Esperado**:
```
[BRIDGE] Serial RX: {"tipo":"brilho_Setor","Setor":"1","brilho":50}
[BRIDGE] Tipo: brilho_Setor
[BRIDGE] Mesh TX: Broadcast enviado
```

---

## 🔬 Teste 2: Comunicação Python (Raspberry)

### Script de Teste

Salvar como `test_bridge.py`:

```python
#!/usr/bin/env python3
import serial
import json
import time

# Conectar ao ESP32
ser = serial.Serial('/dev/ttyUSB0', 115200, timeout=1)
time.sleep(2)  # Aguardar inicialização

print("=== Teste ESP32 Bridge ===\n")

# Teste 1: Modo Manual
print("Teste 1: Modo Manual")
comando = {"tipo": "global", "modo": "manual"}
ser.write((json.dumps(comando) + '\n').encode())
time.sleep(0.5)

# Ler resposta
if ser.in_waiting:
    response = ser.readline().decode().strip()
    print(f"Resposta: {response}\n")

# Teste 2: Brilho Geral
print("Teste 2: Brilho Geral 75%")
comando = {"tipo": "global", "brilho": 75}
ser.write((json.dumps(comando) + '\n').encode())
time.sleep(0.5)

if ser.in_waiting:
    response = ser.readline().decode().strip()
    print(f"Resposta: {response}\n")

# Teste 3: Brilho Setor
print("Teste 3: Brilho Setor 1 - 50%")
comando = {"tipo": "brilho_Setor", "Setor": "1", "brilho": 50}
ser.write((json.dumps(comando) + '\n').encode())
time.sleep(0.5)

if ser.in_waiting:
    response = ser.readline().decode().strip()
    print(f"Resposta: {response}\n")

# Teste 4: Escutar por 5 segundos (receber status dos escravos)
print("Teste 4: Escutando mensagens dos escravos (5s)...")
inicio = time.time()
while time.time() - inicio < 5:
    if ser.in_waiting:
        mensagem = ser.readline().decode().strip()
        print(f"Recebido: {mensagem}")
    time.sleep(0.1)

print("\n=== Testes Concluídos ===")
ser.close()
```

### Executar Teste

```bash
chmod +x test_bridge.py
python3 test_bridge.py
```

**Saída Esperada**:
```
=== Teste ESP32 Bridge ===

Teste 1: Modo Manual
Resposta: {"status":"ok","acao":"enviado"}

Teste 2: Brilho Geral 75%
Resposta: {"status":"ok","acao":"enviado"}

Teste 3: Brilho Setor 1 - 50%
Resposta: {"status":"ok","acao":"enviado"}

Teste 4: Escutando mensagens dos escravos (5s)...
Recebido: {"tipo":"status_Setores","grupo":{"1":50,"2":75,...}}
Recebido: {"tipo":"ldr","id":1,"setor":"Estacionamento","lux":450.5}
...

=== Testes Concluídos ===
```

---

## 🔬 Teste 3: Sistema Completo (FastAPI)

### Verificar Serviço

```bash
sudo systemctl status iluminacao-viza
```

**Esperado**: `active (running)`

---

### Testar API

```bash
# Modo Manual
curl -X POST http://localhost/api/modo \
  -H "Content-Type: application/json" \
  -d '{"modo":"manual"}'

# Brilho Geral
curl -X POST http://localhost/api/brilho \
  -H "Content-Type: application/json" \
  -d '{"brilho":75}'

# Verificar Status
curl http://localhost/api/status
```

---

### Ver Logs

```bash
sudo journalctl -u iluminacao-viza -f
```

**Esperado**:
```
[INFO] Comando recebido: modo = manual
[INFO] Enviando para Bridge: {"tipo":"global","modo":"manual"}
[INFO] Bridge confirmou: enviado
```

---

## 🔬 Teste 4: Interface Web

### Acessar Dashboard

```
Local: http://raspberrypi.local
VPN:   http://10.0.0.1
```

### Testar Controles

1. **Modo Manual** → Clicar botão
2. **Slider de Brilho** → Arrastar
3. **Setor** → Selecionar e ajustar
4. **Verificar logs** no navegador (F12 → Console)

**Esperado**: Comandos sendo enviados e escravos respondendo

---

## 📊 Checklist de Validação

### Bridge

- [ ] ESP32 liga e mostra logs
- [ ] Conecta na rede Mesh
- [ ] Mostra nodes conectados
- [ ] Recebe comandos via Serial
- [ ] Envia para rede Mesh
- [ ] Recebe status dos escravos
- [ ] Envia status para Serial

### Raspberry

- [ ] Detecta ESP32 em `/dev/ttyUSB0`
- [ ] Serviço `iluminacao-viza` rodando
- [ ] API responde a comandos
- [ ] Logs mostram comunicação
- [ ] Dashboard funcional

### Escravos

- [ ] Recebem comandos via Mesh
- [ ] Executam ações (brilho, modo)
- [ ] Enviam status de volta
- [ ] LDR reportando lux

### End-to-End

- [ ] Dashboard → API → Bridge → Escravo → Status → Dashboard
- [ ] Latência < 500ms
- [ ] Sem erros nos logs

---

## 🐛 Troubleshooting

### Bridge não responde

**Verificar**:
```bash
# Porta correta?
ls /dev/ttyUSB*

# Permissão?
groups | grep dialout

# Testar manualmente
sudo minicom -D /dev/ttyUSB0 -b 115200
```

---

### Escravos não respondem

**Verificar**:
1. Configurações Mesh corretas?
2. Escravos ligados?
3. Distância WiFi OK?
4. Serial Monitor do bridge mostra conexões?

---

### Latência alta

**Otimizar**:
1. Reduzir `SERIAL_CHECK_INTERVAL` (ESP32)
2. Aumentar baud rate (se suportado)
3. Aproximar ESP32s

---

## 📈 Benchmarks Esperados

| Métrica | Valor Esperado |
|---------|----------------|
| **Latência total** | 100-300ms |
| **Comandos/segundo** | 10-20 |
| **Taxa de sucesso** | > 99% |
| **Nodes conectados** | 10 (ou mais) |
| **Uptime** | 99.9%+ |

---

## ✅ Critérios de Sucesso

### Mínimo Viável

- [x] Bridge conecta na Mesh
- [x] Recebe comandos via Serial
- [x] Envia para escravos
- [x] Escravos respondem
- [x] Dashboard funcional

### Produção

- [x] Latência < 500ms
- [x] Taxa de sucesso > 95%
- [x] Uptime > 24h contínuas
- [x] Todos os 10 escravos conectados
- [x] Logs limpos (sem erros críticos)

---

## 📝 Registro de Testes

### Template

```
Data: ___/___/2025
Testador: _____________
ESP32 Bridge ID: _____________

Teste 1 - Bridge Standalone:       [ ] OK  [ ] FALHOU
Teste 2 - Python Serial:           [ ] OK  [ ] FALHOU
Teste 3 - API FastAPI:             [ ] OK  [ ] FALHOU
Teste 4 - Interface Web:           [ ] OK  [ ] FALHOU

Latência média: _____ ms
Nodes conectados: _____
Taxa de sucesso: _____%

Observações:
_________________________________
_________________________________
_________________________________

Assinatura: _____________
```

---

## 🎉 Conclusão

Se todos os testes passaram:

✅ **Sistema 100% Funcional!**

- Bridge comunicando
- Escravos respondendo
- Dashboard operacional
- Pronto para produção!

---

**Desenvolvido por Engemase Engenharia**  
**Para Viza Atacadista - Caçador/SC**
