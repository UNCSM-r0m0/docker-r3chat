# ==========================================================================
# Script para iniciar Cloudflare Tunnel en Windows (fuera de Docker)
# Esto permite que el túnel vea localhost:3000 y localhost:5173
# ==========================================================================

param(
    [switch]$Stop
)

$ErrorActionPreference = "Stop"

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) { Write-Output $args }
    $host.UI.RawUI.ForegroundColor = $fc
}

if ($Stop) {
    Write-ColorOutput Red "🛑 Deteniendo cloudflared..."
    Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-ColorOutput Green "✅ cloudflared detenido"
    exit
}

# Token del túnel TEST-R3CHAT
$token = "eyJhIjoiMzRlM2EwNzY4M2Y2Njk4YzhjYTFjZWQzMDU4MjZhZGMiLCJ0IjoiZDFmMTkxYzgtNDJmNi00NTk4LWJmNTEtOTc3Yjc4YTkxODk1IiwicyI6Ill6bGlNalkwTlRJdFpEVTVOaTAwTTJZeUxXSTJNRGN0TlRreE56Rm1NelZoWmpobCJ9"

Write-ColorOutput Cyan "🚀 Iniciando Cloudflare Tunnel..."
Write-ColorOutput Yellow "   Frontend: https://testr3.r0lm0.dev → localhost:5173"
Write-ColorOutput Yellow "   Backend:  https://apitest.r0lm0.dev → localhost:3000"
Write-Output ""

# Verificar que cloudflared.exe existe
$cloudflaredPath = "$env:LOCALAPPDATA\cloudflared\cloudflared.exe"
if (-not (Test-Path $cloudflaredPath)) {
    # Buscar en PATH
    $cloudflaredPath = (Get-Command cloudflared.exe -ErrorAction SilentlyContinue)?.Source
}

if (-not $cloudflaredPath) {
    Write-ColorOutput Red "❌ cloudflared.exe no encontrado"
    Write-Output "   Descargando cloudflared..."
    
    # Crear directorio
    New-Item -ItemType Directory -Force -Path "$env:LOCALAPPDATA\cloudflared" | Out-Null
    
    # Descargar
    $url = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
    Invoke-WebRequest -Uri $url -OutFile "$env:LOCALAPPDATA\cloudflared\cloudflared.exe"
    $cloudflaredPath = "$env:LOCALAPPDATA\cloudflared\cloudflared.exe"
    Write-ColorOutput Green "✅ cloudflared descargado"
}

# Iniciar cloudflared en segundo plano
Write-ColorOutput Cyan "🌐 Iniciando túnel..."
Start-Process -FilePath $cloudflaredPath -ArgumentList "tunnel", "--no-autoupdate", "run", "--token", $token -WindowStyle Hidden

Start-Sleep -Seconds 2

# Verificar que está corriendo
$process = Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue
if ($process) {
    Write-ColorOutput Green "✅ Cloudflare Tunnel iniciado (PID: $($process.Id))"
    Write-Output ""
    Write-ColorOutput Cyan "📊 URLs disponibles:"
    Write-Output "   - https://testr3.r0lm0.dev  (Frontend)"
    Write-Output "   - https://apitest.r0lm0.dev (Backend API)"
    Write-Output ""
    Write-ColorOutput Yellow "⚠️  Para detener: .\start-cloudflared.ps1 -Stop"
} else {
    Write-ColorOutput Red "❌ Error al iniciar cloudflared"
}
