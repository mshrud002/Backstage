# Backstage

Deploy [Backstage](https://backstage.io) to any Kubernetes environment.

## Project Structure

```
├── Dockerfile                    # Multi-stage container build
├── app-config.yaml               # Backstage configuration
├── app-config.production.yaml    # Production config overrides
├── catalog-info.yaml             # Backstage entity catalog
├── helm/backstage/               # Helm chart for K8s deployment
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── ci/ci-values.yaml
│   └── templates/
│       ├── _helpers.tpl
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       ├── configmap.yaml
│       ├── serviceaccount.yaml
│       ├── hpa.yaml
│       ├── auth-secret.yaml
│       └── tests/test-connection.yaml
├── terraform/                    # Terraform module
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── examples/basic/
│       ├── main.tf
│       └── terraform.tfvars.example
├── kubernetes/                   # Raw K8s manifests + Kustomize
│   ├── kustomization.yaml
│   ├── backstage-namespace.yaml
│   ├── backstage-serviceaccount.yaml
│   ├── backstage-configmap.yaml
│   ├── backstage-deployment.yaml
│   ├── backstage-service.yaml
│   └── backstage-ingress.yaml
├── scripts/build-and-push.sh     # Build helper script
└── .github/workflows/deploy.yaml # CI/CD pipeline
```

## Prerequisites

- Kubernetes cluster (any provider)
- kubectl configured
- Helm 3+ (for Helm deployment)
- Terraform 1.3+ (for Terraform deployment)

## Quick Start

### Option 1: Helm (recommended)

```bash
# Add Bitnami repo for PostgreSQL dependency
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install Backstage
helm upgrade --install backstage ./helm/backstage \
  --namespace backstage --create-namespace \
  --set backstage.appConfig.baseUrl=https://backstage.example.com \
  --set image.repository=ghcr.io/your-org/backstage \
  --set image.tag=latest
```

### Option 2: Terraform

```bash
cd terraform/examples/basic
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
terraform init
terraform plan
terraform apply
```

### Option 3: kubectl + Kustomize

```bash
kubectl apply -k kubernetes/
```

## Building the Container Image

```bash
REGISTRY=ghcr.io OWNER=my-org ./scripts/build-and-push.sh
```

Or manually:

```bash
docker build -t ghcr.io/my-org/backstage:latest .
docker push ghcr.io/my-org/backstage:latest
```

## Configuration

| Parameter | Description | Required |
|-----------|-------------|----------|
| `backstage.appConfig.baseUrl` | Public URL of Backstage instance | yes |
| `image.repository` | Container image repository | yes |
| `backstage.auth.github.clientId` | GitHub OAuth client ID | for auth |
| `backstage.auth.github.clientSecret` | GitHub OAuth client secret | for auth |
| `postgresql.enabled` | Deploy PostgreSQL as dependency | optional |
| `ingress.enabled` | Create Kubernetes Ingress | optional |

## CI/CD

The GitHub Actions workflow in `.github/workflows/deploy.yaml`:
1. Installs dependencies and type-checks
2. Builds the backend
3. Builds and pushes the Docker image to GHCR
4. Deploys to Kubernetes via Helm

Secrets required:
- `KUBECONFIG_PRODUCTION` - kubeconfig for the target cluster
- `APP_BASE_URL` - public URL for Backstage
- `AUTH_GITHUB_CLIENT_ID` / `AUTH_GITHUB_CLIENT_SECRET` - GitHub OAuth credentials
- `POSTGRES_PASSWORD` - database password
