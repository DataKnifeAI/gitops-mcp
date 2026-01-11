# HTTP MCP Servers Review

This document summarizes the HTTP MCP servers found in `/home/lee/git` and their deployment configurations.

## Reviewed MCP Servers

### 1. **proxmox-ve-mcp**
- **Location**: `/home/lee/git/proxmox-ve-mcp`
- **Language**: Go
- **HTTP Support**: ✅ Yes (via `MCP_TRANSPORT=http`)
- **Default Port**: 8000
- **Image**: `harbor.dataknife.net/library/proxmox-ve-mcp:latest`
- **Configuration**:
  - Requires: `PROXMOX_BASE_URL`, `PROXMOX_API_USER`, `PROXMOX_API_TOKEN_ID`, `PROXMOX_API_TOKEN_SECRET`
  - Optional: `PROXMOX_SKIP_SSL_VERIFY`

### 2. **unifi-network-mcp**
- **Location**: `/home/lee/git/unifi-network-mcp`
- **Language**: Go
- **HTTP Support**: ✅ Yes (via `MCP_TRANSPORT=http`)
- **Default Port**: 8000
- **Image**: `harbor.dataknife.net/library/unifi-network-mcp:latest`
- **Configuration**:
  - Requires: `UNIFI_API_KEY`
  - Optional: `UNIFI_BASE_URL` (default: `https://192.168.1.1`), `UNIFI_SKIP_SSL_VERIFY`

### 3. **unifi-protect-mcp**
- **Location**: `/home/lee/git/unifi-protect-mcp`
- **Language**: Go
- **HTTP Support**: ✅ Yes (via `MCP_TRANSPORT=http`)
- **Default Port**: 8000
- **Image**: `harbor.dataknife.net/library/unifi-protect-mcp:latest`
- **Configuration**:
  - Requires: `UNIFI_API_KEY`
  - Optional: `UNIFI_BASE_URL` (default: `https://192.168.1.1`), `UNIFI_SKIP_SSL_VERIFY`

### 4. **high-command-mcp**
- **Location**: `/home/lee/git/high-command/high-command-mcp`
- **Language**: Python
- **HTTP Support**: ✅ Yes (via `MCP_TRANSPORT=http`)
- **Default Port**: 8000
- **Image**: `harbor.dataknife.net/library/high-command-mcp:latest`
- **Configuration**:
  - Optional: `MCP_WORKERS`, `X_SUPER_CLIENT`, `X_SUPER_CONTACT`
- **Note**: Already had a deployment example in `k8s/deployment.yaml` (updated for nrpd-apps)

## Servers Not Included

### proton-mail-mcp
- **Location**: `/home/lee/git/proton-mail-mcp`
- **Status**: Empty directory - no implementation found

### rancher-manager-mcp
- **Location**: `/home/lee/git/rancher-manager-mcp`
- **Status**: Empty directory - no implementation found

## Deployment Features

All deployments include:

1. **High Availability**
   - 2 replicas per deployment
   - Pod anti-affinity for node distribution

2. **Health Monitoring**
   - Liveness probes (30s interval)
   - Readiness probes (10s interval)
   - HTTP health endpoint at `/health`

3. **Security**
   - Non-root user (UID 1000)
   - Read-only root filesystem
   - Dropped capabilities
   - No privilege escalation

4. **Resource Management**
   - CPU: 100m request, 500m limit
   - Memory: 128Mi request, 512Mi limit

5. **Service Discovery**
   - ClusterIP services on port 8000
   - DNS names: `<service-name>.mcp-servers.svc.cluster.local`

## Files Created

1. **Deployment Manifests** (in `mcp-servers/` directories):
   - `proxmox-ve-mcp/deployment.yaml`
   - `unifi-network-mcp/deployment.yaml`
   - `unifi-protect-mcp/deployment.yaml`
   - `high-command-mcp/deployment.yaml`

2. **Configuration** (per-server directories):
   - `configmap.yaml` - Non-sensitive configuration per server
   - `secret.yaml.example` - Secret templates (DO NOT COMMIT actual secrets)

3. **Documentation**:
   - `README.md` - Main deployment instructions
   - `docs/MCP_SERVERS_REVIEW.md` - This file
   - `docs/STRUCTURE.md` - Repository structure guide

4. **GitOps**:
   - `kustomization.yaml` - Kustomize configuration
   - `.gitignore` - Excludes secrets
   - `namespace.yaml` - MCP servers namespace

## Next Steps

1. **Create Secrets**: Copy `secret.yaml.example` to `secret.yaml` in each server directory and fill in actual values
2. **Build/Push Images**: Ensure container images are available at the specified registries
3. **Create Namespace**: `kubectl apply -f namespace.yaml` (or it will be created automatically)
4. **Apply Manifests**: Use `kubectl apply -k .` or apply individual files
5. **Verify**: Check pod status and logs

## Notes

- All servers default to stdio transport if `MCP_TRANSPORT` is not set to "http"
- All servers use port 8000 for HTTP transport
- Secrets should be managed through a secrets management solution (Sealed Secrets, External Secrets, Vault, etc.)
- Consider using GitOps tools (ArgoCD, Flux) for automated deployment
