# Postmortem: modelos no cargaban en VPS Ubuntu

## Incidente

Despues de desplegar cambios en la VPS Ubuntu el 17 de marzo de 2026, el endpoint `GET /api/models/public` empezo a devolver `{"models":[]}` aunque los contenedores estaban corriendo y los health checks aparecian en verde.

## Impacto

- La app no mostraba modelos disponibles.
- El flujo de chat quedaba bloqueado o degradado.
- El estado de salud del stack daba una falsa sensacion de normalidad.

## Sintoma visible

- `curl http://localhost:3000/api/models/public` devolvia lista vacia.
- `ollama-proxy` respondia `500` en `/v1/models`.

## Causa raiz

La causa real fue conectividad rota entre el contenedor `saas-ollama-proxy` y el servicio Ollama que corria en el host Ubuntu.

El proxy estaba intentando llegar a Ollama usando una IP bridge de Docker (`172.18.0.1:11434`), pero esa ruta no era confiable y ademas el host tenia `ufw` con politica `deny (routed)`, lo que bloqueaba trafico desde la red Docker hacia el puerto `11434`.

## Factores contribuyentes

- `ollama-proxy` necesitaba exponer `/v1/models` por compatibilidad OpenAI.
- El health check del proxy solo validaba que Express estuviera vivo, no que el upstream Ollama respondiera.
- Usar IPs bridge (`172.17.0.1`, `172.18.0.1`) hizo la configuracion fragil ante recreacion de redes Docker.
- Hubo ruido de diagnostico porque `gateway -> ollama-proxy` si funcionaba, pero `ollama-proxy -> Ollama host` no.

## Que validamos

- Ollama en el host si respondia en `http://localhost:11434/api/tags`.
- El modelo real existia y coincidia con `PUBLIC_MODELS`.
- El backend Nest si estaba consumiendo `/v1/models`.
- Los logs de `ollama-proxy` mostraban `ConnectTimeoutError` hacia `172.18.0.1:11434`.
- Los logs del `gateway` mostraban error al listar modelos por falla del proxy.

## Solucion aplicada

1. Se mantuvo el endpoint `/v1/models` en `ollama-proxy` para compatibilidad con el backend.
2. Se cambio la configuracion de `docker-compose.yml` para que `ollama-proxy` use:
   - `OLLAMA_TARGET=http://host.docker.internal:11434`
   - `extra_hosts: ["host.docker.internal:host-gateway"]`
3. Se recreo `saas-ollama-proxy`.
4. Se valido conectividad desde el contenedor hacia:
   - `http://host.docker.internal:11434/api/tags`
   - `http://localhost:8080/v1/models`
5. Se valido el endpoint final:
   - `curl http://localhost:3000/api/models/public`

## Resultado

El endpoint volvio a responder correctamente:

```json
{
  "models": [
    {
      "id": "ollama-kimi-k2:1t-cloud",
      "defaultModel": "kimi-k2:1t-cloud"
    }
  ]
}
```

## Lecciones aprendidas

- Un contenedor "healthy" no garantiza que su dependencia upstream este sana.
- En Linux, `host.docker.internal` con `host-gateway` es mas estable que depender de IPs bridge.
- Los logs del proxy eran la fuente mas util; sin ellos el problema parecia estar en backend o base de datos.
- Cuando el sintoma es "lista vacia", conviene validar la cadena completa: `gateway -> proxy -> upstream`.

## Acciones preventivas

- Cambiar el health check de `ollama-proxy` para validar el upstream real.
- Evitar hardcodear IPs bridge Docker en produccion.
- Documentar el acceso host-container para servicios locales como Ollama.
- Rotar los secretos expuestos durante la sesion de soporte.
- Agregar un smoke test de `GET /api/models/public` en despliegue.
