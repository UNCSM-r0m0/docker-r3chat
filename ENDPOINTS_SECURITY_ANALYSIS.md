# 🔒 Análisis de Endpoints - Requisitos de Seguridad y E2EE

## 📋 Resumen del Stack

| Servicio | URL Local | URL Pública (Túnel) | Estado |
|----------|-----------|---------------------|--------|
| Frontend | http://localhost:5173 | https://testr3.r0lm0.dev | ✅ Running |
| Backend API | http://localhost:3000 | https://apitest.r0lm0.dev | ✅ Running |
| Cloudflare Tunnel | - | - | ✅ Connected |

---

## 🔐 Endpoints de Autenticación (Auth)

| Endpoint | Método | Auth Requerida | E2EE Recomendado | Descripción |
|----------|--------|----------------|------------------|-------------|
| `/api/auth/register` | POST | ❌ No | ⚠️ Opcional | Registro de usuarios |
| `/api/auth/login` | POST | ❌ No | ✅ Sí | Login con credenciales |
| `/api/auth/logout` | POST | ✅ Sí | ❌ No | Cerrar sesión |
| `/api/auth/refresh` | POST | ✅ Refresh Token | ❌ No | Renovar access token |
| `/api/auth/profile` | GET | ✅ Sí | ❌ No | Obtener perfil |
| `/api/auth/google` | GET | ❌ No | ⚠️ OAuth | Iniciar OAuth Google |
| `/api/auth/google/callback` | GET | ❌ No | ⚠️ OAuth | Callback Google |
| `/api/auth/github` | GET | ❌ No | ⚠️ OAuth | Iniciar OAuth GitHub |
| `/api/auth/github/callback` | GET | ❌ No | ⚠️ OAuth | Callback GitHub |
| `/api/auth/mobile/google-verify` | POST | ❌ No | ✅ Sí | Verificar token móvil |

**Notas E2EE Auth:**
- Login/Register: Aunque usan HTTPS, el password viaja en plaintext al servidor
- OAuth: Los tokens están protegidos por el flujo OAuth, pero no hay E2EE
- **Recomendación**: Considerar hash del password en cliente antes de enviar

---

## 💬 Endpoints de Chat

| Endpoint | Método | Auth Requerida | E2EE Recomendado | Descripción |
|----------|--------|----------------|------------------|-------------|
| `/api/chat` | POST | ✅ Sí | ⚠️ Análisis | Crear chat |
| `/api/chat/sessions` | GET | ✅ Sí | ❌ No | Listar chats |
| `/api/chat/sessions/:id` | GET | ✅ Sí | ⚠️ Análisis | Obtener chat |
| `/api/chat/sessions/:id` | PATCH | ✅ Sí | ❌ No | Actualizar chat |
| `/api/chat/sessions/:id` | DELETE | ✅ Sí | ❌ No | Eliminar chat |
| `/api/chat/message` | POST | ⚠️ Opcional | ✅ **CRÍTICO** | Enviar mensaje |
| `/api/chat/message/stream` | POST | ⚠️ Opcional | ✅ **CRÍTICO** | Streaming mensaje |
| `/api/chat/message/authenticated` | POST | ✅ Sí | ✅ **CRÍTICO** | Mensaje autenticado |

**Notas E2EE Chat:**
- Los mensajes de chat contienen datos sensibles del usuario
- Actualmente: El servidor puede leer TODO el contenido
- **E2EE Recomendado**: Encriptar mensajes cliente-a-cliente
- Implementación sugerida: Signal Protocol o Double Ratchet

---

## 💳 Endpoints de Stripe/Billing

| Endpoint | Método | Auth Requerida | E2EE Recomendado | Descripción |
|----------|--------|----------------|------------------|-------------|
| `/api/stripe/subscription` | GET | ✅ Sí | ❌ No | Obtener suscripción |
| `/api/stripe/create-checkout-session` | POST | ✅ Sí | ✅ Sí | Crear checkout |
| `/api/stripe/create-portal-session` | POST | ✅ Sí | ❌ No | Portal billing |
| `/api/stripe/confirm-session` | POST | ✅ Sí | ❌ No | Confirmar sesión |
| `/api/stripe/webhook` | POST | ❌ No (firma) | ✅ Sí | Webhook Stripe |

**Notas E2EE Billing:**
- Stripe maneja la encriptación de datos sensibles (tarjetas)
- Webhooks: Verificar firma de Stripe para autenticidad
- **NO implementar E2EE** para pagos - Stripe requiere acceso a los datos

---

## 👤 Endpoints de Usuarios

| Endpoint | Método | Auth Requerida | E2EE Recomendado | Descripción |
|----------|--------|----------------|------------------|-------------|
| `/api/users/profile` | PUT | ✅ Sí | ⚠️ Opcional | Actualizar perfil |

**Notas:**
- Datos de perfil (nombre, avatar) = baja sensibilidad
- **NO requiere E2EE** a menos que incluya datos médicos/PII sensible

---

## 🤖 Endpoints de Modelos AI

| Endpoint | Método | Auth Requerida | E2EE Recomendado | Descripción |
|----------|--------|----------------|------------------|-------------|
| `/api/models/public` | GET | ❌ No | ❌ No | Modelos públicos |
| `/api/models/:id` | GET | ✅ Sí | ❌ No | Detalle modelo |

---

## 📊 Endpoints de Usage/Analytics

| Endpoint | Método | Auth Requerida | E2EE Recomendado | Descripción |
|----------|--------|----------------|------------------|-------------|
| `/api/chat/usage/stats` | GET | ✅ Sí | ❌ No | Estadísticas uso |

---

## 📁 Endpoints de Upload

| Endpoint | Método | Auth Requerida | E2EE Recomendado | Descripción |
|----------|--------|----------------|------------------|-------------|
| `/api/upload/image` | POST | ✅ Sí | ⚠️ Análisis | Subir imagen |
| `/api/upload/image/:id` | GET | ⚠️ Público | ❌ No | Ver imagen |
| `/api/upload/image/:id` | DELETE | ✅ Sí | ❌ No | Eliminar imagen |
| `/api/upload/health` | GET | ❌ No | ❌ No | Health check |

**Notas E2EE Upload:**
- Imágenes subidas por usuarios pueden contener PII
- **Recomendación**: Encriptar imágenes en cliente antes de subir
- Cloudflare Images ya proporciona encriptación en tránsito y reposo

---

## 🏥 Health Checks

| Endpoint | Método | Auth Requerida | E2EE Recomendado | Descripción |
|----------|--------|----------------|------------------|-------------|
| `/health` | GET | ❌ No | ❌ No | Health check gateway |

---

## 📊 Matriz de Prioridad E2EE

### 🔴 CRÍTICO - Implementar E2EE

| Prioridad | Endpoint | Razón |
|-----------|----------|-------|
| 1 | `/api/chat/message` | Contenido conversacional privado |
| 2 | `/api/chat/message/stream` | Streaming de contenido privado |
| 3 | `/api/chat/message/authenticated` | Mensajes de usuarios autenticados |

### 🟡 OPCIONAL - Considerar E2EE

| Prioridad | Endpoint | Razón |
|-----------|----------|-------|
| 4 | `/api/auth/login` | Password en tránsito |
| 5 | `/api/upload/image` | Imágenes con PII potencial |
| 6 | `/api/chat/sessions/:id` | Historial de chats |

### 🟢 NO REQUIERE E2EE

- Health checks
- Webhooks con firma
- Datos públicos (modelos)
- Metadatos de sesión (sin contenido)

---

## 🛡️ Medidas Actuales de Seguridad

### ✅ Implementadas

1. **HTTPS/TLS**: Todo el tráfico por HTTPS (Cloudflare Tunnel)
2. **Cookies HTTP-only**: Tokens no accesibles por JavaScript
3. **Rate Limiting**: 5 req/min auth, 20 req/min AI
4. **CORS Estricto**: Solo dominios permitidos
5. **Helmet Headers**: CSP, HSTS, X-Frame-Options
6. **Redis Cache**: Para AI responses (reduce API calls)

### ⚠️ Pendientes

1. **E2EE para Chat**: Los mensajes son legibles por el servidor
2. **Hash de Passwords en Cliente**: Opcional, reduce riesgo
3. **Encriptación de Imágenes**: Opcional, para PII

---

## 🚀 Implementación E2EE Recomendada

### Para Chat (Alta Prioridad)

```
Arquitectura Propuesta:
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   Cliente A │◄───────►│   Servidor   │◄───────►│   Cliente B │
│  (Navegador)│  E2EE   │   (Relay)    │  E2EE   │  (Navegador)│
└─────────────┘         └──────────────┘         └─────────────┘
     │                         │                         │
     └────── Encriptado ───────┴────── Encriptado ───────┘
           (Signal Protocol o Double Ratchet)
```

**Librerías sugeridas:**
- JavaScript: `libsignal-client` o `@privacyresearch/libsignal-protocol-typescript`
- Backend: No necesita cambios (sigue siendo relay)

**Flujo:**
1. Cliente A genera par de claves
2. Cliente B genera par de claves
3. Intercambio de claves públicas vía servidor
4. Mensajes encriptados con clave compartida
5. Servidor solo ve ciphertext

---

## 📈 Métricas Actuales

| Servicio | Estado | Health |
|----------|--------|--------|
| Gateway | ✅ Running | Starting |
| Auth | ✅ Running | - |
| Chat | ✅ Running | - |
| Users | ✅ Running | - |
| Billing | ✅ Running | - |
| Usage | ✅ Running | - |
| NATS | ✅ Running | Healthy |
| Postgres | ✅ Running | Healthy |
| Redis | ✅ Running | Healthy |
| Ollama Proxy | ✅ Running | Healthy |
| Cloudflared | ✅ Running | Connected |

---

## 📝 Próximos Pasos

1. ✅ **Completado**: Cloudflare Tunnel funcionando
2. ✅ **Completado**: Cookies HTTP-only (sin localStorage)
3. ✅ **Completado**: Rate limiting y CORS
4. 🔄 **Pendiente**: Implementar E2EE para chat
5. 🔄 **Pendiente**: Pruebas de OAuth con dominios túnel
6. 🔄 **Pendiente**: Configurar webhooks de Stripe
