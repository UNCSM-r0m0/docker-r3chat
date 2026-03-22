# 🌐 Guía: Desarrollo Local con Cloudflare Tunnel

## Objetivo
Trabajar con dominios HTTPS locales que apuntan a tu máquina de desarrollo.

```
Frontend: https://testr3.r0lm0.dev  →  localhost:5173
API:      https://apitest.r0lm0.dev →  localhost:3000
```

---

## 🚀 Setup Inicial

### 1. Instalar cloudflared (Windows)

```powershell
# Usando scoop
scoop install cloudflared

# O descargar directamente:
# https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/
```

### 2. Autenticar con Cloudflare

```bash
cloudflared tunnel login
```

Esto abrirá el navegador. Selecciona el dominio `r0lm0.dev`.

### 3. Crear el túnel de desarrollo

```bash
# Crear túnel (solo una vez)
cloudflared tunnel create r3chat-dev

# Obtener el UUID del túnel
cloudflared tunnel list
```

### 4. Configurar el túnel

Crear archivo: `%USERPROFILE%/.cloudflared/config.yml`

```yaml
tunnel: <TU_TUNNEL_UUID>
credentials-file: %USERPROFILE%/.cloudflared/<TU_TUNNEL_UUID>.json

ingress:
  # Frontend (Vite)
  - hostname: testr3.r0lm0.dev
    service: http://localhost:5173
    originRequest:
      noTLSVerify: true
      httpHostHeader: localhost
  
  # Backend API (NestJS)
  - hostname: apitest.r0lm0.dev
    service: http://localhost:3000
    originRequest:
      noTLSVerify: true
      httpHostHeader: localhost
  
  # Fallback
  - service: http_status:404
```

### 5. Crear registros DNS

```bash
# Apuntar dominios al túnel
cloudflared tunnel route dns r3chat-dev testr3.r0lm0.dev
cloudflared tunnel route dns r3chat-dev apitest.r0lm0.dev
```

### 6. Iniciar el túnel

```bash
cloudflared tunnel run r3chat-dev
```

---

## 🔧 Configuración del Proyecto

### Variables de entorno para Desarrollo con Túnel

**Archivo:** `docker-r3chat/.env.development`

```bash
# ==========================================
# ENTORNO: Desarrollo con Túnel Cloudflare
# ==========================================
NODE_ENV=development

# URLs públicas (túnel)
PUBLIC_URL=https://apitest.r0lm0.dev
FRONTEND_URL=https://testr3.r0lm0.dev
FRONTEND_URLS=https://testr3.r0lm0.dev,http://localhost:5173

# CORS: Permitir ambos orígenes (túnel y localhost)
CORS_ALLOW_ALL=false

# Base de datos
DATABASE_URL=postgresql://postgres:local_password@localhost:5433/saas_db?schema=public

# Redis
REDIS_URL=redis://localhost:6379

# OAuth - Actualizar URLs de callback
GOOGLE_CALLBACK_URL=https://apitest.r0lm0.dev/api/auth/google/callback
GITHUB_CALLBACK_URL=https://apitest.r0lm0.dev/api/auth/github/callback

# Cookies: Secure en true porque usamos HTTPS
# En desarrollo con túnel, HTTPS está habilitado
COOKIE_SECURE=true
COOKIE_SAMESITE=none
```

**Archivo:** `r3-chat/.env.development`

```bash
# ==========================================
# FRONTEND - Desarrollo con Túnel
# ==========================================

# API Backend (túnel)
VITE_API_URL=https://apitest.r0lm0.dev/api
VITE_WS_URL=wss://apitest.r0lm0.dev
VITE_APP_URL=https://testr3.r0lm0.dev

# Google OAuth
VITE_GOOGLE_CLIENT_ID=your_google_client_id
```

---

## 📝 Script de Inicio Automatizado

Crear archivo: `docker-r3chat/start-dev-tunnel.ps1`

```powershell
#!/usr/bin/env pwsh
# Iniciar entorno de desarrollo con túnel

Write-Host "🚀 Iniciando R3Chat con Cloudflare Tunnel..." -ForegroundColor Green

# 1. Iniciar infraestructura (Docker)
Write-Host "📦 Iniciando Docker..." -ForegroundColor Cyan
docker-compose up -d postgres redis nats ollama-proxy

# 2. Esperar a que PostgreSQL esté listo
Write-Host "⏳ Esperando PostgreSQL..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 3. Iniciar túnel de Cloudflare en nueva ventana
Write-Host "🌐 Iniciando Cloudflare Tunnel..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "cloudflared tunnel run r3chat-dev" -WindowStyle Normal

# 4. Esperar a que el túnel esté listo
Write-Host "⏳ Esperando túnel..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# 5. Iniciar backend (Nueva ventana)
Write-Host "⚙️  Iniciando Backend..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "cd saas-backend; npm run start:dev" -WindowStyle Normal

# 6. Esperar backend
Start-Sleep -Seconds 5

# 7. Iniciar frontend (Nueva ventana)
Write-Host "🎨 Iniciando Frontend..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "cd ../r3-chat; npm run dev" -WindowStyle Normal

Write-Host "✅ Todo iniciado!" -ForegroundColor Green
Write-Host "   Frontend: https://testr3.r0lm0.dev" -ForegroundColor Blue
Write-Host "   API:      https://apitest.r0lm0.dev" -ForegroundColor Blue
Write-Host "   Swagger:  https://apitest.r0lm0.dev/api/docs" -ForegroundColor Blue
```

---

## 🔐 Seguridad en Desarrollo

### Con túnel HTTPS:

| Aspecto | Localhost | Con Túnel |
|---------|-----------|-----------|
| Protocolo | HTTP | HTTPS ✅ |
| Cookies Secure | false | true ✅ |
| SameSite | lax | none ✅ |
| Mixed Content | No | No |
| Service Workers | Limitado | Full ✅ |

### Headers adicionales necesarios:

```typescript
// cors.config.ts
export const corsOptions = {
  origin: [
    'https://testr3.r0lm0.dev',    // Túnel frontend
    'http://localhost:5173',        // Localhost (fallback)
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'X-Requested-With',
    'Accept',
    'Origin',
  ],
};
```

---

## 🔄 Flujo de Trabajo

### Iniciar desarrollo:
```powershell
.\start-dev-tunnel.ps1
```

### Ver logs:
```powershell
# Backend
docker-compose logs -f gateway

# Túnel
cloudflared tunnel tail r3chat-dev
```

### Detener:
```powershell
docker-compose down
# Cerrar ventanas de PowerShell del backend y frontend
```

---

## 🐛 Troubleshooting

### Error: "Cannot determine default configuration path"
**Solución:** Especificar ruta explícita:
```bash
cloudflared tunnel --config ~/.cloudflared/config.yml run r3chat-dev
```

### Error: "Bad request" en OAuth
**Solución:** Actualizar URLs de callback en Google/GitHub Console:
- `https://apitest.r0lm0.dev/api/auth/google/callback`
- `https://apitest.r0lm0.dev/api/auth/github/callback`

### Error: CORS
**Solución:** Verificar que `FRONTEND_URLS` incluya `https://testr3.r0lm0.dev`

### Error: WebSocket no conecta
**Solución:** Usar `wss://` (WebSocket Secure) en vez de `ws://`

---

## 📊 Comparación: Desarrollo vs Producción

| Característica | Desarrollo (Túnel) | Producción |
|----------------|-------------------|------------|
| Frontend URL | testr3.r0lm0.dev | r3chat.r0lm0.dev |
| API URL | apitest.r0lm0.dev | api.r0lm0.dev |
| HTTPS | ✅ Sí | ✅ Sí |
| Base de datos | Local Docker | Cloud PostgreSQL |
| OAuth App | "R3Chat Dev" | "R3Chat Prod" |
| Rate Limiting | Relajado | Estricto |
| Logging | Debug | Error/Warning |
| Stripe | Test keys | Live keys |

---

## ✅ Checklist

Antes de empezar a desarrollar:

- [ ] Instalar cloudflared
- [ ] Crear túnel `r3chat-dev`
- [ ] Configurar DNS para `testr3.r0lm0.dev`
- [ ] Configurar DNS para `apitest.r0lm0.dev`
- [ ] Actualizar OAuth callbacks en Google Console
- [ ] Actualizar OAuth callbacks en GitHub
- [ ] Crear `.env.development` con URLs del túnel
- [ ] Probar conexión HTTPS
- [ ] Verificar WebSocket funciona (wss://)
