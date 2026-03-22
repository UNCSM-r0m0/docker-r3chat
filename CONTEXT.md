# Contexto del Proyecto R3Chat

**Fecha de actualización:** 22/03/2026  
**Autor:** Kimi Code CLI  
**Propósito:** Documentar la configuración de desarrollo local vs producción

---

## Estado Actual (22/03/2026)

### ✅ Funcionando
- **Cloudflare Tunnel:** Configurado y operativo
- **Google OAuth:** Login funcional (secret corregido)
- **Modelos Ollama:** Configurados y visibles para usuarios logueados
- **WebSocket:** Conexiones activas
- **E2EE:** Implementación lista (ECDH + AES-GCM)

### URLs de Trabajo
| Servicio | URL |
|----------|-----|
| Frontend | https://testr3.r0lm0.dev |
| Backend API | https://apitest.r0lm0.dev/api |
| WebSocket | wss://apitest.r0lm0.dev/chat |

---

## Configuración de Modelos Ollama

**Archivo:** `.env` (docker-r3chat)

```bash
# Modelos disponibles en Ollama Cloud
PUBLIC_MODELS=kimi-k2:1t-cloud
PRO_MODELS=kimi-k2.5:cloud,kimi-k2-thinking,deepseek-v3.1:671b-cloud,minimax-m2:cloud,glm-5:cloud,qwen3-coder-next:cloud

# Conexión
OLLAMA_URL=http://host.docker.internal:11434
```

**Nota:** El endpoint `/api/models/available` ahora requiere autenticación JWT (cambio de seguridad).

---

## Estructura del Proyecto

```
D:\WORKSPACES\DOCKER\
├── docker-r3chat/          # Backend (Docker Compose + submodules)
│   ├── saas-backend/       # NestJS (submodule)
│   │   ├── apps/           # Microservicios (ms-*)
│   │   │   ├── ms-auth/    # Auth microservice (port 3001)
│   │   │   ├── ms-users/   # Users microservice (port 3002)
│   │   │   ├── ms-chat/    # Chat microservice (port 3003)
│   │   │   ├── ms-billing/ # Billing microservice (port 3004)
│   │   │   └── ms-usage/   # Usage microservice (port 3005)
│   │   ├── src/            # Gateway API (port 3000)
│   │   │   ├── auth/       # Gateway Auth (HTTP/WS)
│   │   │   ├── chat/       # Gateway Chat (WebSocket)
│   │   │   ├── integrations/
│   │   │   │   └── ai/     # AI Providers (deepseek, gemini, ollama, openai)
│   │   │   └── ...
│   │   └── STRUCTURE.md    # Documentación de estructura
│   ├── ollama-proxy/       # Proxy modelos (submodule)
│   ├── docker-compose.yml
│   ├── docker-compose.override.yml   # Desarrollo local
│   ├── docker-compose.prod.yml       # Producción
│   └── package.json
│
└── r3-chat/                # Frontend (React + Vite)
    ├── src/
    ├── .env.development
    ├── .env.production
    └── package.json
```

---

## Configuración de Desarrollo Local

### Backend (docker-r3chat)

**Comandos:**
```bash
cd docker-r3chat
npm run start:local      # docker-compose up -d
npm run stop             # docker-compose down
npm run logs             # docker-compose logs -f
npm run clean            # docker-compose down -v
```

**URLs en desarrollo:**
- Gateway: http://localhost:3000
- MS-Auth: http://127.0.0.1:3001
- MS-Users: http://127.0.0.1:3002
- MS-Chat: http://127.0.0.1:3003
- MS-Billing: http://127.0.0.1:3004
- MS-Usage: http://127.0.0.1:3005
- Postgres: localhost:5432
- Redis: localhost:6379
- NATS: localhost:4222

**Variables de entorno (.env):**
```bash
NODE_ENV=development
PORT=3000
PUBLIC_URL=http://localhost:3000
FRONTEND_URL=http://localhost:5173
FRONTEND_URLS=http://localhost:5173,http://127.0.0.1:5173
CORS_ALLOW_ALL=true
TUNNEL_TOKEN=           # Vacío en desarrollo
```

### Frontend (r3-chat)

**Comandos:**
```bash
cd r3-chat
npm run dev              # Vite modo development
npm run dev:prod         # Vite modo production
npm run build            # Build desarrollo
npm run build:prod       # Build producción
```

**Variables de entorno:**
```bash
# .env.development (local)
VITE_API_URL=http://localhost:3000/api
VITE_WS_URL=ws://localhost:3000
VITE_APP_URL=http://localhost:5173

# .env.production (deploy)
VITE_API_URL=https://api.r0lm0.dev/api
VITE_WS_URL=wss://api.r0lm0.dev
VITE_APP_URL=https://r3chat.r0lm0.dev
```

**URLs en desarrollo:**
- Frontend: http://localhost:5173
- API Backend: http://localhost:3000/api
- WebSocket: ws://localhost:3000

---

## Configuración de Producción

### Backend

```bash
cd docker-r3chat
npm run start:prod       # docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

**Variables de entorno (.env):**
```bash
NODE_ENV=production
PORT=3000
PUBLIC_URL=https://api.r0lm0.dev
FRONTEND_URL=https://r3chat.r0lm0.dev
FRONTEND_URLS=https://r3chat.r0lm0.dev
CORS_ALLOW_ALL=false
TUNNEL_TOKEN=your_cloudflare_token_here
```

### Frontend

```bash
cd r3-chat
npm run build:prod       # Build con .env.production
```

---

## Módulo de Upload (Cloudflare Images)

**Ubicación:** `docker-r3chat/saas-backend/src/upload/`

**Endpoints:**
```
POST   /upload/image      # Subir imagen (requiere auth)
GET    /upload/image/:id  # Obtener URLs de variantes
DELETE /upload/image/:id  # Eliminar imagen (requiere auth)
GET    /upload/health     # Verificar configuración
```

**Variables de entorno:**
```bash
CF_ACCOUNT_ID=your_account_id
CF_API_TOKEN=your_api_token
CF_IMAGES_ACCOUNT_HASH=your_hash
```

**Formato URLs Cloudflare Images:**
```
https://imagedelivery.net/<ACCOUNT_HASH>/<IMAGE_ID>/<VARIANT>

Variants:
- public     : Original
- thumbnail  : 200x200
- medium     : 800x600
- large      : 1920x1080
```

**Si no está configurado Cloudflare**, el servicio funciona en modo "mock" (devuelve base64 del archivo).

---

## Archivos Docker Compose

### docker-compose.yml (Base)
Servicios: NATS, Postgres, Redis, Ollama Proxy, MS-Auth, MS-Users, MS-Chat, MS-Billing, MS-Usage, Gateway

### docker-compose.override.yml (Desarrollo)
Overrides automáticos cuando se corre `docker-compose up`:
- Gateway en `0.0.0.0:3000`
- CORS_ALLOW_ALL=true
- Puertos expuestos para debugging
- **Cloudflared** (opcional) para túnel HTTPS

### docker-compose.prod.yml (Producción)
Agrega:
- Configuraciones específicas de producción (escalado, recursos)

---

## Flujo de Trabajo Recomendado

### Desarrollo Local (Sin túneles)

```bash
# Terminal 1 - Backend
cd docker-r3chat
npm run start:local

# Terminal 2 - Frontend
cd r3-chat
npm run dev

# Acceso: http://localhost:5173
# No requiere internet para túneles
```

### Producción

```bash
# 1. Configurar .env con TUNNEL_TOKEN
# 2. Deploy backend
cd docker-r3chat
npm run start:prod

# 3. Build y deploy frontend
cd r3-chat
npm run build:prod
# Subir dist/ a Vercel
```

---

## Decisiones Técnicas

| Aspecto | Decisión | Razón |
|---------|----------|-------|
| Variables entorno | Archivos separados (.env.development/.env.production) | Más simple que ramas Git |
| Docker Compose | Override files | docker-compose up usa automáticamente override |
| CORS dev | CORS_ALLOW_ALL=true | Facilita desarrollo local |
| Cloudflare Images | API directa | Mejor que R2 para transformaciones on-the-fly |
| Puerto Gateway | 3000 para ambos ambientes | Consistencia |
| **Autenticación** | **Cookies HTTP-only** | **NO se usa localStorage para tokens** |
| **Cloudflare Tunnel** | **En docker-compose.override.yml** | **HTTPS en desarrollo con dominios reales** |
| **E2EE** | **Web Crypto API (ECDH+AES-GCM)** | **Preparado para chat usuario-usuario** |

---

## Notas Importantes

1. **Frontend usa variables Vite**: Todas empiezan con `VITE_` para ser expuestas al cliente

2. **Backend validación**: Joi schema en app.module.ts valida todas las variables

3. **Submódulos**: 
   - `saas-backend` → https://github.com/UNCSM-r0m0/saas-backend.git
   - `ollama-proxy` → https://github.com/UNCSM-r0m0/ollama-proxy.git

4. **Upload sin config**: Si CF_* variables están vacías, el servicio usa modo mock

5. **Health checks**: Cada servicio tiene healthcheck configurado en docker-compose

---

## Troubleshooting

### Error CORS
Verificar `CORS_ALLOW_ALL=true` en desarrollo

### Frontend no conecta
Verificar que:
1. Docker está corriendo: `docker-compose ps`
2. VITE_API_URL apunta al puerto correcto
3. Gateway healthcheck pasa: `curl http://localhost:3000/health`

### Variables no cargan
Frontend: Recargar Vite (detener y `npm run dev`)
Backend: Reconstruir contenedores: `docker-compose up -d --build`

### Google OAuth Error 401: invalid_client
Verificar que `GOOGLE_CLIENT_SECRET` coincida exactamente con el JSON de credenciales de Google Cloud Console.

---

## Contacto / Repositorios

- Docker Monorepo: https://github.com/UNCSM-r0m0/docker-r3chat
- SaaS Backend: https://github.com/UNCSM-r0m0/saas-backend
- Ollama Proxy: https://github.com/UNCSM-r0m0/ollama-proxy
- Frontend: https://github.com/UNCSM-r0m0/r3-chat (asumido)

---

## 🔐 Autenticación (IMPORTANTE)

### NO SE USA localStorage PARA TOKENS

**Cambio crítico realizado el 22/03/2026:**
- ❌ Eliminado todo uso de `localStorage.getItem('access_token')`
- ❌ Eliminado `localStorage.setItem('access_token', token)`
- ✅ **Solo cookies HTTP-only** manejadas por el servidor
- ✅ OAuth callback ya no guarda token en URL (cuando usa HTTPS)

**Ventajas:**
- Tokens no accesibles por JavaScript (protección XSS)
- Funciona con dominios personalizados (Cloudflare Tunnel)
- Flujo idéntico a producción

**Archivos modificados:**
- `r3-chat/src/services/api.ts` - Removido header Authorization manual
- `r3-chat/src/stores/auth.store.ts` - Sin localStorage
- `r3-chat/src/components/auth/OAuthCallback.tsx` - Sin guardar token

---

## 🌐 Cloudflare Tunnel (Desarrollo con HTTPS)

**Nuevo desde 22/03/2026:**

El túnel de Cloudflare ahora está integrado en Docker Compose para desarrollo.

### URLs Públicas (Desarrollo)
- **Frontend:** https://testr3.r0lm0.dev
- **Backend:** https://apitest.r0lm0.dev

### Uso
```bash
cd docker-r3chat

# Copiar config de túnel
cp .env.tunnel .env

# Iniciar todo (incluye cloudflared)
.\start-tunnel.ps1

# O manualmente
docker-compose up -d
```

### Beneficios
- HTTPS real en desarrollo local
- Webhooks de Stripe funcionan sin ngrok
- OAuth callbacks funcionan correctamente
- Cookies cross-origin funcionan (sameSite=None + secure)

---

## 🔒 E2EE (End-to-End Encryption)

**Implementado el 22/03/2026:**

Infraestructura lista para encriptación end-to-end en chats usuario-usuario.

### Algoritmos
- **Intercambio de claves:** ECDH (P-256)
- **Encriptación:** AES-GCM (256-bit)
- **IV:** 96-bit aleatorio por mensaje

### Archivos
- `r3-chat/src/services/crypto.service.ts` - Web Crypto API
- `r3-chat/src/hooks/useE2EE.ts` - Hook React
- `docker-r3chat/saas-backend/src/users/users.controller.ts` - Endpoints claves

### Estado
- ✅ Generación de pares de claves
- ✅ Derivación de claves compartidas
- ✅ Encriptar/desencriptar mensajes
- 🔄 Pendiente: UI indicador de E2EE
- 🔄 Pendiente: Tabla de mensajes encriptados en DB

---

## 🧹 Limpieza de Código Muerto (22/03/2026)

### Backend Eliminado
- `src/app.controller.spec.ts` - Test unitario no usado
- `test/app.e2e-spec.ts` - Test e2e obsoleto
- `test/jest-e2e.json` - Config sin uso

### Frontend Eliminado
- `src/helpers/format.ts` - 7 funciones no usadas
- `src/helpers/validation.ts` - 6 funciones no usadas  
- `src/components/legal/index.ts` - Barrel export no usado

### Frontend Actualizado
- `src/stores/index.ts` - Agregados exports faltantes

---

## 🔒 Seguridad: Endpoint de Modelos Privado (22/03/2026)

**Cambio de seguridad importante:**

| Antes | Después |
|-------|---------|
| `GET /api/models/public` | `GET /api/models/available` |
| Público (sin auth) | Requiere JWT |

**Motivo:** Los modelos Ollama son recursos valiosos. Evitar que no autenticados puedan ver/quemar tokens.

**Commits:**
- Backend: `af74c4c` - feat: add cache service, throttler, and security improvements
- Frontend: `e87cd45` - config: update vite config and env for cloudflare tunnel deployment

---

## Cambios Realizados (17/03/2026)

### Frontend
- ✅ Creado `.env.development`
- ✅ Creado `.env.production`
- ✅ Creado `.env.example`
- ✅ Modificado `src/constants/index.ts` para usar `import.meta.env`
- ✅ Actualizado `package.json` con scripts
- ✅ Actualizado `.gitignore`
- ✅ Creado `README.md`

### Backend
- ✅ Creado `docker-compose.override.yml`
- ✅ Creado `docker-compose.prod.yml`
- ✅ Modificado `docker-compose.yml` (removido cloudflared)
- ✅ Actualizado `.env.example`
- ✅ Creado `package.json` con scripts
- ✅ Actualizado `README.md`

### Módulo Upload
- ✅ Creado `upload.module.ts`
- ✅ Creado `upload.service.ts`
- ✅ Creado `upload.controller.ts`
- ✅ Creado `dto/upload-image.dto.ts`
- ✅ Actualizado `app.module.ts` para importar UploadModule
- ✅ Agregadas variables CF_* a Joi validation


---



## 🔐 Autenticación: Desarrollo vs Producción

### Desarrollo Local (localhost)

**Problema:** Las cookies HTTP-only no funcionan entre diferentes puertos (localhost:3000 vs localhost:5173).

**Solución implementada:**
| Componente | Implementación |
|------------|----------------|
| **Backend** | OAuth callback envía token en URL: `?token=xxx` |
| **Frontend** | Captura token de URL y lo guarda en `localStorage` |
| **API** | Interceptor Axios lee token de `localStorage` y lo envía en header `Authorization: Bearer <token>` |

**Archivos modificados:**
- `saas-backend/src/auth/auth.controller.ts` - Callback envía token en URL para localhost
- `r3-chat/src/components/auth/OAuthCallback.tsx` - Guarda token en localStorage
- `r3-chat/src/stores/auth.store.ts` - Persiste token en localStorage
- `r3-chat/src/services/api.ts` - Interceptor agrega header Authorization
- `r3-chat/vite.config.ts` - Proxy para unificar origen (localhost:5173/api → localhost:3000)

> ⚠️ **Nota de seguridad:** Este método es **SOLO para desarrollo local**. No usar en producción.

### Producción

**Implementación segura:**
| Componente | Implementación |
|------------|----------------|
| **Backend** | Cookies HTTP-only con `secure: true` y `sameSite: 'none'` |
| **Frontend** | No maneja tokens directamente |
| **API** | Cookies se envían automáticamente con `withCredentials: true` |

**Ventajas de cookies HTTP-only:**
- ✅ Token no expuesto en URL
- ✅ No accesible por JavaScript (protección XSS)
- ✅ Navegador las envía automáticamente
- ✅ Más seguro contra ataques de robo de tokens

**Variables de entorno en producción:**
```bash
# Backend
NODE_ENV=production
FRONTEND_URL=https://r3chat.r0lm0.dev

# Frontend (.env.production)
VITE_API_URL=https://api.r0lm0.dev/api
```

### Migración Desarrollo → Producción

Para deploy a producción:

1. **Backend:**
   - Cambiar `NODE_ENV=production`
   - Usar `sameSite: 'none'` y `secure: true` en cookies
   - No enviar token en URL

2. **Frontend:**
   - Usar `.env.production` (cookies HTTP-only)
   - Remover lógica de localStorage para tokens
   - Axios seguirá usando `withCredentials: true`

3. **Configuración actual detecta automáticamente:**
   ```typescript
   // auth.controller.ts
   const isLocalhost = frontendUrl.includes('localhost') || frontendUrl.includes('127.0.0.1');
   if (isLocalhost) {
     return res.redirect(`${frontendUrl}/auth/callback?token=${access_token}`);
   }
   // Producción: solo redirige sin token en URL
   ```

---

## Comandos Útiles

```bash
# Backend
cd docker-r3chat
npm run start:local           # Levantar todo
npm run logs                  # Ver logs
docker-compose logs gateway   # Logs específicos

# Frontend
cd r3-chat
npm run dev                   # Iniciar Vite

# Migraciones
cd docker-r3chat/saas-backend
docker-compose exec gateway npx prisma migrate deploy

# Verificar servicios
curl http://localhost:3000/health
curl http://localhost:3001/health  # ms-auth
curl http://localhost:3003/health  # ms-chat
```

---

## Cambios Realizados (21/03/2026) - Reorganización

### Eliminación de PayPal
- ❌ Eliminado microservicio `ms-paypal` (puerto 3006)
- ❌ Eliminados contratos en `libs/contracts/paypal/`
- ❌ Eliminado gateway module `src/paypal/`
- ❌ Actualizado `docker-compose.yml` (quitado servicio paypal)
- ❌ Actualizado `docker-compose.override.yml`
- ❌ Actualizado `package.json` (scripts de paypal)
- ❌ Eliminadas variables PAYPAL_* de configuración

**Nota:** Stripe permanece como único proveedor de pagos.

### Reorganización de Estructura

#### Microservicios (`apps/`)
Renombrados con prefijo `ms-` para claridad:
- `apps/auth/` → `apps/ms-auth/`
- `apps/users/` → `apps/ms-users/`
- `apps/chat/` → `apps/ms-chat/`
- `apps/billing/` → `apps/ms-billing/`
- `apps/usage/` → `apps/ms-usage/`

#### Integraciones AI (`src/integrations/ai/`)
Movidos de `src/` a `src/integrations/ai/`:
- `src/deepseek/` → `src/integrations/ai/deepseek/`
- `src/gemini/` → `src/integrations/ai/gemini/`
- `src/ollama/` → `src/integrations/ai/ollama/`
- `src/openai/` → `src/integrations/ai/openai/`

#### Archivos Actualizados
- ✅ `nest-cli.json` - rutas de proyectos actualizadas
- ✅ `package.json` - scripts actualizados
- ✅ `docker-compose.yml` - comandos actualizados
- ✅ `app.module.ts` - imports actualizados
- ✅ `chat/chat.module.ts` - imports actualizados
- ✅ `chat/chat.controller.ts` - imports actualizados
- ✅ `models/models.module.ts` - imports actualizados
- ✅ `models/models.controller.ts` - imports actualizados

### Convenciones de Nombres

| Prefijo | Ubicación | Propósito | Puerto |
|---------|-----------|-----------|--------|
| `ms-*` | `apps/` | Microservicios (NATS) | 3001-3005 |
| - | `src/` | Gateway API (HTTP/WS) | 3000 |
| `integrations/*` | `src/integrations/` | APIs externas | - |

Ver documentación completa en: `saas-backend/STRUCTURE.md`
