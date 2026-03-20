# Contexto del Proyecto R3Chat

**Fecha de actualización:** 20/03/2026  
**Autor:** Kimi Code CLI  
**Propósito:** Documentar la configuración de desarrollo local vs producción

---

## Estructura del Proyecto

```
D:\WORKSPACES\DOCKER\
├── docker-r3chat/          # Backend (Docker Compose + submodules)
│   ├── saas-backend/       # NestJS (submodule)
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
- Auth: http://127.0.0.1:3001
- Users: http://127.0.0.1:3002
- Chat: http://127.0.0.1:3003
- Billing: http://127.0.0.1:3004
- Usage: http://127.0.0.1:3005
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
Servicios: NATS, Postgres, Redis, Ollama Proxy, Auth, Users, Chat, Billing, Usage, Gateway

### docker-compose.override.yml (Desarrollo)
Overrides automáticos cuando se corre `docker-compose up`:
- Gateway en `0.0.0.0:3000`
- CORS_ALLOW_ALL=true
- Puertos expuestos para debugging

### docker-compose.prod.yml (Producción)
Agrega:
- cloudflared (Cloudflare Tunnel)

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

---

## Contacto / Repositorios

- Docker Monorepo: https://github.com/UNCSM-r0m0/docker-r3chat
- SaaS Backend: https://github.com/UNCSM-r0m0/saas-backend
- Ollama Proxy: https://github.com/UNCSM-r0m0/ollama-proxy
- Frontend: https://github.com/UNCSM-r0m0/r3-chat (asumido)

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

## Cambios Realizados (20/03/2026)

### MS-PayPal (Nuevo Microservicio)
- ✅ Creado microservicio `ms-paypal` en puerto 3006
- ✅ Contratos en `libs/contracts/paypal/` (patterns, contracts)
- ✅ Servicio completo con integración PayPal Subscriptions API
- ✅ Endpoints: crear producto, plan, suscripción, cancelar, webhook
- ✅ Variables de entorno: `PAYPAL_CLIENT_ID`, `PAYPAL_CLIENT_SECRET`, `PAYPAL_ENVIRONMENT`
- ✅ Integrado a docker-compose.yml con healthcheck

### Gateway PayPal Module
- ✅ Creado `src/paypal/paypal.module.ts` - módulo del gateway
- ✅ Creado `src/paypal/paypal.controller.ts` - endpoints REST
- ✅ Creado `src/paypal/paypal.service.ts` - comunicación NATS
- ✅ DTOs: create-product, create-plan, create-subscription
- ✅ Endpoint público `/api/paypal/config` para Client ID
- ✅ Endpoints protegidos con JWT para productos/planes/suscripciones
- ✅ Webhook endpoint para eventos de PayPal

### Google OAuth Configuración
- ✅ Creada nueva app "R3Chat Local Dev" en Google Cloud Console
- ✅ Configurados orígenes: `http://localhost:5173`, `http://localhost:3000`
- ✅ Callback URL: `http://localhost:3000/api/auth/google/callback`
- ✅ Actualizado `.env` con nuevas credenciales
- ✅ Fix en auth.controller.ts para cookies en localhost (sin dominio)

### Base de Datos
- ✅ Ejecutadas migraciones de Prisma con `prisma migrate deploy`
- ✅ Creadas tablas: users, auth, chat, billing, usage con schemas separados
- ✅ Verificada conexión PostgreSQL en puerto 5433

### Frontend
- ✅ Agregado `VITE_GOOGLE_CLIENT_ID` a `.env.development`

### Estructura de Ramas
- ✅ `feature/ms-paypal-integration` en todos los repos (sin afectar main/producción)

---

## Endpoints PayPal Disponibles

```
GET    /api/paypal/config                    # Público - Client ID
POST   /api/paypal/products                  # Auth - Crear producto
POST   /api/paypal/plans                     # Auth - Crear plan
POST   /api/paypal/subscriptions             # Auth - Crear suscripción
GET    /api/paypal/subscriptions/:id         # Auth - Ver suscripción
POST   /api/paypal/subscriptions/:id/cancel  # Auth - Cancelar
POST   /api/paypal/webhook                   # Webhook de PayPal
```

---

## Configuración Actual (Local)

### Variables .env (docker-r3chat)
```bash
# PayPal (Sandbox)
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_CLIENT_SECRET=your_paypal_client_secret
PAYPAL_ENVIRONMENT=sandbox
PAYPAL_WEBHOOK_ID=                    # Pendiente configurar con ngrok

# Google OAuth (R3Chat Local Dev)
GOOGLE_CLIENT_ID=your_google_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_google_client_secret
GOOGLE_CALLBACK_URL=http://localhost:3000/api/auth/google/callback
```

### Variables .env.development (r3-chat)
```bash
VITE_GOOGLE_CLIENT_ID=your_google_client_id.apps.googleusercontent.com
```

---

## Próximos Pasos (Pendientes)

1. **PayPal Webhook:** Configurar con ngrok para recibir eventos de pago
2. **Google OAuth:** Verificar que el login funcione correctamente (cookies)
3. **Frontend PayPal:** Integrar PayPal SDK para botón de suscripción
4. **Producción:** Crear apps separadas en PayPal y Google para producción

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
curl http://localhost:3006/health
curl http://localhost:3000/api/paypal/config
```

