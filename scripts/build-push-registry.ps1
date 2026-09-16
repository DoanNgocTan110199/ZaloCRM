# Build image app rồi push lên Docker registry nội bộ.
#
# Dùng:
#   .\scripts\build-push-registry.ps1
#   .\scripts\build-push-registry.ps1 -Tag v1.2.3
#   .\scripts\build-push-registry.ps1 -Registry 192.168.188.225:5000 -Tag latest
#
# Yêu cầu: Docker Desktop đã thêm registry vào insecure-registries
# (Settings → Docker Engine), ví dụ:
#   "insecure-registries": ["192.168.188.225:5000"]

param(
  [string]$Registry = "192.168.188.225:5000",
  [string]$Tag = "latest",
  [string]$Name = "zalo-crm-app",
  [switch]$NoCache
)

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

$Image = "${Registry}/${Name}:${Tag}"

Write-Host "▶ Registry : $Registry"
Write-Host "▶ Image    : $Image"
Write-Host ""

# Kiểm tra registry reachable
try {
  $null = Invoke-WebRequest -Uri "http://${Registry}/v2/" -UseBasicParsing -TimeoutSec 5
  Write-Host "✓ Registry reachable"
} catch {
  Write-Warning "Không ping được http://${Registry}/v2/ — kiểm tra mạng / insecure-registries."
}

$env:DOCKER_REGISTRY = $Registry
$env:IMAGE_TAG = $Tag

$buildArgs = @("compose", "build", "app")
if ($NoCache) { $buildArgs += "--no-cache" }

Write-Host "▶ Building..."
docker @buildArgs
if ($LASTEXITCODE -ne 0) { throw "docker compose build thất bại (exit $LASTEXITCODE)" }

Write-Host "▶ Pushing $Image ..."
docker compose push app
if ($LASTEXITCODE -ne 0) { throw "docker compose push thất bại (exit $LASTEXITCODE)" }

Write-Host ""
Write-Host "✓ Done: $Image"
Write-Host "  Pull trên máy khác: docker pull $Image"
