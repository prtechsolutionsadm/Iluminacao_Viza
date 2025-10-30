// ============================================
// Service Worker - Sistema de Iluminação Viza
// PWA com cache inteligente e offline first
// ============================================

const CACHE_NAME = 'viza-iluminacao-v1.0.0';
const RUNTIME_CACHE = 'viza-runtime-v1.0.0';

// Arquivos essenciais para cache (offline first)
const STATIC_CACHE_URLS = [
  '/',
  '/static/manifest.json',
  '/static/images/Viza_Logo.png',
  '/static/images/Engemase_Logo.png',
  '/static/images/icon-192x192.png',
  '/static/images/icon-512x512.png'
];

// URLs de API que não devem ser cacheadas
const API_URLS = [
  '/api/status',
  '/api/modo',
  '/api/brilho',
  '/api/modo_setor',
  '/api/brilho_setor',
  '/api/setpoint_lux_geral',
  '/api/setpoint_lux_setor',
  '/api/agendar_simples',
  '/api/listar_agendamentos',
  '/api/horario_atual',
  '/api/sincronizar_rtc'
];

// ============================================
// INSTALAÇÃO - Cachear arquivos essenciais
// ============================================
self.addEventListener('install', (event) => {
  console.log('[Service Worker] Instalando...');
  
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('[Service Worker] Cache aberto, adicionando arquivos estáticos');
        return cache.addAll(STATIC_CACHE_URLS);
      })
      .then(() => {
        console.log('[Service Worker] Instalado com sucesso');
        return self.skipWaiting(); // Ativar imediatamente
      })
      .catch((error) => {
        console.error('[Service Worker] Erro na instalação:', error);
      })
  );
});

// ============================================
// ATIVAÇÃO - Limpar caches antigos
// ============================================
self.addEventListener('activate', (event) => {
  console.log('[Service Worker] Ativando...');
  
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            // Deletar caches antigos
            if (cacheName !== CACHE_NAME && cacheName !== RUNTIME_CACHE) {
              console.log('[Service Worker] Removendo cache antigo:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      })
      .then(() => {
        console.log('[Service Worker] Ativado e assumindo controle');
        return self.clients.claim(); // Assumir controle imediatamente
      })
  );
});

// ============================================
// FETCH - Estratégia de cache
// ============================================
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Ignorar requisições de outros domínios
  if (url.origin !== location.origin) {
    return;
  }
  
  // Estratégia para APIs: Network First (sempre buscar dados frescos)
  if (isApiRequest(url.pathname)) {
    event.respondWith(networkFirst(request));
    return;
  }
  
  // Estratégia para recursos estáticos: Cache First
  event.respondWith(cacheFirst(request));
});

// ============================================
// ESTRATÉGIA: Cache First
// Busca primeiro no cache, depois na rede
// ============================================
async function cacheFirst(request) {
  try {
    // Tentar buscar do cache
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      console.log('[Service Worker] Servindo do cache:', request.url);
      return cachedResponse;
    }
    
    // Se não estiver no cache, buscar da rede
    console.log('[Service Worker] Buscando da rede:', request.url);
    const networkResponse = await fetch(request);
    
    // Cachear a resposta para uso futuro
    if (networkResponse && networkResponse.status === 200) {
      const cache = await caches.open(RUNTIME_CACHE);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
    
  } catch (error) {
    console.error('[Service Worker] Erro no cacheFirst:', error);
    
    // Se offline e não tem cache, retornar página offline
    return caches.match('/offline.html') || new Response('Offline - Sem conexão com o sistema', {
      status: 503,
      statusText: 'Service Unavailable'
    });
  }
}

// ============================================
// ESTRATÉGIA: Network First
// Busca primeiro na rede, fallback para cache
// ============================================
async function networkFirst(request) {
  try {
    // Tentar buscar da rede com timeout
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 3000);
    
    const networkResponse = await fetch(request, {
      signal: controller.signal
    });
    
    clearTimeout(timeoutId);
    
    // Cachear resposta de sucesso
    if (networkResponse && networkResponse.status === 200) {
      const cache = await caches.open(RUNTIME_CACHE);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
    
  } catch (error) {
    console.warn('[Service Worker] Rede falhou, tentando cache:', error.message);
    
    // Fallback para cache
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    
    // Se não tem cache, retornar erro
    return new Response(JSON.stringify({
      error: 'Offline',
      message: 'Sem conexão com o sistema'
    }), {
      status: 503,
      statusText: 'Service Unavailable',
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// ============================================
// FUNÇÃO AUXILIAR: Verificar se é API
// ============================================
function isApiRequest(pathname) {
  return API_URLS.some(apiUrl => pathname.startsWith(apiUrl));
}

// ============================================
// MENSAGENS - Comunicação com cliente
// ============================================
self.addEventListener('message', (event) => {
  console.log('[Service Worker] Mensagem recebida:', event.data);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'CLEAR_CACHE') {
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => caches.delete(cacheName))
      );
    }).then(() => {
      console.log('[Service Worker] Cache limpo');
      event.ports[0].postMessage({ success: true });
    });
  }
  
  if (event.data && event.data.type === 'GET_VERSION') {
    event.ports[0].postMessage({ version: CACHE_NAME });
  }
});

// ============================================
// PUSH NOTIFICATIONS (futuro)
// ============================================
self.addEventListener('push', (event) => {
  console.log('[Service Worker] Push recebido:', event);
  
  const options = {
    body: event.data ? event.data.text() : 'Notificação do Sistema de Iluminação Viza',
    icon: '/static/images/icon-192x192.png',
    badge: '/static/images/icon-72x72.png',
    vibrate: [200, 100, 200],
    tag: 'viza-notification',
    requireInteraction: false
  };
  
  event.waitUntil(
    self.registration.showNotification('Sistema Viza', options)
  );
});

// ============================================
// NOTIFICATION CLICK
// ============================================
self.addEventListener('notificationclick', (event) => {
  console.log('[Service Worker] Notificação clicada');
  event.notification.close();
  
  event.waitUntil(
    clients.openWindow('/')
  );
});

// ============================================
// SYNC (sincronização em background - futuro)
// ============================================
self.addEventListener('sync', (event) => {
  console.log('[Service Worker] Sync:', event.tag);
  
  if (event.tag === 'sync-data') {
    event.waitUntil(syncData());
  }
});

async function syncData() {
  try {
    console.log('[Service Worker] Sincronizando dados...');
    // Implementar sincronização aqui no futuro
    return true;
  } catch (error) {
    console.error('[Service Worker] Erro na sincronização:', error);
    return false;
  }
}

console.log('[Service Worker] Carregado e pronto!');
