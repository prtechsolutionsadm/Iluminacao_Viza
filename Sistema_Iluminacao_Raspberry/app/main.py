"""
Sistema de Iluminação Viza - Raspberry PI
Aplicação Principal FastAPI
"""

from fastapi import FastAPI, Request, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse, JSONResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn
import logging
import os
from datetime import datetime

from app.config import settings
from app.database import init_db, log_event
from app.mesh_bridge import mesh_bridge

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ============================================
# LIFESPAN - Inicialização e Finalização
# ============================================
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gerenciar ciclo de vida da aplicação"""
    # Inicialização
    logger.info("=" * 60)
    logger.info("INICIANDO SISTEMA DE ILUMINAÇÃO VIZA")
    logger.info("Desenvolvido por: Engemase Engenharia")
    logger.info("Cliente: Viza Atacadista - Caçador/SC")
    logger.info("=" * 60)
    
    # Inicializar banco de dados
    try:
        init_db()
        log_event('INFO', 'Sistema inicializado', 'main')
    except Exception as e:
        logger.error(f"Erro ao inicializar banco: {e}")
    
    # Iniciar bridge Mesh
    try:
        mesh_bridge.start()
        logger.info("✓ ESP32 Mesh Bridge iniciado")
    except Exception as e:
        logger.error(f"✗ Erro ao iniciar Mesh Bridge: {e}")
        log_event('ERROR', f'Erro ao iniciar Mesh Bridge: {e}', 'main')
    
    yield
    
    # Finalização
    logger.info("Encerrando sistema...")
    mesh_bridge.stop()
    log_event('INFO', 'Sistema encerrado', 'main')
    logger.info("Sistema encerrado com sucesso")

# ============================================
# CRIAR APLICAÇÃO FASTAPI
# ============================================
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    lifespan=lifespan
)

# CORS - Permitir acesso de qualquer origem
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Arquivos estáticos e templates
app.mount("/static", StaticFiles(directory=settings.STATIC_DIR), name="static")
templates = Jinja2Templates(directory=settings.TEMPLATES_DIR)

# ============================================
# ROTAS PWA
# ============================================

@app.get("/manifest.json")
async def manifest():
    """Manifest PWA"""
    return FileResponse(os.path.join(settings.STATIC_DIR, "manifest.json"))

@app.get("/service-worker.js")
async def service_worker():
    """Service Worker"""
    return FileResponse(os.path.join(settings.STATIC_DIR, "service-worker.js"), 
                       media_type="application/javascript")

# ============================================
# ROTAS PRINCIPAIS (HTML)
# ============================================

@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    """Página principal - Dashboard"""
    return templates.TemplateResponse("index.html", {"request": request})

@app.get("/controle", response_class=HTMLResponse)
async def controle(request: Request):
    """Página de controle manual"""
    return templates.TemplateResponse("controle.html", {"request": request})

@app.get("/visualizacao", response_class=HTMLResponse)
async def visualizacao(request: Request):
    """Página de visualização detalhada"""
    return templates.TemplateResponse("visualizacao.html", {"request": request})

@app.get("/consumo", response_class=HTMLResponse)
async def consumo(request: Request):
    """Página de análise de consumo"""
    return templates.TemplateResponse("consumo.html", {"request": request})

@app.get("/agendamentos", response_class=HTMLResponse)
async def agendamentos(request: Request):
    """Página de agendamentos"""
    return templates.TemplateResponse("agendamentos.html", {"request": request})

@app.get("/banco", response_class=HTMLResponse)
async def banco(request: Request):
    """Página de banco de dados"""
    return templates.TemplateResponse("banco.html", {"request": request})

@app.get("/manual", response_class=HTMLResponse)
async def manual(request: Request):
    """Página de manual"""
    return templates.TemplateResponse("manual.html", {"request": request})

# ============================================
# API REST - Status e Informações
# ============================================

@app.get("/api/status")
async def api_status():
    """Status geral do sistema"""
    mesh_status = mesh_bridge.get_status()
    
    return {
        "status": "online",
        "timestamp": datetime.now().isoformat(),
        "versao": settings.APP_VERSION,
        "sistema": settings.APP_NAME,
        "mesh_bridge": mesh_status,
        "configuracoes": {
            "modo_geral": "manual",  # Buscar do banco
            "brilho_geral": 50,
            "setpoint_lux_geral": 300.0
        }
    }

@app.get("/api/info")
async def api_info():
    """Informações do sistema"""
    return {
        "nome": settings.APP_NAME,
        "versao": settings.APP_VERSION,
        "desenvolvedor": "Engemase Engenharia",
        "cliente": "Viza Atacadista",
        "local": "Caçador/SC",
        "setores": settings.SETORES,
        "luminarias": {
            "estacionamento": settings.LUMINARIAS_ESTACIONAMENTO,
            "loja": settings.LUMINARIAS_LOJA,
            "deposito": settings.LUMINARIAS_DEPOSITO,
            "total": (settings.LUMINARIAS_ESTACIONAMENTO + 
                     settings.LUMINARIAS_LOJA + 
                     settings.LUMINARIAS_DEPOSITO)
        }
    }

# ============================================
# IMPORTAR ROTAS DOS MÓDULOS
# ============================================

from app.routes.controle import router as controle_router

# Incluir rotas da API
app.include_router(controle_router)

# ============================================
# HANDLER DE ERRO 404
# ============================================

@app.exception_handler(404)
async def not_found_handler(request: Request, exc: HTTPException):
    """Página 404 personalizada"""
    try:
        return templates.TemplateResponse("404.html", {"request": request}, status_code=404)
    except:
        return JSONResponse(
            status_code=404,
            content={"detail": "Página não encontrada"}
        )

# ============================================
# FUNÇÃO PRINCIPAL
# ============================================

def main():
    """Iniciar servidor"""
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level="info"
    )

if __name__ == "__main__":
    main()
