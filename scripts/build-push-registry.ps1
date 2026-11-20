# Build app image and push to private Docker registry.
#
# Usage:
#   .\scripts\build-push-registry.ps1
#   .\scripts\build-push-registry.ps1 -Tag v1.2.3
#   .\scripts\build-push-registry.ps1 -Registry 192.168.188.225:5000 -Tag latest
#
# Requirement: Docker Desktop insecure-registries must include the registry, e.g.
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

Write-Host ">> Registry : $Registry"
Write-Host ">> Image    : $Image"
Write-Host ""

# Check registry reachable
try {
  $null = Invoke-WebRequest -Uri "http://${Registry}/v2/" -UseBasicParsing -TimeoutSec 5
  Write-Host "OK Registry reachable"
} catch {
  Write-Warning "Cannot reach http://${Registry}/v2/ - check network / insecure-registries."
}

$env:DOCKER_REGISTRY = $Registry
$env:IMAGE_TAG = $Tag

$buildArgs = @("compose", "build", "app")
if ($NoCache) { $buildArgs += "--no-cache" }

Write-Host ">> Building..."
docker @buildArgs
if ($LASTEXITCODE -ne 0) { throw "docker compose build failed (exit $LASTEXITCODE)" }

Write-Host ">> Pushing $Image ..."
docker compose push app
if ($LASTEXITCODE -ne 0) { throw "docker compose push failed (exit $LASTEXITCODE)" }

Write-Host ""
Write-Host "OK Done: $Image"
Write-Host "  Pull elsewhere: docker pull $Image"
