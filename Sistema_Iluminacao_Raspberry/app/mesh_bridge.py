"""
Bridge de Comunicação ESP32 Mesh
Gerencia comunicação serial com ESP32 que atua como ponte Mesh
"""

import serial
import json
import time
import threading
from typing import Dict, Callable, Optional, Any
from queue import Queue
from datetime import datetime
from app.config import settings
from app.database import log_event, update_escravo_status
import logging

logger = logging.getLogger(__name__)

class MeshBridge:
    """Ponte de comunicação com rede Mesh ESP32"""
    
    def __init__(self, port: str = None, baudrate: int = None):
        self.port = port or settings.ESP32_PORT
        self.baudrate = baudrate or settings.ESP32_BAUDRATE
        self.serial_conn: Optional[serial.Serial] = None
        self.running = False
        self.read_thread: Optional[threading.Thread] = None
        
        # Filas de mensagens
        self.tx_queue = Queue()  # Mensagens a enviar
        self.rx_queue = Queue()  # Mensagens recebidas
        
        # Callbacks para processar mensagens recebidas
        self.message_callbacks: Dict[str, Callable] = {}
        
        # Status dos escravos
        self.escravos_status: Dict[int, Dict] = {}
        
        # Estatísticas
        self.stats = {
            'mensagens_enviadas': 0,
            'mensagens_recebidas': 0,
            'erros_comunicacao': 0,
            'ultima_mensagem': None
        }
    
    def connect(self) -> bool:
        """Conectar à porta serial ESP32"""
        try:
            self.serial_conn = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                timeout=1,
                write_timeout=1
            )
            
            time.sleep(2)  # Aguardar ESP32 reiniciar
            
            logger.info(f"Conectado ao ESP32 Bridge na porta {self.port}")
            log_event('INFO', f'ESP32 Bridge conectado: {self.port}', 'mesh_bridge')
            
            return True
            
        except serial.SerialException as e:
            logger.error(f"Erro ao conectar ESP32: {e}")
            log_event('ERROR', f'Erro ao conectar ESP32: {e}', 'mesh_bridge')
            return False
    
    def disconnect(self):
        """Desconectar porta serial"""
        if self.serial_conn and self.serial_conn.is_open:
            self.serial_conn.close()
            logger.info("ESP32 Bridge desconectado")
            log_event('INFO', 'ESP32 Bridge desconectado', 'mesh_bridge')
    
    def start(self):
        """Iniciar threads de comunicação"""
        if not self.connect():
            raise Exception("Não foi possível conectar ao ESP32 Bridge")
        
        self.running = True
        
        # Thread de leitura
        self.read_thread = threading.Thread(target=self._read_loop, daemon=True)
        self.read_thread.start()
        
        # Thread de escrita
        self.write_thread = threading.Thread(target=self._write_loop, daemon=True)
        self.write_thread.start()
        
        logger.info("Mesh Bridge iniciado")
        log_event('INFO', 'Mesh Bridge iniciado', 'mesh_bridge')
    
    def stop(self):
        """Parar threads de comunicação"""
        self.running = False
        
        if self.read_thread:
            self.read_thread.join(timeout=2)
        
        if self.write_thread:
            self.write_thread.join(timeout=2)
        
        self.disconnect()
        logger.info("Mesh Bridge parado")
        log_event('INFO', 'Mesh Bridge parado', 'mesh_bridge')
    
    def _read_loop(self):
        """Loop de leitura de mensagens"""
        buffer = ""
        
        while self.running:
            try:
                if self.serial_conn and self.serial_conn.in_waiting > 0:
                    data = self.serial_conn.read(self.serial_conn.in_waiting).decode('utf-8', errors='ignore')
                    buffer += data
                    
                    # Processar linhas completas
                    while '\n' in buffer:
                        line, buffer = buffer.split('\n', 1)
                        line = line.strip()
                        
                        if line:
                            self._process_received_message(line)
                
                time.sleep(0.01)  # Evitar uso excessivo de CPU
                
            except Exception as e:
                logger.error(f"Erro na leitura serial: {e}")
                self.stats['erros_comunicacao'] += 1
                time.sleep(1)
    
    def _write_loop(self):
        """Loop de envio de mensagens"""
        while self.running:
            try:
                if not self.tx_queue.empty():
                    message = self.tx_queue.get(timeout=0.1)
                    self._send_message(message)
                else:
                    time.sleep(0.01)
                    
            except Exception as e:
                logger.error(f"Erro no envio serial: {e}")
                self.stats['erros_comunicacao'] += 1
                time.sleep(1)
    
    def _process_received_message(self, line: str):
        """Processar mensagem recebida"""
        try:
            # Tentar parsear como JSON
            if line.startswith('{'):
                data = json.loads(line)
                self.stats['mensagens_recebidas'] += 1
                self.stats['ultima_mensagem'] = datetime.now().isoformat()
                
                # Processar diferentes tipos de mensagem
                tipo = data.get('tipo', '')
                
                if tipo == 'status_Setores':
                    self._process_status_setores(data)
                elif tipo == 'ldr':
                    self._process_ldr(data)
                elif tipo == 'agendamento_status':
                    self._process_agendamento_status(data)
                
                # Callbacks registrados
                if tipo in self.message_callbacks:
                    self.message_callbacks[tipo](data)
                
                # Adicionar à fila de recebidos
                self.rx_queue.put(data)
                
            else:
                # Log normal (não JSON)
                logger.debug(f"ESP32: {line}")
                
        except json.JSONDecodeError:
            # Não é JSON, apenas log
            logger.debug(f"ESP32: {line}")
        except Exception as e:
            logger.error(f"Erro ao processar mensagem: {e}")
    
    def _process_status_setores(self, data: Dict):
        """Processar status dos setores"""
        grupo = data.get('grupo', {})
        
        for id_luminaria, brilho in grupo.items():
            id_int = int(id_luminaria)
            
            # Atualizar status local
            if id_int not in self.escravos_status:
                self.escravos_status[id_int] = {}
            
            self.escravos_status[id_int]['brilho'] = brilho
            self.escravos_status[id_int]['ultima_atualizacao'] = datetime.now().isoformat()
            
            # Atualizar banco de dados
            setor = self._determinar_setor(id_int)
            if setor:
                update_escravo_status(id_int, {
                    'setor': setor,
                    'brilho': brilho,
                    'comunicacao_ok': True
                })
    
    def _process_ldr(self, data: Dict):
        """Processar leitura do sensor LDR"""
        id_escravo = data.get('id')
        setor = data.get('setor')
        lux = data.get('lux', 0)
        brilho = data.get('percentual brilho', 0)
        
        if id_escravo:
            # Atualizar status
            if id_escravo not in self.escravos_status:
                self.escravos_status[id_escravo] = {}
            
            self.escravos_status[id_escravo].update({
                'setor': setor,
                'lux': lux,
                'brilho': brilho,
                'ultima_atualizacao': datetime.now().isoformat()
            })
            
            # Atualizar banco
            update_escravo_status(id_escravo, {
                'setor': setor,
                'lux': lux,
                'brilho': brilho,
                'comunicacao_ok': True
            })
    
    def _process_agendamento_status(self, data: Dict):
        """Processar status de agendamento"""
        logger.info(f"Agendamento: {data.get('status')}")
    
    def _send_message(self, message: Dict):
        """Enviar mensagem via serial"""
        try:
            if self.serial_conn and self.serial_conn.is_open:
                json_str = json.dumps(message) + '\n'
                self.serial_conn.write(json_str.encode('utf-8'))
                self.serial_conn.flush()
                
                self.stats['mensagens_enviadas'] += 1
                logger.debug(f"Enviado: {message}")
                
        except Exception as e:
            logger.error(f"Erro ao enviar mensagem: {e}")
            self.stats['erros_comunicacao'] += 1
    
    def send_command(self, command: Dict):
        """Enviar comando para a rede Mesh"""
        self.tx_queue.put(command)
        logger.info(f"Comando enfileirado: {command.get('tipo')}")
    
    def broadcast_json(self, key: str, value: Any):
        """Enviar broadcast simples (compatível com Mestre.ino)"""
        self.send_command({key: value})
    
    def set_modo_geral(self, modo: str):
        """Definir modo geral (manual/automatico)"""
        self.send_command({
            'tipo': 'global',
            'modo': modo
        })
        log_event('INFO', f'Modo geral alterado: {modo}', 'mesh_bridge')
    
    def set_brilho_geral(self, brilho: int):
        """Definir brilho geral"""
        self.send_command({
            'tipo': 'global',
            'brilho': brilho
        })
        log_event('INFO', f'Brilho geral alterado: {brilho}%', 'mesh_bridge')
    
    def set_setpoint_lux_geral(self, setpoint_lux: float):
        """Definir setpoint em lux geral"""
        self.send_command({
            'tipo': 'global',
            'setpoint_lux': setpoint_lux
        })
        log_event('INFO', f'Setpoint lux geral: {setpoint_lux} lux', 'mesh_bridge')
    
    def set_modo_setor(self, setor: str, modo: str):
        """Definir modo de um setor"""
        self.send_command({
            'tipo': 'modo_Setor',
            'Setor': setor,
            'modo': modo
        })
        log_event('INFO', f'Modo setor {setor}: {modo}', 'mesh_bridge')
    
    def set_brilho_setor(self, setor: str, brilho: int):
        """Definir brilho de um setor"""
        self.send_command({
            'tipo': 'brilho_Setor',
            'Setor': setor,
            'brilho': brilho
        })
        log_event('INFO', f'Brilho setor {setor}: {brilho}%', 'mesh_bridge')
    
    def set_setpoint_lux_setor(self, setor: str, setpoint_lux: float):
        """Definir setpoint em lux de um setor"""
        self.send_command({
            'tipo': 'setpoint_lux_Setor',
            'Setor': setor,
            'setpoint_lux': setpoint_lux
        })
        log_event('INFO', f'Setpoint lux setor {setor}: {setpoint_lux} lux', 'mesh_bridge')
    
    def enviar_horario_atual(self, hora: int, minuto: int):
        """Enviar horário atual para os escravos"""
        self.send_command({
            'tipo': 'horario_atual',
            'hora': hora,
            'minuto': minuto
        })
    
    def configurar_agendamento(self, setor: str, acao: str, hora: int, minuto: int, brilho: int = 100):
        """Configurar agendamento de um setor"""
        self.send_command({
            'tipo': 'config_agendamento_simples',
            'setor': setor,
            'acao': acao,
            'hora': hora,
            'minuto': minuto,
            'brilho': brilho
        })
        log_event('INFO', f'Agendamento {setor}: {acao} às {hora:02d}:{minuto:02d}', 'mesh_bridge')
    
    def toggle_agendamento(self, setor: str, ativo: bool):
        """Ativar/desativar agendamento de um setor"""
        self.send_command({
            'tipo': 'toggle_agendamento_simples',
            'setor': setor,
            'ativo': ativo
        })
        log_event('INFO', f'Agendamento {setor}: {"ativo" if ativo else "inativo"}', 'mesh_bridge')
    
    def resetar_escravo(self, id_escravo: int):
        """Resetar um escravo específico"""
        self.send_command({
            'tipo': 'reset_remoto',
            'id_escravo': id_escravo
        })
        log_event('WARNING', f'Reset remoto escravo ID {id_escravo}', 'mesh_bridge')
    
    def register_callback(self, tipo_mensagem: str, callback: Callable):
        """Registrar callback para tipo de mensagem"""
        self.message_callbacks[tipo_mensagem] = callback
    
    def _determinar_setor(self, id_luminaria: int) -> Optional[str]:
        """Determinar setor baseado no ID da luminária"""
        # Baseado na configuração original do sistema
        # Estacionamento: 1-225
        # Loja: 226-325
        # Depósito: 326-400
        
        if 1 <= id_luminaria <= 225:
            return "Estacionamento"
        elif 226 <= id_luminaria <= 325:
            return "Loja"
        elif 326 <= id_luminaria <= 400:
            return "Deposito"
        else:
            return None
    
    def get_status(self) -> Dict:
        """Obter status da bridge"""
        return {
            'conectado': self.serial_conn and self.serial_conn.is_open if self.serial_conn else False,
            'porta': self.port,
            'baudrate': self.baudrate,
            'running': self.running,
            'escravos_ativos': len(self.escravos_status),
            'estatisticas': self.stats.copy()
        }
    
    def get_escravos_status(self) -> Dict:
        """Obter status de todos os escravos"""
        return self.escravos_status.copy()

# Instância global
mesh_bridge = MeshBridge()
