# Changelog

## [1.0.0] - 2026-10-16

First release of Flash Sales API with its CI/CD and local infrastructure workflows.

### Added

- CI validation for linting, formatting, type checking, builds, and tests.
- Security checks for secret scanning, static analysis, and dependency vulnerabilities.
- Multi-stage Docker image, local Compose stack, vulnerability scanning, and SBOM generation.
- Docker Hub publishing workflow for main-branch and versioned release images.
- Terraform configuration for a private S3 exports bucket and customer-managed KMS key in LocalStack.
- Kubernetes manifests for the API, PostgreSQL, Redis, Prometheus, and Grafana.
- Local Minikube deployment script with context checks, secret handling, and rollout verification.

### Notes

- Terraform provisions the exports bucket, but the API does not yet store exports in S3.
- The Kubernetes and Minikube configuration is intended for local development, not production.
