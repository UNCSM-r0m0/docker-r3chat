# 🌐 Cloudflare Tunnel - Desarrollo con Dominios Reales

Este documento explica cómo usar Cloudflare Tunnel para exponer tu stack local de R3CHAT a Internet con dominios personalizados.

## 📋 ¿Qué es esto?

Cloudflare Tunnel crea una conexión segura desde tu máquina local hasta la red de Cloudflare, permitiendo:

- Acceder a tu app local desde URLs reales: `https://testr3.r0lm0.dev`
- Probar webhooks de Stripe, OAuth de Google/GitHub sin deploy
- Compartir tu trabajo con clientes/equipo en tiempo real
- Flujo de desarrollo idéntico al de producción

## 🚀 Inicio Rápido

### 1. Usar el script (Recomendado)

```powershell
# Iniciar todo con túnel
.\start-tunnel.ps1

# Ver logs del túnel
.\start-tunnel.ps1 -Logs

# Detener todo
.\start-tunnel.ps1 -Stop
```

### 2. O manualmente

```powershell
# Copiar configuración del túnel
cp .env.tunnel .env

# Iniciar stack
docker-compose up -d

# Ver logs del túnel
docker-compose logs -f cloudflared
```

## 🌐 URLs Disponibles

| Servicio | URL Local | URL Pública (Túnel) |
|----------|-----------|---------------------|
| Frontend | http://localhost:5173 | https://testr3.r0lm0.dev |
| Backend API | http://localhost:3000 | https://apitest.r0lm0.dev |

## 🔧 Configuración

### Variables de entorno (.env.tunnel)

El archivo `.env.tunnel` contiene toda la configuración necesaria:

```env
# Token del túnel (ya configurado)
CLOUDFLARE_TUNNEL_TOKEN=eyJh...

# URLs públicas
PUBLIC_URL=https://apitest.r0lm0.dev
FRONTEND_URL=https://testr3.r0lm0.dev

# CORS (más estricto que desarrollo local)
CORS_ALLOW_ALL=false

# OAuth callbacks apuntan al túnel
GOOGLE_CALLBACK_URL=https://apitest.r0lm0.dev/auth/google/callback
GITHUB_CALLBACK_URL=https://apitest.r0lm0.dev/auth/github/callback

# Stripe webhooks
STRIPE_SUCCESS_URL=https://testr3.r0lm0.dev/success
STRIPE_CANCEL_URL=https://testr3.r0lm0.dev/cancel
```

### Estructura del Túnel

```
Cloudflare Edge
      │
      ▼
┌─────────────────┐
│  Cloudflared    │  ← Contenedor Docker
│   (en tu PC)    │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
testr3.r0lm0.dev → localhost:5173 (Vite)
apitest.r0lm0.dev → localhost:3000 (NestJS)
```

## 🔐 Seguridad

### Rate Limiting

Ya implementado en el backend:
- Auth: 5 req/min
- AI endpoints: 20 req/min
- General: 15 req/min

### CORS

El túnel usa CORS estricto (no `*`), solo permite:
- `https://testr3.r0lm0.dev` (frontend)
- `http://localhost:5173` (desarrollo local)

### Headers de seguridad

Helmet está activo con:
- CSP configurado
- HSTS habilitado
- X-Frame-Options

## 🐛 Troubleshooting

### El túnel no conecta

```bash
# Ver logs
docker-compose logs cloudflared

# Reiniciar solo el túnel
docker-compose restart cloudflared
```

### Error "Tunnel not found"

El token puede haber expirado. Ve a Cloudflare Dashboard → Zero Trust → Networks → Tunnels → TEST-R3CHAT y copia un nuevo token.

### CORS errors en el frontend

Verifica que el backend tenga las URLs correctas:
```bash
docker-compose exec gateway env | grep FRONTEND
```

Debe mostrar:
```
FRONTEND_URL=https://testr3.r0lm0.dev
FRONTEND_URLS=https://testr3.r0lm0.dev,http://localhost:5173
```

### Puerto 3000/5173 ya en uso

```bash
# Windows: Encontrar y matar proceso
netstat -ano | findstr :3000
taskkill /PID <PID> /F
```

## 🔄 Flujo de Trabajo Recomendado

### Desarrollo Normal (sin túnel)

```powershell
# Usar el .env normal (si existe)
docker-compose up -d
```

### Desarrollo con Túnel (para pruebas reales)

```powershell
# Usar configuración de túnel
.\start-tunnel.ps1

# Trabajar normalmente, los cambios se reflejan en las URLs públicas
```

### Para Probar Webhooks (Stripe, OAuth)

1. Iniciar con túnel: `.\start-tunnel.ps1`
2. Configurar webhook en Stripe Dashboard apuntando a `https://apitest.r0lm0.dev/webhooks/stripe`
3. Probar pagos reales con tarjetas de test

## 📊 Monitoreo

### Estado del Túnel

Dashboard de Cloudflare:
https://one.dash.cloudflare.com → Networks → Tunnels → TEST-R3CHAT

### Métricas locales

```bash
# Ver conexiones activas
docker-compose logs cloudflared | grep "connection"

# Ver tráfico
docker-compose logs cloudflared | grep "request"
```

## 🧹 Limpieza

```powershell
# Detener todo
.\start-tunnel.ps1 -Stop

# O manualmente
docker-compose down

# Volver a desarrollo local
cp .env.local .env  # si tienes un .env.local
docker-compose up -d
```

---

**Nota:** El túnel solo está activo mientras ejecutes el contenedor `cloudflared`. Al detener docker-compose, el túnel se cierra automáticamente.
