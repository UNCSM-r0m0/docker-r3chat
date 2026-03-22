# =============================================================================
# R3CHAT - Iniciar con Cloudflare Tunnel
# =============================================================================
# Este script inicia todo el stack con conexión a dominios reales:
#   - Frontend: https://testr3.r0lm0.dev
#   - Backend:  https://apitest.r0lm0.dev
# =============================================================================

param(
    [switch]$Stop,
    [switch]$Logs
)

$ErrorActionPreference = "Stop"

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) { Write-Output $args }
    $host.UI.RawUI.ForegroundColor = $fc
}

if ($Stop) {
    Write-ColorOutput Red "🛑 Deteniendo stack con túnel..."
    docker-compose down
    Write-ColorOutput Green "✅ Stack detenido"
    exit
}

if ($Logs) {
    Write-ColorOutput Cyan "📋 Mostrando logs del túnel..."
    docker-compose logs -f cloudflared
    exit
}

# Verificar si existe .env.tunnel
if (-not (Test-Path .env.tunnel)) {
    Write-ColorOutput Red "❌ Error: No se encuentra .env.tunnel"
    exit 1
}

# Copiar configuración del túnel
Write-ColorOutput Yellow "📋 Copiando configuración de túnel..."
Copy-Item .env.tunnel .env -Force

# Verificar que el token no está vacío
$envContent = Get-Content .env -Raw
if ($envContent -match "CLOUDFLARE_TUNNEL_TOKEN=your_token_here|CLOUDFLARE_TUNNEL_TOKEN=$") {
    Write-ColorOutput Red "❌ Error: El token de Cloudflare no está configurado"
    Write-ColorOutput Yellow "   Edita .env.tunnel y actualiza CLOUDFLARE_TUNNEL_TOKEN"
    exit 1
}

Write-ColorOutput Green "✅ Configuración lista"
Write-Output ""

# Iniciar stack
Write-ColorOutput Cyan "🚀 Iniciando R3CHAT con Cloudflare Tunnel..."
Write-Output ""
Write-ColorOutput Yellow "   Frontend: https://testr3.r0lm0.dev"
Write-ColorOutput Yellow "   Backend:  https://apitest.r0lm0.dev"
Write-Output ""

docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput Red "❌ Error al iniciar el stack"
    exit 1
}

Write-Output ""
Write-ColorOutput Green "✅ Stack iniciado correctamente"
Write-Output ""
Write-ColorOutput Cyan "📊 Ver estado del túnel:"
Write-Output "   docker-compose logs -f cloudflared"
Write-Output ""
Write-ColorOutput Cyan "🌐 URLs públicas:"
Write-Output "   - https://testr3.r0lm0.dev  (Frontend)"
Write-Output "   - https://apitest.r0lm0.dev (Backend API)"
Write-Output ""
