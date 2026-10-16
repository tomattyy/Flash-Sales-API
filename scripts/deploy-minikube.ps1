$ErrorActionPreference = "Stop"

function Invoke-NativeCommand {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Command,

    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  & $Command @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$Command failed with exit code $LASTEXITCODE."
  }
}

function Apply-PasswordSecret {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Namespace,

    [Parameter(Mandatory = $true)]
    [string]$Password
  )

  $encodedPassword = [Convert]::ToBase64String(
    [Text.Encoding]::UTF8.GetBytes($Password)
  )
  $secret = [ordered]@{
    apiVersion = "v1"
    kind       = "Secret"
    metadata   = @{
      name      = $Name
      namespace = $Namespace
    }
    type       = "Opaque"
    data       = @{
      password = $encodedPassword
    }
  } | ConvertTo-Json -Depth 5 -Compress

  $secret | & kubectl apply -f -
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to apply secret '$Name' in namespace '$Namespace'."
  }
}

if ([string]::IsNullOrWhiteSpace($env:DB_PASSWORD)) {
  throw "Set DB_PASSWORD to a development-only password before deploying."
}

if ([string]::IsNullOrWhiteSpace($env:GRAFANA_ADMIN_PASSWORD)) {
  throw "Set GRAFANA_ADMIN_PASSWORD to a development-only password before deploying."
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot

try {
  $context = & kubectl config current-context
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to determine the current Kubernetes context."
  }

  if ($context.Trim() -ne "minikube") {
    throw "Refusing to deploy to context '$context'; switch kubectl to the 'minikube' context."
  }

  $minikubeStatus = & minikube status --format "{{.Host}}"
  if ($LASTEXITCODE -ne 0 -or $minikubeStatus.Trim() -ne "Running") {
    throw "Minikube is not running. Start it with 'minikube start --driver=docker'."
  }

  Invoke-NativeCommand "docker" @("build", "--tag", "flash-sales-api:local", ".")
  Invoke-NativeCommand "minikube" @("image", "load", "flash-sales-api:local")

  Invoke-NativeCommand "kubectl" @("apply", "-f", "k8s/namespace.yaml")
  Apply-PasswordSecret "flash-sales-db" "flash-sales" $env:DB_PASSWORD
  Invoke-NativeCommand "kubectl" @("apply", "-f", "k8s/configmap.yaml")
  Invoke-NativeCommand "kubectl" @("apply", "-f", "k8s/database.yaml")
  Invoke-NativeCommand "kubectl" @("apply", "-f", "k8s/redis.yaml")
  Invoke-NativeCommand "kubectl" @("apply", "-f", "k8s/api.yaml")

  Invoke-NativeCommand "kubectl" @("rollout", "status", "deployment/postgres", "-n", "flash-sales", "--timeout=300s")
  Invoke-NativeCommand "kubectl" @("rollout", "status", "deployment/redis", "-n", "flash-sales", "--timeout=300s")
  Invoke-NativeCommand "kubectl" @("rollout", "status", "deployment/flash-sales-api", "-n", "flash-sales", "--timeout=300s")

  Invoke-NativeCommand "kubectl" @("apply", "-f", "k8s/observability/namespace.yaml")
  Apply-PasswordSecret "grafana-admin" "observability" $env:GRAFANA_ADMIN_PASSWORD
  Invoke-NativeCommand "kubectl" @("apply", "-f", "k8s/observability/")
  Invoke-NativeCommand "kubectl" @("rollout", "status", "deployment/prometheus", "-n", "observability", "--timeout=240s")
  Invoke-NativeCommand "kubectl" @("rollout", "status", "deployment/grafana", "-n", "observability", "--timeout=240s")

  Write-Output "Deployment completed. API: namespace flash-sales; Prometheus and Grafana: namespace observability."
}
finally {
  Pop-Location
}
