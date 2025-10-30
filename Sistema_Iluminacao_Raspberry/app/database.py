"""
Gerenciamento do Banco de Dados SQLite
"""

import sqlite3
from datetime import datetime
from typing import List, Dict, Any, Optional
from contextlib import contextmanager
from app.config import settings
import os

class Database:
    """Gerenciador do banco de dados SQLite"""
    
    def __init__(self, db_path: str = None):
        self.db_path = db_path or settings.DATABASE_PATH
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
    
    @contextmanager
    def get_connection(self):
        """Context manager para conexão com o banco"""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row  # Retornar como dicionário
        try:
            yield conn
            conn.commit()
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            conn.close()
    
    def execute_query(self, query: str, params: tuple = None):
        """Executar query SQL"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            return cursor
    
    def fetch_one(self, query: str, params: tuple = None) -> Optional[Dict]:
        """Buscar um resultado"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            row = cursor.fetchone()
            return dict(row) if row else None
    
    def fetch_all(self, query: str, params: tuple = None) -> List[Dict]:
        """Buscar todos os resultados"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            rows = cursor.fetchall()
            return [dict(row) for row in rows]

def init_db():
    """Criar tabelas do banco de dados"""
    db = Database()
    
    # Tabela de configurações
    db.execute_query("""
        CREATE TABLE IF NOT EXISTS config (
            chave TEXT PRIMARY KEY,
            valor TEXT NOT NULL,
            tipo TEXT DEFAULT 'string',
            descricao TEXT,
            atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    # Tabela de histórico de consumo
    db.execute_query("""
        CREATE TABLE IF NOT EXISTS consumo_historico (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            setor TEXT NOT NULL,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            hora INTEGER NOT NULL,
            minuto INTEGER NOT NULL,
            dia INTEGER NOT NULL,
            mes INTEGER NOT NULL,
            ano INTEGER NOT NULL,
            luminarias_ativas INTEGER DEFAULT 0,
            luminarias_desligadas INTEGER DEFAULT 0,
            luminarias_sem_comunicacao INTEGER DEFAULT 0,
            brilho_medio INTEGER DEFAULT 0,
            lux_medio REAL DEFAULT 0,
            consumo_kwh REAL DEFAULT 0,
            custo_real REAL DEFAULT 0,
            eficiencia REAL DEFAULT 0,
            taxa_operacao REAL DEFAULT 0,
            dados_validos BOOLEAN DEFAULT 1
        )
    """)
    
    # Índice para consultas rápidas
    db.execute_query("""
        CREATE INDEX IF NOT EXISTS idx_consumo_setor_data 
        ON consumo_historico(setor, ano, mes, dia, hora)
    """)
    
    # Tabela de agendamentos
    db.execute_query("""
        CREATE TABLE IF NOT EXISTS agendamentos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            setor TEXT NOT NULL,
            hora_ligar INTEGER,
            minuto_ligar INTEGER,
            hora_desligar INTEGER,
            minuto_desligar INTEGER,
            brilho_ligar INTEGER DEFAULT 100,
            ativo BOOLEAN DEFAULT 1,
            criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    # Tabela de logs do sistema
    db.execute_query("""
        CREATE TABLE IF NOT EXISTS logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            nivel TEXT NOT NULL,
            modulo TEXT,
            mensagem TEXT NOT NULL,
            detalhes TEXT
        )
    """)
    
    # Índice de logs
    db.execute_query("""
        CREATE INDEX IF NOT EXISTS idx_logs_timestamp 
        ON logs(timestamp DESC)
    """)
    
    # Tabela de status dos escravos
    db.execute_query("""
        CREATE TABLE IF NOT EXISTS escravos_status (
            id INTEGER PRIMARY KEY,
            setor TEXT NOT NULL,
            node_id INTEGER,
            brilho INTEGER DEFAULT 0,
            lux REAL DEFAULT 0,
            pwm INTEGER DEFAULT 0,
            modo TEXT DEFAULT 'manual',
            setpoint_lux REAL DEFAULT 300.0,
            comunicacao_ok BOOLEAN DEFAULT 1,
            ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    # Tabela de comandos enviados (auditoria)
    db.execute_query("""
        CREATE TABLE IF NOT EXISTS comandos_auditoria (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            tipo_comando TEXT NOT NULL,
            destino TEXT,
            parametros TEXT,
            usuario TEXT,
            ip_origem TEXT,
            sucesso BOOLEAN DEFAULT 1
        )
    """)
    
    # Inserir configurações padrão
    configuracoes_padrao = [
        ('modo_geral', 'manual', 'string', 'Modo de operação geral (manual/automatico)'),
        ('brilho_geral', '50', 'int', 'Brilho geral em porcentagem (0-100)'),
        ('setpoint_lux_geral', '300.0', 'float', 'Setpoint em lux para modo automático'),
        ('modo_setor_1', 'manual', 'string', 'Modo do Estacionamento'),
        ('modo_setor_2', 'manual', 'string', 'Modo da Loja'),
        ('modo_setor_3', 'manual', 'string', 'Modo do Depósito'),
        ('brilho_setor_1', '50', 'int', 'Brilho do Estacionamento'),
        ('brilho_setor_2', '50', 'int', 'Brilho da Loja'),
        ('brilho_setor_3', '50', 'int', 'Brilho do Depósito'),
        ('tarifa_energia', '0.50', 'float', 'Tarifa de energia em R$/kWh'),
        ('potencia_luminaria', '88.50', 'float', 'Potência de cada luminária em W'),
    ]
    
    for chave, valor, tipo, descricao in configuracoes_padrao:
        db.execute_query("""
            INSERT OR IGNORE INTO config (chave, valor, tipo, descricao)
            VALUES (?, ?, ?, ?)
        """, (chave, valor, tipo, descricao))
    
    print("✓ Banco de dados criado com sucesso!")
    print(f"  Localização: {db.db_path}")
    
    # Verificar tabelas criadas
    tabelas = db.fetch_all("""
        SELECT name FROM sqlite_master 
        WHERE type='table' AND name NOT LIKE 'sqlite_%'
        ORDER BY name
    """)
    
    print(f"  Tabelas criadas: {len(tabelas)}")
    for tabela in tabelas:
        print(f"    - {tabela['name']}")

# Instância global
db = Database()

# Funções auxiliares para acesso rápido
def get_config(chave: str, default: Any = None) -> Any:
    """Obter valor de configuração"""
    result = db.fetch_one("SELECT valor, tipo FROM config WHERE chave = ?", (chave,))
    if not result:
        return default
    
    valor = result['valor']
    tipo = result['tipo']
    
    # Converter tipo
    if tipo == 'int':
        return int(valor)
    elif tipo == 'float':
        return float(valor)
    elif tipo == 'bool':
        return valor.lower() in ('true', '1', 'yes')
    else:
        return valor

def set_config(chave: str, valor: Any, tipo: str = 'string', descricao: str = None):
    """Definir valor de configuração"""
    db.execute_query("""
        INSERT OR REPLACE INTO config (chave, valor, tipo, descricao, atualizado_em)
        VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
    """, (chave, str(valor), tipo, descricao))

def log_event(nivel: str, mensagem: str, modulo: str = None, detalhes: str = None):
    """Registrar evento no log"""
    db.execute_query("""
        INSERT INTO logs (nivel, modulo, mensagem, detalhes)
        VALUES (?, ?, ?, ?)
    """, (nivel, modulo, mensagem, detalhes))

def log_command(tipo_comando: str, destino: str = None, parametros: dict = None, 
                usuario: str = None, ip_origem: str = None, sucesso: bool = True):
    """Registrar comando enviado (auditoria)"""
    import json
    db.execute_query("""
        INSERT INTO comandos_auditoria 
        (tipo_comando, destino, parametros, usuario, ip_origem, sucesso)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (tipo_comando, destino, json.dumps(parametros) if parametros else None,
          usuario, ip_origem, sucesso))

def save_consumo_historico(setor: str, dados: dict):
    """Salvar dados de consumo no histórico"""
    now = datetime.now()
    db.execute_query("""
        INSERT INTO consumo_historico (
            setor, hora, minuto, dia, mes, ano,
            luminarias_ativas, luminarias_desligadas, luminarias_sem_comunicacao,
            brilho_medio, lux_medio, consumo_kwh, custo_real, 
            eficiencia, taxa_operacao, dados_validos
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        setor, now.hour, now.minute, now.day, now.month, now.year,
        dados.get('luminarias_ativas', 0),
        dados.get('luminarias_desligadas', 0),
        dados.get('luminarias_sem_comunicacao', 0),
        dados.get('brilho_medio', 0),
        dados.get('lux_medio', 0),
        dados.get('consumo_kwh', 0),
        dados.get('custo_real', 0),
        dados.get('eficiencia', 0),
        dados.get('taxa_operacao', 0),
        dados.get('dados_validos', True)
    ))

def get_consumo_dia(setor: str, dia: int = None, mes: int = None, ano: int = None) -> List[Dict]:
    """Obter consumo de um dia específico"""
    now = datetime.now()
    dia = dia or now.day
    mes = mes or now.month
    ano = ano or now.year
    
    return db.fetch_all("""
        SELECT * FROM consumo_historico
        WHERE setor = ? AND dia = ? AND mes = ? AND ano = ?
        ORDER BY hora, minuto
    """, (setor, dia, mes, ano))

def update_escravo_status(id_escravo: int, dados: dict):
    """Atualizar status de um escravo"""
    db.execute_query("""
        INSERT OR REPLACE INTO escravos_status (
            id, setor, node_id, brilho, lux, pwm, modo, setpoint_lux,
            comunicacao_ok, ultima_atualizacao
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
    """, (
        id_escravo,
        dados.get('setor'),
        dados.get('node_id'),
        dados.get('brilho', 0),
        dados.get('lux', 0),
        dados.get('pwm', 0),
        dados.get('modo', 'manual'),
        dados.get('setpoint_lux', 300.0),
        dados.get('comunicacao_ok', True)
    ))
