# 🔐 HTTPS + PWA - Sistema de Iluminação Viza

## 📋 Visão Geral

O sistema foi configurado como **Progressive Web App (PWA)** completo com suporte a HTTPS para máxima segurança e funcionalidade offline.

---

## 🌐 HTTPS - Conexão Segura

### Por que HTTPS é necessário?

✅ **Service Workers** exigem HTTPS (exceto localhost)  
✅ **PWA instalável** requer HTTPS  
✅ **Segurança** de dados e credenciais  
✅ **Criptografia** de comunicação  
✅ **Confiabilidade** do navegador

---

## 🔧 Configurar HTTPS

### Opção 1: Certificado Auto-assinado (Desenvolvimento/Rede Local)

```bash
cd ~/sistema-iluminacao-viza
chmod +x scripts/setup_https.sh
sudo ./scripts/setup_https.sh

# Escolher opção 1
```

**✅ Vantagens**:
- Rápido e fácil
- Funciona em rede local
- Gratuito
- Ideal para desenvolvimento

**⚠️ Desvantagens**:
- Navegadores mostram aviso de "Não seguro"
- Não é confiável publicamente
- Usuário precisa aceitar manualmente

**Acesso**:
```
Local:  https://raspberrypi.local
VPN:    https://10.0.0.1
IP:     https://192.168.1.X
```

**Aceitar Certificado**:
- Chrome/Edge: Clicar em "Avançado" → "Continuar"
- Firefox: "Avançado" → "Aceitar o risco"
- Safari: "Mostrar detalhes" → "Visitar site"

---

### Opção 2: Let's Encrypt (Produção com Domínio)

```bash
cd ~/sistema-iluminacao-viza
sudo ./scripts/setup_https.sh

# Escolher opção 2
# Informar domínio público
```

**Requisitos**:
- Domínio público (ex: `iluminacao.viza.com.br`)
- IP público acessível
- Portas 80 e 443 abertas
- DNS apontando para o servidor

**✅ Vantagens**:
- Certificado confiável
- Sem avisos no navegador
- Renovação automática
- Profissional

**Configuração de Domínio**:

1. **Registrar domínio** ou usar subdomínio
2. **Configurar DNS**:
   ```
   Tipo: A
   Nome: iluminacao
   Valor: <SEU_IP_PÚBLICO>
   TTL: 300
   ```
3. **Aguardar propagação** (até 24h)
4. **Verificar**:
   ```bash
   nslookup iluminacao.viza.com.br
   ```
5. **Executar script HTTPS**

---

## 📱 PWA - Progressive Web App

### O que foi implementado?

✅ **Manifest.json** configurado  
✅ **Service Worker** com cache inteligente  
✅ **Ícones** em múltiplos tamanhos  
✅ **Instalável** em dispositivos  
✅ **Offline First** strategy  
✅ **Meta tags** Apple e Android

---

## 🎯 Funcionalidades PWA

### 1. **Cache Inteligente**

**Arquivos estáticos** (Cache First):
- HTML, CSS, JavaScript
- Imagens e logos
- Manifest

**APIs** (Network First):
- `/api/status`
- `/api/modo`
- `/api/brilho`
- Todas as outras APIs

**Resultado**: Interface carrega instantaneamente, dados sempre frescos!

---

### 2. **Modo Offline**

**Funcionamento**:
- Interface carregada do cache
- Últimos dados conhecidos exibidos
- Tentativa automática de reconexão
- Notificação quando voltar online

**Limitações Offline**:
- ❌ Não é possível enviar comandos
- ❌ Dados não atualizam em tempo real
- ✅ Visualizar últimos dados conhecidos
- ✅ Interface 100% funcional

---

### 3. **Instalação**

#### Android (Chrome)

```
1. Acessar: https://raspberrypi.local ou https://10.0.0.1
2. Menu (⋮) → "Adicionar à tela inicial"
   ou
   Banner aparece automaticamente → "Instalar"
3. Ícone criado na tela inicial
4. App abre em tela cheia (sem navegador)
```

#### iOS (Safari)

```
1. Acessar: https://raspberrypi.local ou https://10.0.0.1
2. Botão Compartilhar (↗️)
3. "Adicionar à Tela de Início"
4. Confirmar nome
5. Ícone na tela inicial
```

#### Windows/Mac/Linux (Chrome/Edge)

```
1. Acessar site
2. Ícone de instalação aparece na barra de endereço
   ou
   Menu → "Instalar app"
3. Confirmar instalação
4. App desktop criado
```

---

## 🔄 Atualizações Automáticas

### Como funciona?

1. **Nova versão** deployada no servidor
2. **Service Worker** detecta alteração
3. **Notificação** exibida ao usuário:
   ```
   "Atualização Disponível
   Uma nova versão está disponível. Recarregue a página."
   [Recarregar]
   ```
4. **Usuário confirma** → App atualizado!

---

## 📊 Estratégias de Cache

### Cache First (Recursos Estáticos)

```
1. Busca no cache
2. Se encontrar: retorna imediatamente
3. Se não: busca na rede
4. Salva no cache para próxima vez
```

**Ideal para**: HTML, CSS, JS, imagens

---

### Network First (APIs)

```
1. Tenta buscar da rede (timeout 3s)
2. Se sucesso: retorna e atualiza cache
3. Se falha: busca do cache
4. Se não tem cache: retorna erro
```

**Ideal para**: Dados dinâmicos, APIs

---

## 🛠️ Comandos Úteis

### Verificar HTTPS

```bash
# Status do serviço
sudo systemctl status iluminacao-viza

# Logs
sudo journalctl -u iluminacao-viza -f

# Testar conexão
curl -k https://localhost

# Verificar certificado
openssl s_client -connect localhost:443 -showcerts
```

---

### Gerenciar Cache

**Limpar cache do navegador**:
```javascript
// Console do navegador
caches.keys().then(names => {
  names.forEach(name => caches.delete(name));
});
```

**Limpar via Service Worker**:
```javascript
// Console
navigator.serviceWorker.controller.postMessage({
  type: 'CLEAR_CACHE'
});
```

---

### Debug PWA

**Chrome DevTools**:
```
1. F12 → Application
2. Service Workers → Ver status
3. Cache Storage → Ver arquivos cacheados
4. Manifest → Verificar configuração
```

**Lighthouse Audit**:
```
1. F12 → Lighthouse
2. Progressive Web App
3. Generate report
4. Verificar score e recomendações
```

---

## 📱 Recursos PWA Avançados

### Já Implementado ✅

- [x] Manifest.json completo
- [x] Service Worker com cache
- [x] Instalação em dispositivos
- [x] Ícones adaptivos
- [x] Tema color
- [x] Display standalone
- [x] Offline fallback
- [x] Update notification

### Futuro 🚀

- [ ] Push Notifications
- [ ] Background Sync
- [ ] Share Target API
- [ ] File System Access
- [ ] Geolocation (se necessário)
- [ ] Camera API (para QR codes)

---

## 🔐 Segurança

### HTTPS

**Criptografia**: TLS 1.3  
**Cipher suites**: Modernos e seguros  
**Certificado**: RSA 4096-bit (auto-assinado) ou Let's Encrypt

### Service Worker

**Scope**: Limitado ao domínio  
**Origem**: Same-origin policy  
**HTTPS only**: Não funciona em HTTP

---

## 📏 Requisitos PWA

### Checklist Completo ✅

- [x] HTTPS habilitado
- [x] Manifest.json válido
- [x] Service Worker registrado
- [x] Ícones 192x192 e 512x512
- [x] Start URL configurada
- [x] Display standalone
- [x] Theme color
- [x] Background color
- [x] Nome e descrição
- [x] Responsivo (viewport)
- [x] Cache offline
- [x] Fast load time

**Score Lighthouse**: 95+ / 100 esperado

---

## 🎨 Personalização

### Cores do Tema

```json
{
  "theme_color": "#8e44ad",      // Roxo Viza
  "background_color": "#ffffff"  // Branco
}
```

### Ícones

**Gerar novos ícones**:
```bash
cd ~/sistema-iluminacao-viza/scripts
chmod +x generate_icons.sh
./generate_icons.sh
```

**Tamanhos gerados**:
- 72x72, 96x96, 128x128, 144x144
- 152x152, 192x192, 384x384, 512x512
- favicon.ico (32x32)

---

## 🐛 Troubleshooting

### PWA não instalável?

**Verificar**:
1. HTTPS habilitado? `https://` na URL
2. Manifest válido? DevTools → Application → Manifest
3. Service Worker ativo? DevTools → Application → Service Workers
4. Ícones presentes? 192x192 e 512x512
5. Start URL acessível? Testar `/`

---

### Service Worker não registra?

**Verificar console**:
```javascript
navigator.serviceWorker.getRegistrations()
  .then(registrations => console.log(registrations));
```

**Re-registrar**:
```javascript
navigator.serviceWorker.register('/service-worker.js', { scope: '/' })
  .then(reg => console.log('Registrado:', reg))
  .catch(err => console.error('Erro:', err));
```

---

### Cache desatualizado?

**Forçar atualização**:
```javascript
// Hard refresh
Ctrl + Shift + R  // ou Cmd + Shift + R

// Limpar cache
navigator.serviceWorker.getRegistration()
  .then(reg => reg.update());
```

---

## 📚 Recursos Adicionais

**Documentação Oficial**:
- [web.dev/progressive-web-apps](https://web.dev/progressive-web-apps/)
- [MDN: Service Worker API](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)
- [PWA Builder](https://www.pwabuilder.com/)

**Ferramentas**:
- Chrome DevTools
- Lighthouse
- PWA Builder
- Workbox (library Google)

---

## ✅ Status Atual

| Recurso | Status |
|---------|--------|
| **HTTPS** | ✅ Configurável (auto-assinado ou Let's Encrypt) |
| **Manifest.json** | ✅ Completo |
| **Service Worker** | ✅ Cache inteligente |
| **Instalável** | ✅ Android, iOS, Desktop |
| **Offline** | ✅ Cache First + Network First |
| **Ícones** | ✅ Múltiplos tamanhos |
| **Meta Tags** | ✅ Apple + Android |
| **Push Notifications** | 🚀 Preparado (futuro) |

---

## 🎉 Resultado Final

**Desktop/Mobile com VPN**:
```
https://10.0.0.1 (via WireGuard)
→ Certificado confiável no túnel VPN
→ Service Worker ativo
→ Cache offline
→ Instalável como app
→ Ícone na tela inicial
→ Notificações de atualização
```

**Rede Local**:
```
https://raspberrypi.local
→ Certificado auto-assinado (aceitar manualmente)
→ Todas as funcionalidades PWA
→ Cache e offline
→ Instalável
```

---

**Desenvolvido por Engemase Engenharia**  
**Para Viza Atacadista - Caçador/SC**

**Versão**: 1.0.0 com PWA e HTTPS completo
