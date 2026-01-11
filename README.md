# GitOps MCP - Kubernetes Deployments

> **Note**: This project was built with [Cursor](https://cursor.sh) and the Composer model, demonstrating AI-assisted development for Kubernetes infrastructure as code.

This repository contains Kubernetes deployment manifests for HTTP MCP servers in a dedicated `mcp-servers` namespace.

## Repository Structure

```
gitops-mcp/
├── namespace.yaml                    # MCP servers namespace
├── kustomization.yaml                # Kustomize configuration
├── README.md                          # This file
├── .cursorrules                      # Cursor IDE instructions
├── .gitignore                         # Git ignore rules
├── docs/                              # Documentation
│   ├── MCP_SERVERS_REVIEW.md         # Server review and details
│   └── STRUCTURE.md                   # Repository structure guide
└── mcp-servers/                      # MCP server deployments
    ├── proxmox-ve-mcp/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── configmap.yaml
    │   └── secret.yaml.example
    ├── unifi-network-mcp/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── configmap.yaml
    │   └── secret.yaml.example
    ├── unifi-protect-mcp/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── configmap.yaml
    │   └── secret.yaml.example
    ├── unifi-manager-mcp/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── configmap.yaml
    │   └── secret.yaml.example
    └── high-command-mcp/
        ├── deployment.yaml
        ├── service.yaml
        ├── configmap.yaml
        └── secret.yaml.example
```

## MCP Servers

The following HTTP MCP servers are configured:

1. **proxmox-ve-mcp** - Proxmox VE management MCP server
2. **unifi-network-mcp** - UniFi Network management MCP server
3. **unifi-protect-mcp** - UniFi Protect management MCP server
4. **unifi-manager-mcp** - UniFi Manager MCP server
5. **high-command-mcp** - High Command MCP server

For detailed information about each server, see [docs/MCP_SERVERS_REVIEW.md](docs/MCP_SERVERS_REVIEW.md).

## Prerequisites

1. Kubernetes cluster access
2. `kubectl` configured
3. Container images available at Harbor registry:
   - `harbor.dataknife.net/library/proxmox-ve-mcp:latest`
   - `harbor.dataknife.net/library/unifi-network-mcp:latest`
   - `harbor.dataknife.net/library/unifi-protect-mcp:latest`
   - `harbor.dataknife.net/library/unifi-manager-mcp:latest`
   - `harbor.dataknife.net/library/high-command-mcp:latest`
4. Harbor registry credentials with pull access

## Quick Start

### Using Kustomize (Recommended)

1. **Create Harbor Registry Secret** (required for pulling images):
   ```bash
   # Create the Harbor registry secret in the mcp-servers namespace
   kubectl create secret docker-registry harbor-registry-secret \
     --docker-server=harbor.dataknife.net \
     --docker-username=<your-harbor-username> \
     --docker-password=<your-harbor-password> \
     --docker-email=<your-email@example.com> \
     --namespace=mcp-servers
   
   # Verify the secret was created
   kubectl get secret harbor-registry-secret -n mcp-servers
   ```
   
   **Alternative**: Use the example template and apply it manually:
   ```bash
   # Edit mcp-servers/harbor-registry-secret.yaml.example with your credentials
   # Then apply it
   kubectl apply -f mcp-servers/harbor-registry-secret.yaml
   ```

2. **Create Application Secrets** (one-time setup):
   ```bash
   # Copy example secrets and fill in your values
   cp mcp-servers/proxmox-ve-mcp/secret.yaml.example mcp-servers/proxmox-ve-mcp/secret.yaml
   cp mcp-servers/unifi-network-mcp/secret.yaml.example mcp-servers/unifi-network-mcp/secret.yaml
   cp mcp-servers/unifi-protect-mcp/secret.yaml.example mcp-servers/unifi-protect-mcp/secret.yaml
   cp mcp-servers/unifi-manager-mcp/secret.yaml.example mcp-servers/unifi-manager-mcp/secret.yaml
   
   # Edit each secret.yaml file with your actual credentials
   # DO NOT commit these files to git!
   ```

3. **Update kustomization.yaml** to include secrets:
   ```yaml
   resources:
     # ... existing resources ...
     - mcp-servers/proxmox-ve-mcp/secret.yaml
     - mcp-servers/unifi-network-mcp/secret.yaml
     - mcp-servers/unifi-protect-mcp/secret.yaml
     - mcp-servers/unifi-manager-mcp/secret.yaml
   ```

4. **Deploy everything**:
   ```bash
   kubectl apply -k .
   ```

### Using Individual Files

1. **Create the namespace**:
   ```bash
   kubectl apply -f namespace.yaml
   ```

2. **Create Harbor Registry Secret** (required for pulling images):
   ```bash
   kubectl create secret docker-registry harbor-registry-secret \
     --docker-server=harbor.dataknife.net \
     --docker-username=<your-harbor-username> \
     --docker-password=<your-harbor-password> \
     --docker-email=<your-email@example.com> \
     --namespace=mcp-servers
   ```

3. **Deploy each MCP server**:
   ```bash
   # Proxmox VE MCP
   kubectl apply -f mcp-servers/proxmox-ve-mcp/configmap.yaml
   kubectl apply -f mcp-servers/proxmox-ve-mcp/secret.yaml  # After creating from example
   kubectl apply -f mcp-servers/proxmox-ve-mcp/deployment.yaml
   kubectl apply -f mcp-servers/proxmox-ve-mcp/service.yaml
   
   # Repeat for other MCP servers...
   ```

## Configuration

### Namespace

All resources are deployed to the `mcp-servers` namespace, which is created automatically.

### Harbor Registry Authentication

All deployments are configured to use Harbor registry (`harbor.dataknife.net`) and require authentication to pull images. The `harbor-registry-secret` must be created in the `mcp-servers` namespace before deploying.

**Creating the Harbor Registry Secret**:
```bash
kubectl create secret docker-registry harbor-registry-secret \
  --docker-server=harbor.dataknife.net \
  --docker-username=<your-harbor-username> \
  --docker-password=<your-harbor-password> \
  --docker-email=<your-email@example.com> \
  --namespace=mcp-servers
```

**Note**: If using a Harbor robot account (recommended for CI/CD), use the robot account username and token. Robot account format: `robot$library+botname`.

**Using GitHub CLI and Actions**:

1. **Set up secrets using GitHub CLI**:
   ```bash
   # Use the interactive setup script
   ./scripts/setup-harbor-secrets.sh
   
   # Or manually set secrets
   echo "robot\$library+ci-bot" | gh secret set HARBOR_USERNAME
   echo "your-token" | gh secret set HARBOR_PASSWORD
   ```

2. **Deploy via GitHub Actions**: Run the workflow `.github/workflows/deploy-harbor-secret.yml` which will automatically pull secrets and create the Kubernetes secret.

All deployments include `imagePullSecrets` referencing this secret.

### Environment Variables

All servers use HTTP transport mode with the following common settings:
- `MCP_TRANSPORT=http`
- `MCP_HTTP_ADDR=:8000`
- `LOG_LEVEL` (from ConfigMap, default: "info")

### Server-Specific Configuration

#### Proxmox VE MCP
- **ConfigMap**: `proxmox-ve-mcp-config`
  - `LOG_LEVEL` (default: "info")
  - `PROXMOX_SKIP_SSL_VERIFY` (default: "false")
- **Secrets**: `proxmox-ve-mcp-secrets`
  - `PROXMOX_BASE_URL` - Proxmox server URL
  - `PROXMOX_API_USER` - API user
  - `PROXMOX_API_TOKEN_ID` - API token ID
  - `PROXMOX_API_TOKEN_SECRET` - API token secret

#### UniFi Network MCP
- **ConfigMap**: `unifi-network-mcp-config`
  - `LOG_LEVEL` (default: "info")
  - `UNIFI_BASE_URL` (default: "https://192.168.1.1")
  - `UNIFI_SKIP_SSL_VERIFY` (default: "false")
- **Secrets**: `unifi-network-mcp-secrets`
  - `UNIFI_API_KEY` - API key

#### UniFi Protect MCP
- **ConfigMap**: `unifi-protect-mcp-config`
  - `LOG_LEVEL` (default: "info")
  - `UNIFI_BASE_URL` (default: "https://192.168.1.1")
  - `UNIFI_SKIP_SSL_VERIFY` (default: "false")
- **Secrets**: `unifi-protect-mcp-secrets`
  - `UNIFI_API_KEY` - API key

#### UniFi Manager MCP
- **ConfigMap**: `unifi-manager-mcp-config`
  - `LOG_LEVEL` (default: "info")
- **Secrets**: `unifi-manager-mcp-secrets`
  - `UNIFI_API_KEY` - API key

#### High Command MCP
- **ConfigMap**: `high-command-mcp-config`
  - `LOG_LEVEL` (default: "info")
  - `MCP_WORKERS` (default: "4")
  - `X_SUPER_CLIENT` (default: "hc.mcp-servers.cluster")
  - `X_SUPER_CONTACT` (default: "ops@example.com")

## Health Checks

All deployments include:
- **Liveness Probe**: HTTP GET `/health` every 30 seconds
- **Readiness Probe**: HTTP GET `/health` every 10 seconds

## Resource Limits

Each pod has:
- **Requests**: 100m CPU, 128Mi memory
- **Limits**: 500m CPU, 512Mi memory

## Security

All deployments use:
- Non-root user (UID 1000)
- Read-only root filesystem
- Dropped capabilities
- No privilege escalation
- Dedicated namespace for isolation

## High Availability

- 2 replicas per deployment
- Pod anti-affinity to spread pods across nodes
- Health checks for automatic recovery

## Service Endpoints

All services are exposed on port 8000 in the `mcp-servers` namespace:
- `proxmox-ve-mcp.mcp-servers.svc.cluster.local:8000`
- `unifi-network-mcp.mcp-servers.svc.cluster.local:8000`
- `unifi-protect-mcp.mcp-servers.svc.cluster.local:8000`
- `unifi-manager-mcp.mcp-servers.svc.cluster.local:8000`
- `high-command-mcp.mcp-servers.svc.cluster.local:8000`

## Monitoring

Check deployment status:
```bash
# All MCP servers
kubectl get deployments -n mcp-servers
kubectl get pods -n mcp-servers -l component=mcp-server
kubectl get services -n mcp-servers -l component=mcp-server

# Specific server
kubectl get pods -n mcp-servers -l app=proxmox-ve-mcp
```

## Troubleshooting

View logs:
```bash
# All pods in namespace
kubectl logs -n mcp-servers -l component=mcp-server

# Specific server
kubectl logs -n mcp-servers -l app=proxmox-ve-mcp

# Specific pod
kubectl logs -n mcp-servers <pod-name>
```

Describe resources:
```bash
kubectl describe pod -n mcp-servers <pod-name>
kubectl describe deployment -n mcp-servers proxmox-ve-mcp
```

Check events:
```bash
kubectl get events -n mcp-servers --sort-by='.lastTimestamp'
```

## GitOps

This repository is designed for GitOps workflows. Update the manifests and apply changes through your GitOps tool (ArgoCD, Flux, Fleet, etc.).

### Fleet Compatibility

**Note**: The `kustomization.yaml` file has been renamed to `.kustomization.yaml` to prevent Rancher Fleet from auto-detecting it and attempting to use Kustomize post-rendering, which was causing deployment failures.

Fleet will process all Kubernetes YAML manifests directly, which works because:
- All manifests already have namespaces and labels specified
- Individual resource files are self-contained and valid
- Fleet can apply Kubernetes manifests directly without Kustomize

For local Kustomize usage, temporarily rename the file:
```bash
mv .kustomization.yaml kustomization.yaml
kubectl kustomize .
mv kustomization.yaml .kustomization.yaml
```

**Important**: Never commit `secret.yaml` files to the repository. Use a secrets management solution like:
- Sealed Secrets
- External Secrets Operator
- Vault
- Your GitOps tool's secret management

## Documentation

- **[MCP Servers Review](docs/MCP_SERVERS_REVIEW.md)** - Detailed review of all HTTP MCP servers
- **[Repository Structure](docs/STRUCTURE.md)** - Guide to the repository organization
- **[Contributing](CONTRIBUTING.md)** - Guidelines for contributing to this project
- **[Code of Conduct](CODE_OF_CONDUCT.md)** - Community standards and expectations
- **[Security Policy](SECURITY.md)** - Security reporting and best practices
- **[Changelog](CHANGELOG.md)** - History of changes and updates

## File Organization

Each MCP server has its own directory with:
- `deployment.yaml` - Deployment manifest
- `service.yaml` - Service manifest
- `configmap.yaml` - Non-sensitive configuration
- `secret.yaml.example` - Secret template (copy to `secret.yaml` and fill in)

This organization makes it easy to:
- Manage individual servers independently
- Apply changes to specific servers
- Understand the structure at a glance
- Scale to additional MCP servers

For more details, see [docs/STRUCTURE.md](docs/STRUCTURE.md).

## Development

This project uses Cursor IDE with the Composer model for AI-assisted development. See `.cursorrules` for project-specific coding guidelines and patterns.
