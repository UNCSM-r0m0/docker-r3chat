# R3CHAT - Docker Monorepo

Infraestructura Docker para R3Chat SaaS con microservicios NestJS y modelos cloud.

## Estructura

```
docker-r3chat/
├── docker-compose.yml           # Base: servicios esenciales
├── docker-compose.override.yml  # Override para desarrollo local
├── docker-compose.prod.yml      # Producción: agrega Cloudflare Tunnel
├── .env                         # Variables de entorno (crear desde .env.example)
├── package.json                 # Scripts npm convenientes
├── saas-backend/                # Submódulo: Backend NestJS
└── ollama-proxy/                # Submódulo: Proxy para modelos cloud
```

## Desarrollo Local (Sin Túneles)

```bash
# Clonar con submódulos
git clone --recursive https://github.com/UNCSM-r0m0/docker-r3chat.git
cd docker-r3chat

# Copiar variables de entorno
cp .env.example .env
# Editar .env (ya viene configurado para desarrollo)

# Iniciar servicios (sin túneles)
npm run start:local
# o
docker-compose up -d

# Ver logs
npm run logs
# o
docker-compose logs -f

# Ver estado
npm run ps
```

**Acceso en desarrollo:**
- API Gateway: http://localhost:3000
- Frontend (si corre local): http://localhost:5173

## Producción (Con Cloudflare Tunnel)

```bash
# Configurar .env con valores de producción:
# NODE_ENV=production
# PUBLIC_URL=https://api.yourdomain.com
# FRONTEND_URL=https://app.yourdomain.com
# TUNNEL_TOKEN=your_token_here

# Deploy
npm run start:prod
# o
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Scripts NPM Disponibles

| Comando | Descripción |
|---------|-------------|
| `npm run start:local` | Inicia servicios en desarrollo local |
| `npm run start:prod` | Inicia servicios en producción (con tunnel) |
| `npm run stop` | Detiene todos los servicios |
| `npm run logs` | Muestra logs de todos los servicios |
| `npm run logs:gateway` | Logs del gateway |
| `npm run clean` | Detiene y elimina volúmenes |
| `npm run health` | Verifica estado de los servicios |
| `npm run shell:db` | Accede a PostgreSQL |

## Servicios

| Servicio       | Puerto (Dev) | Descripción              |
|----------------|--------------|--------------------------|
| Gateway        | 3000         | API pública              |
| Auth           | 3001         | Autenticación            |
| Users          | 3002         | Gestión de usuarios      |
| Chat           | 3003         | Chat con IA              |
| Billing        | 3004         | Pagos                    |
| Usage          | 3005         | Métricas                 |
| Ollama Proxy   | 8080         | Proxy modelos cloud      |
| NATS           | 4222         | Mensajería               |
| Postgres       | 5432         | Base de datos            |
| Redis          | 6379         | Cache                    |
| Cloudflared    | -            | Tunnel seguro (solo prod)|

## Desarrollo Frontend + Backend Local

```bash
# Terminal 1: Backend
cd docker-r3chat
npm run start:local

# Terminal 2: Frontend
cd r3-chat
npm run dev

# Abrir http://localhost:5173
```

El frontend usará automáticamente `http://localhost:3000/api` como backend.
