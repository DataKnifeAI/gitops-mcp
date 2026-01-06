# Contributing to GitOps MCP

Thank you for your interest in contributing to GitOps MCP! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

This project adheres to a Code of Conduct that all contributors are expected to follow. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the issue list as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title**
* **Describe the exact steps to reproduce the problem**
* **Provide specific examples to demonstrate the steps**
* **Describe the behavior you observed after following the steps**
* **Explain which behavior you expected to see instead and why**
* **Include screenshots and animated GIFs if applicable**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title**
* **Provide a step-by-step description of the suggested enhancement**
* **Provide specific examples to demonstrate the steps**
* **Describe the current behavior and explain which behavior you expected to see instead**
* **Explain why this enhancement would be useful**

### Pull Requests

* Fill in the required template
* Do not include issue numbers in the PR title
* Include screenshots and animated GIFs in your pull request whenever possible
* Follow the Kubernetes manifest style guide (see below)
* Include thoughtfully-worded, well-structured tests
* Document new code based on the Documentation Styleguide
* End all files with a newline
* Place requires in alphabetical order
* Avoid platform-dependent code

## Development Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following the style guidelines
4. Commit your changes (`git commit -m 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## Kubernetes Manifest Style Guide

### YAML Formatting
- Use 2 spaces for indentation
- Always specify `namespace: mcp-servers` in metadata
- Include appropriate labels: `app`, `component: mcp-server`, `managed-by: gitops`
- Use consistent resource naming: `{server-name}-mcp`

### File Organization
- Each MCP server has its own directory under `mcp-servers/`
- Separate concerns: `deployment.yaml`, `service.yaml`, `configmap.yaml`, `secret.yaml.example`
- Never commit actual `secret.yaml` files (use `.example` templates)

### Security Best Practices
- Always use non-root users (UID 1000)
- Enable read-only root filesystem
- Drop all capabilities
- Disable privilege escalation
- Use ConfigMaps for non-sensitive data
- Use Secrets for sensitive data (never commit)

### Resource Management
- Standard resource requests: 100m CPU, 128Mi memory
- Standard resource limits: 500m CPU, 512Mi memory
- Always include health checks (liveness and readiness probes)
- Use pod anti-affinity for high availability

## Adding New MCP Servers

When adding a new MCP server:

1. Create directory: `mcp-servers/{server-name}/`
2. Create files: `deployment.yaml`, `service.yaml`, `configmap.yaml`, `secret.yaml.example`
3. Add resources to `kustomization.yaml`
4. Update documentation in `docs/` folder
5. Follow existing patterns for consistency
6. Update `README.md` with server information

## Testing

Before submitting a pull request:

1. Validate YAML syntax:
   ```bash
   kubectl apply --dry-run=client -k .
   ```

2. Verify namespace is correct:
   ```bash
   kubectl get all -n mcp-servers
   ```

3. Check resource limits are appropriate

## GitOps Considerations

- This repo is designed for GitOps workflows (ArgoCD, Flux, etc.)
- Secrets should be managed externally (Sealed Secrets, External Secrets, Vault)
- Use Kustomize for resource management
- Keep manifests declarative and idempotent

## Questions?

If you have questions about contributing, please open an issue or contact the maintainers.

Thank you for contributing! 🎉
