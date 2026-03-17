# R3CHAT - Docker Monorepo

Infraestructura Docker para R3Chat SaaS con microservicios NestJS y modelos cloud.

## Estructura

docker-r3chat/ ├── docker-compose.yml # Orquestación de servicios ├── .env # Variables de entorno (crear desde .env.example) ├── saas-backend/ # Submód
ulo: Backend NestJS └── ollama-proxy/ # Submódulo: Proxy para modelos cloud

## Uso

### Local (Desarrollo)

```bash
# Clonar con submódulos
git clone --recursive https://github.com/UNCSM-r0m0/docker-r3chat.git
cd docker-r3chat

# Copiar variables de entorno
cp .env.example .env
# Editar .env con tus valores

# Iniciar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f

Producción (VPS)

# En el VPS
git clone --recursive https://github.com/UNCSM-r0m0/docker-r3chat.git /opt/r3chat
cd /opt/r3chat
cp .env.example .env
# Configurar .env con valores de producción
docker-compose up -d

Servicios

 Servicio       Puerto   Descripción
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Gateway        3000     API pública
 Auth           3001     Autenticación
 Users          3002     Gestión de usuarios
 Chat           3003     Chat con IA
 Billing        3004     Pagos
 Usage          3005     Métricas
 Ollama Proxy   8080     Proxy modelos cloud
 NATS           4222     Mensajería
 Postgres       5432     Base de datos
 Redis          6379     Cache
 Cloudflared    -        Tunnel seguro

URLs

• API: https://api.r0lm0.dev
• Frontend: https://r3chat.r0lm0.dev
```
