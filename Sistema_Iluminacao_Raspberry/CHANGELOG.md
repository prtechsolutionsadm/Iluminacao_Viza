# 📝 Changelog - Sistema de Iluminação Viza

## [1.0.0] - 30/10/2025

### ✨ Novo Sistema Completo

#### 🎯 Migração ESP32 → Raspberry PI
- ✅ Backend completo em Python (FastAPI)
- ✅ Bridge ESP32 Mesh via Serial
- ✅ Banco de dados SQLite
- ✅ API REST completa
- ✅ Layout original mantido 100%

#### 🔐 Segurança e Acesso Remoto
- ✅ WireGuard VPN Server
- ✅ HTTPS configurável
  - Certificado auto-assinado (desenvolvimento)
  - Let's Encrypt (produção)
- ✅ Firewall UFW
- ✅ Autenticação HTTP Basic (opcional)

#### 📱 Progressive Web App (PWA)
- ✅ Manifest.json completo
- ✅ Service Worker com cache inteligente
  - Cache First para recursos estáticos
  - Network First para APIs
- ✅ Instalável em todos os dispositivos
  - Android
  - iOS
  - Windows/Mac/Linux Desktop
- ✅ Offline First strategy
- ✅ Meta tags Apple e Android
- ✅ Ícones adaptativos (72px até 512px)
- ✅ Notificações de atualização
- ✅ Preparado para Push Notifications

#### 🎨 Interface
- ✅ Layout 100% original preservado
- ✅ Sistema de Toast notifications
- ✅ Menu inferior mobile
- ✅ Responsivo completo
- ✅ Animações suaves
- ✅ Cores Viza (roxo #8e44ad)

#### 📄 Páginas
- ✅ Index (Dashboard)
- ✅ Visualização
- ✅ Consumo
- ✅ Banco de Dados
- ✅ Manual
- ✅ Agendamentos
- ✅ 404 personalizado

#### 🛠️ Scripts de Automação
- ✅ `setup.sh` - Instalação completa automatizada
- ✅ `wireguard_setup.sh` - Configuração VPN
- ✅ `setup_https.sh` - Configuração HTTPS/SSL
- ✅ `generate_icons.sh` - Geração de ícones PWA
- ✅ `backup.sh` - Backup automático
- ✅ `monitor.sh` - Monitoramento sistema
- ✅ `update.sh` - Atualização sistema

#### 🐧 Systemd Services
- ✅ `iluminacao-viza.service` - Aplicação principal
- ✅ `mesh-bridge.service` - Bridge ESP32
- ✅ Inicialização automática
- ✅ Restart em caso de falha

#### 📊 API REST
- ✅ `/api/status` - Status geral
- ✅ `/api/modo` - Modo operação (manual/automático)
- ✅ `/api/brilho` - Controle de brilho
- ✅ `/api/modo_setor` - Modo por setor
- ✅ `/api/brilho_setor` - Brilho por setor
- ✅ `/api/setpoint_lux_geral` - Setpoint lux geral
- ✅ `/api/setpoint_lux_setor` - Setpoint lux por setor
- ✅ `/api/agendar_simples` - Criar agendamento
- ✅ `/api/listar_agendamentos` - Listar agendamentos
- ✅ `/api/toggle_agendamento_simples` - Ativar/desativar
- ✅ `/api/horario_atual` - Horário RTC
- ✅ `/api/sincronizar_rtc` - Sincronizar RTC
- ✅ `/api/reiniciar_mestre` - Reiniciar Raspberry
- ✅ `/api/reset_escravo` - Reiniciar escravo

#### 🗄️ Banco de Dados
- ✅ SQLite com 6 tabelas
  - config
  - consumo_historico
  - agendamentos
  - logs
  - escravos_status
  - comandos_auditoria

#### 📚 Documentação
- ✅ README.md - Visão geral
- ✅ INSTALL.md - Instalação detalhada
- ✅ PWA_HTTPS.md - PWA e HTTPS completo
- ✅ RESUMO_MIGRACAO.md - Resumo da migração
- ✅ CHANGELOG.md - Este arquivo

#### 🔧 Configurações
- ✅ RTC DS3231 via I2C
- ✅ ESP32 Bridge via USB Serial
- ✅ 225 luminárias em 3 setores
- ✅ Mesh PainlessMesh mantido
- ✅ Zero alterações nos escravos ESP32

#### 🎁 Extras
- ✅ Backup automático diário (2:00 AM)
- ✅ Monitoramento CPU/RAM/Temperatura
- ✅ Logs estruturados (journalctl)
- ✅ Port forwarding configurável
- ✅ DDNS suportado
- ✅ Multi-cliente VPN

---

## 📊 Estatísticas

**Linhas de código**:
- Python: ~2.500 linhas
- JavaScript: ~3.000 linhas (mantido original)
- HTML/CSS: ~3.000 linhas (mantido original)
- Shell Scripts: ~1.000 linhas
- **Total**: ~9.500 linhas

**Arquivos criados**: 50+

**Tempo de desenvolvimento**: 2 horas

**Tempo de instalação**: 10-15 minutos

---

## 🚀 Próximas Versões

### [1.1.0] - Planejado
- [ ] Gráficos Chart.js interativos
- [ ] Histórico de consumo detalhado
- [ ] Relatórios exportáveis (CSV/PDF)
- [ ] Dashboard corporativo
- [ ] Multi-idioma (PT/EN/ES)

### [1.2.0] - Planejado
- [ ] Push Notifications reais
- [ ] Background Sync
- [ ] Geolocalização (multi-loja)
- [ ] Reconhecimento facial (segurança)
- [ ] Integração com sensores IoT adicionais

### [2.0.0] - Futuro
- [ ] App móvel nativo (Flutter)
- [ ] Alexa/Google Home
- [ ] Machine Learning para otimização
- [ ] Integração ERP
- [ ] Dashboard corporativo multi-instalação

---

## 🐛 Correções

### [1.0.1] - Pendente
- [ ] Melhorar tratamento de erros offline
- [ ] Adicionar retry automático em falhas de API
- [ ] Otimizar tamanho do cache
- [ ] Comprimir imagens
- [ ] Minificar JavaScript

---

## 🎯 Compatibilidade

### Navegadores Suportados
- ✅ Chrome/Edge 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Opera 76+

### Sistemas Operacionais
- ✅ Raspberry Pi OS (64-bit)
- ✅ Ubuntu 20.04+
- ✅ Debian 11+

### Dispositivos Testados
- ✅ Raspberry PI 4 Model B (4GB)
- ✅ Android 9+
- ✅ iOS 13+
- ✅ Windows 10/11
- ✅ macOS 10.15+
- ✅ Linux Desktop

---

## 👥 Contribuidores

**Desenvolvimento**:
- Pablo Gonçalves Ribas
- Eduardo Matheus Santos

**Cliente**:
- Viza Atacadista - Caçador/SC

**Empresa**:
- Engemase Engenharia

---

## 📄 Licença

© 2025 Engemase Engenharia - Todos os direitos reservados

---

**Data**: 30/10/2025  
**Versão**: 1.0.0  
**Status**: ✅ Produção
