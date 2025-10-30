"""
Configurações do Sistema de Iluminação Viza
"""

from pydantic_settings import BaseSettings
from typing import Optional
import os

class Settings(BaseSettings):
    """Configurações da aplicação"""
    
    # ============================================
    # APLICAÇÃO
    # ============================================
    APP_NAME: str = "Sistema de Iluminação Viza"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    HOST: str = "0.0.0.0"
    PORT: int = 80
    
    # ============================================
    # BANCO DE DADOS
    # ============================================
    DATABASE_PATH: str = "data/iluminacao_viza.db"
    DATABASE_URL: str = f"sqlite:///{DATABASE_PATH}"
    
    # ============================================
    # ESP32 MESH BRIDGE
    # ============================================
    ESP32_PORT: str = "/dev/ttyUSB0"
    ESP32_BAUDRATE: int = 115200
    ESP32_TIMEOUT: int = 5
    
    # Configurações Mesh (compatível com ESP32)
    MESH_PREFIX: str = "Iluminação_Viza_Mesh"
    MESH_PASSWORD: str = "1F#hVL1lM#"
    MESH_PORT: int = 5555
    
    # ============================================
    # RTC DS3231 (I2C)
    # ============================================
    I2C_BUS: int = 1
    RTC_ADDRESS: int = 0x68
    
    # ============================================
    # SISTEMA DE ILUMINAÇÃO
    # ============================================
    # Setores
    SETORES: list = ["Estacionamento", "Loja", "Deposito"]
    SETOR_IDS: dict = {"1": "Estacionamento", "2": "Loja", "3": "Deposito"}
    
    # Luminárias por setor
    LUMINARIAS_ESTACIONAMENTO: int = 225
    LUMINARIAS_LOJA: int = 100
    LUMINARIAS_DEPOSITO: int = 75
    
    # Faixas de operação
    FAIXA_LUX_MIN: float = 300.0
    FAIXA_LUX_MAX: float = 1000.0
    BRILHO_MIN: int = 0
    BRILHO_MAX: int = 100
    
    # PID (referência dos escravos)
    PID_KP: float = 0.2
    PID_KI: float = 0.001
    PID_KD: float = 0.05
    
    # ============================================
    # CONSUMO E TARIFAS
    # ============================================
    POTENCIA_POR_LUMINARIA: float = 88.50  # Watts
    TARIFA_ENERGIA: float = 0.50  # R$ por kWh
    
    # ============================================
    # SERVIDOR DE BANCO DE DADOS EXTERNO (opcional)
    # ============================================
    DATABASE_SERVER_IP: Optional[str] = None
    DATABASE_SERVER_PORT: int = 5000
    DATABASE_SYNC_ENABLED: bool = False
    DATABASE_SYNC_INTERVAL: int = 60  # segundos
    
    # ============================================
    # SEGURANÇA
    # ============================================
    SECRET_KEY: str = "viza-iluminacao-secret-key-2025"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    
    # Autenticação HTTP Basic (endpoints críticos)
    HTTP_AUTH_ENABLED: bool = False
    HTTP_AUTH_USERNAME: str = "admin"
    HTTP_AUTH_PASSWORD: str = "viza2025"
    
    # ============================================
    # WIREGUARD VPN
    # ============================================
    VPN_NETWORK: str = "10.0.0.0/24"
    VPN_SERVER_IP: str = "10.0.0.1"
    VPN_PORT: int = 51820
    
    # ============================================
    # LOGS
    # ============================================
    LOG_LEVEL: str = "INFO"
    LOG_FILE: str = "logs/iluminacao_viza.log"
    LOG_ROTATION: str = "10 MB"
    LOG_RETENTION: str = "30 days"
    
    # ============================================
    # AGENDAMENTOS
    # ============================================
    AGENDAMENTO_INTERVALO_VERIFICACAO: int = 30  # segundos
    
    # ============================================
    # MONITORAMENTO
    # ============================================
    MONITOR_INTERVAL: int = 5  # segundos
    MONITOR_CPU_THRESHOLD: float = 80.0  # %
    MONITOR_MEMORY_THRESHOLD: float = 85.0  # %
    MONITOR_TEMP_THRESHOLD: float = 75.0  # °C
    
    # ============================================
    # BACKUP
    # ============================================
    BACKUP_DIR: str = "backups"
    BACKUP_RETENTION_DAYS: int = 30
    BACKUP_ENABLED: bool = True
    
    # ============================================
    # CAMINHOS
    # ============================================
    BASE_DIR: str = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    STATIC_DIR: str = os.path.join(BASE_DIR, "static")
    TEMPLATES_DIR: str = os.path.join(BASE_DIR, "templates")
    DATA_DIR: str = os.path.join(BASE_DIR, "data")
    LOGS_DIR: str = os.path.join(BASE_DIR, "logs")
    BACKUPS_DIR: str = os.path.join(BASE_DIR, "backups")
    
    class Config:
        env_file = ".env"
        case_sensitive = True

# Instância global de configurações
settings = Settings()

# Criar diretórios necessários
for directory in [settings.DATA_DIR, settings.LOGS_DIR, settings.BACKUPS_DIR]:
    os.makedirs(directory, exist_ok=True)
