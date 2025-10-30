"""
Rotas de Controle de Iluminação
Endpoints para controlar luminárias via Mesh
"""

from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel, Field
from typing import Optional
from app.mesh_bridge import mesh_bridge
from app.database import set_config, get_config, log_command

router = APIRouter(prefix="/api", tags=["controle"])

# ============================================
# MODELOS DE DADOS
# ============================================

class ModoRequest(BaseModel):
    modo: str = Field(..., description="Modo de operação: manual ou automatico")

class BrilhoRequest(BaseModel):
    brilho: int = Field(..., ge=0, le=100, description="Brilho em porcentagem (0-100)")

class SetpointLuxRequest(BaseModel):
    setpoint_lux: float = Field(..., ge=300.0, le=1000.0, description="Setpoint em lux (300-1000)")

class ModoSetorRequest(BaseModel):
    Setor: str = Field(..., description="Nome do setor")
    modo: str = Field(..., description="Modo: manual ou automatico")

class BrilhoSetorRequest(BaseModel):
    Setor: str = Field(..., description="Nome do setor")
    brilho: int = Field(..., ge=0, le=100, description="Brilho em porcentagem")

class SetpointLuxSetorRequest(BaseModel):
    Setor: str = Field(..., description="Nome do setor")
    setpoint_lux: float = Field(..., ge=300.0, le=1000.0, description="Setpoint em lux")

# ============================================
# CONTROLE GERAL
# ============================================

@router.post("/modo")
async def set_modo_geral(request: ModoRequest):
    """
    Alterar modo de operação geral (manual/automático)
    Aplica para todos os setores
    """
    modo = request.modo.lower()
    
    if modo not in ['manual', 'automatico']:
        raise HTTPException(status_code=400, detail="Modo inválido. Use 'manual' ou 'automatico'")
    
    try:
        # Enviar comando via Mesh
        mesh_bridge.set_modo_geral(modo)
        
        # Salvar no banco
        set_config('modo_geral', modo, 'string')
        
        # Log de auditoria
        log_command('modo_geral', 'todos', {'modo': modo})
        
        return {
            "status": "ok",
            "mensagem": f"Modo geral alterado para: {modo}",
            "modo": modo
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/brilho")
async def set_brilho_geral(request: BrilhoRequest):
    """
    Alterar brilho geral (modo manual)
    Aplica para todos os setores
    """
    brilho = request.brilho
    
    try:
        # Enviar comando via Mesh
        mesh_bridge.set_brilho_geral(brilho)
        
        # Salvar no banco
        set_config('brilho_geral', brilho, 'int')
        
        # Log de auditoria
        log_command('brilho_geral', 'todos', {'brilho': brilho})
        
        return {
            "status": "ok",
            "mensagem": f"Brilho geral alterado para: {brilho}%",
            "brilho": brilho
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/setpoint_lux_geral")
async def set_setpoint_lux_geral(request: SetpointLuxRequest):
    """
    Alterar setpoint em lux para modo automático (geral)
    """
    setpoint = request.setpoint_lux
    
    try:
        # Enviar comando via Mesh
        mesh_bridge.set_setpoint_lux_geral(setpoint)
        
        # Salvar no banco
        set_config('setpoint_lux_geral', setpoint, 'float')
        
        # Log de auditoria
        log_command('setpoint_lux_geral', 'todos', {'setpoint_lux': setpoint})
        
        return {
            "status": "ok",
            "mensagem": f"Setpoint lux geral alterado para: {setpoint} lux",
            "setpoint_lux": setpoint
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============================================
# CONTROLE POR SETOR
# ============================================

@router.post("/modo_setor")
async def set_modo_setor(request: ModoSetorRequest):
    """
    Alterar modo de um setor específico
    """
    setor = request.Setor
    modo = request.modo.lower()
    
    if modo not in ['manual', 'automatico']:
        raise HTTPException(status_code=400, detail="Modo inválido")
    
    try:
        # Enviar comando via Mesh
        mesh_bridge.set_modo_setor(setor, modo)
        
        # Salvar no banco
        setor_id = _get_setor_id(setor)
        if setor_id:
            set_config(f'modo_setor_{setor_id}', modo, 'string')
        
        # Log de auditoria
        log_command('modo_setor', setor, {'modo': modo})
        
        return {
            "status": "ok",
            "mensagem": f"Modo do setor {setor} alterado para: {modo}",
            "setor": setor,
            "modo": modo
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/brilho_setor")
async def set_brilho_setor(request: BrilhoSetorRequest):
    """
    Alterar brilho de um setor específico (modo manual)
    """
    setor = request.Setor
    brilho = request.brilho
    
    try:
        # Enviar comando via Mesh
        mesh_bridge.set_brilho_setor(setor, brilho)
        
        # Salvar no banco
        setor_id = _get_setor_id(setor)
        if setor_id:
            set_config(f'brilho_setor_{setor_id}', brilho, 'int')
        
        # Log de auditoria
        log_command('brilho_setor', setor, {'brilho': brilho})
        
        return {
            "status": "ok",
            "mensagem": f"Brilho do setor {setor} alterado para: {brilho}%",
            "setor": setor,
            "brilho": brilho
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/setpoint_lux_setor")
async def set_setpoint_lux_setor(request: SetpointLuxSetorRequest):
    """
    Alterar setpoint em lux de um setor (modo automático)
    """
    setor = request.Setor
    setpoint = request.setpoint_lux
    
    try:
        # Enviar comando via Mesh
        mesh_bridge.set_setpoint_lux_setor(setor, setpoint)
        
        # Salvar no banco
        setor_id = _get_setor_id(setor)
        if setor_id:
            set_config(f'setpoint_lux_setor_{setor_id}', setpoint, 'float')
        
        # Log de auditoria
        log_command('setpoint_lux_setor', setor, {'setpoint_lux': setpoint})
        
        return {
            "status": "ok",
            "mensagem": f"Setpoint lux do setor {setor} alterado para: {setpoint} lux",
            "setor": setor,
            "setpoint_lux": setpoint
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============================================
# RESET REMOTO
# ============================================

@router.post("/reset_escravo")
async def reset_escravo(id_escravo: int = Body(..., embed=True)):
    """
    Reiniciar um escravo ESP32 remotamente
    """
    try:
        mesh_bridge.resetar_escravo(id_escravo)
        
        log_command('reset_escravo', f'escravo_{id_escravo}', {'id': id_escravo})
        
        return {
            "status": "ok",
            "mensagem": f"Comando de reset enviado para escravo ID {id_escravo}"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============================================
# FUNÇÕES AUXILIARES
# ============================================

def _get_setor_id(setor_nome: str) -> Optional[str]:
    """Converter nome do setor para ID"""
    mapeamento = {
        "Estacionamento": "1",
        "Loja": "2",
        "Deposito": "3"
    }
    return mapeamento.get(setor_nome)
