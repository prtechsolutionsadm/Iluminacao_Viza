/*
 * ============================================
 * ESP32 MESH BRIDGE
 * Sistema de Iluminação Viza
 * ============================================
 * 
 * Função: Bridge entre Raspberry PI (Serial) e Rede Mesh (Escravos)
 * 
 * Hardware:
 * - ESP32 DevKit
 * - Conectado via USB ao Raspberry PI
 * 
 * Comunicação:
 * - Serial (115200 baud) ↔ Raspberry PI (Python/FastAPI)
 * - Mesh (PainlessMesh) ↔ ESP32 Escravos
 * 
 * Desenvolvido por: Engemase Engenharia
 * Cliente: Viza Atacadista - Caçador/SC
 * Data: 30/10/2025
 * Versão: 1.0.0
 */

#include <painlessMesh.h>
#include <ArduinoJson.h>

// ============================================
// CONFIGURAÇÕES DA REDE MESH
// ============================================
#define MESH_PREFIX     "Iluminação_Viza_Mesh"
#define MESH_PASSWORD   "1F#hVL1lM#"
#define MESH_PORT       5555

// ============================================
// CONFIGURAÇÕES SERIAL
// ============================================
#define SERIAL_BAUD     115200

// ============================================
// INSTÂNCIAS
// ============================================
Scheduler userScheduler;
painlessMesh mesh;

// ============================================
// VARIÁVEIS GLOBAIS
// ============================================
unsigned long lastSerialCheck = 0;
const unsigned long SERIAL_CHECK_INTERVAL = 10; // 10ms

// Estatísticas
unsigned long mensagensEnviadas = 0;
unsigned long mensagensRecebidas = 0;
unsigned long errosSerial = 0;
unsigned long errosMesh = 0;

// ============================================
// PROTÓTIPOS DE FUNÇÕES
// ============================================
void receivedCallback(uint32_t from, String &msg);
void newConnectionCallback(uint32_t nodeId);
void changedConnectionCallback();
void nodeTimeAdjustedCallback(int32_t offset);
void processSerialCommand(String comando);
void sendToRaspberry(String mensagem);

// ============================================
// SETUP
// ============================================
void setup() {
  // Inicializar Serial
  Serial.begin(SERIAL_BAUD);
  delay(1000);
  
  Serial.println();
  Serial.println("╔════════════════════════════════════════════════╗");
  Serial.println("║   ESP32 MESH BRIDGE - Sistema Viza            ║");
  Serial.println("║   Versão 1.0.0                                 ║");
  Serial.println("╚════════════════════════════════════════════════╝");
  Serial.println();
  Serial.println("[BRIDGE] Iniciando...");
  
  // Configurar Mesh
  mesh.setDebugMsgTypes(ERROR | STARTUP | CONNECTION);
  
  // Inicializar Mesh
  mesh.init(MESH_PREFIX, MESH_PASSWORD, &userScheduler, MESH_PORT);
  
  // Callbacks
  mesh.onReceive(&receivedCallback);
  mesh.onNewConnection(&newConnectionCallback);
  mesh.onChangedConnections(&changedConnectionCallback);
  mesh.onNodeTimeAdjusted(&nodeTimeAdjustedCallback);
  
  Serial.println("[BRIDGE] Mesh inicializada");
  Serial.print("[BRIDGE] Node ID: ");
  Serial.println(mesh.getNodeId());
  Serial.println("[BRIDGE] Aguardando comandos via Serial...");
  Serial.println();
}

// ============================================
// LOOP PRINCIPAL
// ============================================
void loop() {
  // Atualizar Mesh
  mesh.update();
  
  // Verificar Serial periodicamente
  if (millis() - lastSerialCheck > SERIAL_CHECK_INTERVAL) {
    lastSerialCheck = millis();
    
    if (Serial.available() > 0) {
      String comando = Serial.readStringUntil('\n');
      comando.trim();
      
      if (comando.length() > 0) {
        processSerialCommand(comando);
      }
    }
  }
}

// ============================================
// PROCESSAR COMANDO RECEBIDO VIA SERIAL
// ============================================
void processSerialCommand(String comando) {
  Serial.print("[BRIDGE] Serial RX: ");
  Serial.println(comando);
  
  // Tentar parsear como JSON
  StaticJsonDocument<512> doc;
  DeserializationError error = deserializeJson(doc, comando);
  
  if (error) {
    Serial.print("[BRIDGE] Erro JSON: ");
    Serial.println(error.c_str());
    errosSerial++;
    return;
  }
  
  // Verificar tipo de comando
  const char* tipo = doc["tipo"];
  
  if (tipo == nullptr) {
    Serial.println("[BRIDGE] Erro: campo 'tipo' ausente");
    errosSerial++;
    return;
  }
  
  Serial.print("[BRIDGE] Tipo: ");
  Serial.println(tipo);
  
  // Repassar para rede Mesh (broadcast para todos os escravos)
  String mensagemMesh;
  serializeJson(doc, mensagemMesh);
  
  if (mesh.sendBroadcast(mensagemMesh)) {
    Serial.println("[BRIDGE] Mesh TX: Broadcast enviado");
    mensagensEnviadas++;
    
    // Confirmar para Raspberry
    sendToRaspberry("{\"status\":\"ok\",\"acao\":\"enviado\"}");
  } else {
    Serial.println("[BRIDGE] Mesh TX: Erro ao enviar");
    errosMesh++;
    
    // Erro para Raspberry
    sendToRaspberry("{\"status\":\"error\",\"erro\":\"falha_mesh\"}");
  }
}

// ============================================
// CALLBACK: MENSAGEM RECEBIDA DA REDE MESH
// ============================================
void receivedCallback(uint32_t from, String &msg) {
  Serial.print("[BRIDGE] Mesh RX de ");
  Serial.print(from);
  Serial.print(": ");
  Serial.println(msg);
  
  mensagensRecebidas++;
  
  // Repassar para Raspberry via Serial
  sendToRaspberry(msg);
}

// ============================================
// CALLBACK: NOVA CONEXÃO NA REDE MESH
// ============================================
void newConnectionCallback(uint32_t nodeId) {
  Serial.print("[BRIDGE] Nova conexão: Node ");
  Serial.println(nodeId);
  
  // Notificar Raspberry
  StaticJsonDocument<128> doc;
  doc["tipo"] = "mesh_evento";
  doc["evento"] = "nova_conexao";
  doc["node_id"] = nodeId;
  
  String mensagem;
  serializeJson(doc, mensagem);
  sendToRaspberry(mensagem);
}

// ============================================
// CALLBACK: MUDANÇA NAS CONEXÕES
// ============================================
void changedConnectionCallback() {
  Serial.println("[BRIDGE] Mudança na topologia da rede");
  
  // Listar nodes conectados
  auto nodes = mesh.getNodeList();
  Serial.print("[BRIDGE] Nodes conectados: ");
  Serial.println(nodes.size());
  
  for (auto node : nodes) {
    Serial.print("  - Node ");
    Serial.println(node);
  }
  
  // Notificar Raspberry
  StaticJsonDocument<256> doc;
  doc["tipo"] = "mesh_evento";
  doc["evento"] = "topologia_mudou";
  doc["total_nodes"] = nodes.size();
  
  JsonArray nodesArray = doc.createNestedArray("nodes");
  for (auto node : nodes) {
    nodesArray.add(node);
  }
  
  String mensagem;
  serializeJson(doc, mensagem);
  sendToRaspberry(mensagem);
}

// ============================================
// CALLBACK: AJUSTE DE TEMPO
// ============================================
void nodeTimeAdjustedCallback(int32_t offset) {
  Serial.print("[BRIDGE] Tempo ajustado: ");
  Serial.print(offset);
  Serial.println(" us");
}

// ============================================
// ENVIAR MENSAGEM PARA RASPBERRY VIA SERIAL
// ============================================
void sendToRaspberry(String mensagem) {
  Serial.println(mensagem);
}

// ============================================
// FUNÇÃO AUXILIAR: STATUS DO BRIDGE
// ============================================
void printStatus() {
  Serial.println();
  Serial.println("╔════════════════════════════════════════════════╗");
  Serial.println("║   STATUS DO BRIDGE                             ║");
  Serial.println("╚════════════════════════════════════════════════╝");
  
  Serial.print("Node ID: ");
  Serial.println(mesh.getNodeId());
  
  Serial.print("Nodes conectados: ");
  Serial.println(mesh.getNodeList().size());
  
  Serial.print("Mensagens enviadas: ");
  Serial.println(mensagensEnviadas);
  
  Serial.print("Mensagens recebidas: ");
  Serial.println(mensagensRecebidas);
  
  Serial.print("Erros Serial: ");
  Serial.println(errosSerial);
  
  Serial.print("Erros Mesh: ");
  Serial.println(errosMesh);
  
  Serial.print("Uptime: ");
  Serial.print(millis() / 1000);
  Serial.println(" segundos");
  
  Serial.println();
}
