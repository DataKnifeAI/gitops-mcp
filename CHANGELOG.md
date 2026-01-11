# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial repository structure
- Kubernetes manifests for MCP servers:
  - proxmox-ve-mcp
  - unifi-network-mcp
  - unifi-protect-mcp
  - high-command-mcp
- Kustomize configuration
- Documentation structure
- Security best practices implementation
- Health checks and resource limits
- High availability configuration
- Harbor registry authentication support with `imagePullSecrets`
- GitHub Actions workflow for automated Harbor secret deployment (`.github/workflows/deploy-harbor-secret.yml`)
- GitHub CLI integration for secret management
- Interactive setup script (`scripts/setup-harbor-secrets.sh`) for setting Harbor secrets using `gh secret`

### Changed
- Updated all Docker image paths from `ghcr.io/surrealwolf/*` to `harbor.dataknife.net/library/*` registry
  - proxmox-ve-mcp: `harbor.dataknife.net/library/proxmox-ve-mcp:latest`
  - unifi-network-mcp: `harbor.dataknife.net/library/unifi-network-mcp:latest`
  - unifi-protect-mcp: `harbor.dataknife.net/library/unifi-protect-mcp:latest`
  - high-command-mcp: `harbor.dataknife.net/library/high-command-mcp:latest`
- Updated documentation to reflect new Harbor registry image paths

### Deprecated

### Removed
- unifi-manager-mcp - Removed due to container image issues

### Fixed

### Security
