# Repository Structure

This document describes the organized folder structure for MCP server deployments.

## Directory Tree

```
gitops-mcp/
├── namespace.yaml                    # Dedicated mcp-servers namespace
├── kustomization.yaml                # Kustomize configuration for all resources
├── README.md                          # Main documentation
├── .cursorrules                      # Cursor IDE instructions
├── .gitignore                         # Git ignore rules
├── docs/                              # Documentation
│   ├── MCP_SERVERS_REVIEW.md         # Server review and details
│   └── STRUCTURE.md                   # This file
└── mcp-servers/                       # All MCP server deployments
    ├── proxmox-ve-mcp/
    │   ├── deployment.yaml            # Deployment manifest
    │   ├── service.yaml               # Service manifest
    │   ├── configmap.yaml             # Non-sensitive configuration
    │   └── secret.yaml.example        # Secret template (DO NOT COMMIT actual secrets)
    │
    ├── unifi-network-mcp/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── configmap.yaml
    │   └── secret.yaml.example
    │
    ├── unifi-protect-mcp/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── configmap.yaml
    │   └── secret.yaml.example
    │
    └── high-command-mcp/
        ├── deployment.yaml
        ├── service.yaml
        ├── serviceaccount.yaml        # ServiceAccount (unique to this server)
        ├── configmap.yaml
        └── secret.yaml.example
```

## File Organization Principles

### Per-Server Directory Structure

Each MCP server has its own directory containing:
- **deployment.yaml** - Kubernetes Deployment resource
- **service.yaml** - Kubernetes Service resource
- **configmap.yaml** - Non-sensitive configuration values
- **secret.yaml.example** - Template for secrets (copy to `secret.yaml` and fill in)
- **serviceaccount.yaml** - ServiceAccount (only if needed)

### Benefits of This Structure

1. **Isolation**: Each server's configuration is self-contained
2. **Clarity**: Easy to find and modify server-specific resources
3. **Scalability**: Simple to add new MCP servers
4. **Maintainability**: Changes to one server don't affect others
5. **GitOps Friendly**: Works well with ArgoCD, Flux, and other GitOps tools

## Namespace

All resources are deployed to the **`mcp-servers`** namespace, which provides:
- Isolation from other workloads
- Centralized management
- Easy resource discovery
- Simplified RBAC configuration

## Deployment Methods

### Method 1: Kustomize (Recommended)

Deploy everything at once:
```bash
kubectl apply -k .
```

### Method 2: Individual Server

Deploy a specific server:
```bash
kubectl apply -f mcp-servers/proxmox-ve-mcp/
```

### Method 3: Individual Resources

Deploy specific resources:
```bash
kubectl apply -f mcp-servers/proxmox-ve-mcp/deployment.yaml
kubectl apply -f mcp-servers/proxmox-ve-mcp/service.yaml
```

## Adding a New MCP Server

1. Create a new directory: `mcp-servers/new-server-name/`
2. Create the following files:
   - `deployment.yaml`
   - `service.yaml`
   - `configmap.yaml`
   - `secret.yaml.example`
3. Add the resources to `kustomization.yaml`
4. Update documentation

## Secret Management

**Important**: Never commit actual `secret.yaml` files. Use one of:
- Sealed Secrets
- External Secrets Operator
- HashiCorp Vault
- Your GitOps tool's secret management

The `.gitignore` file is configured to exclude `secret.yaml` files.
