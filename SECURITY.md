# Security Policy

## Supported Versions

We actively support the latest version of the Kubernetes manifests in this repository. Security updates will be applied to the main branch.

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |

## Reporting a Vulnerability

We take the security of this project seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### Please do the following:

1. **Do not** open a public GitHub issue
2. Email the maintainers directly or create a private security advisory
3. Include the following information:
   - Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting, etc.)
   - Full paths of source file(s) related to the manifestation of the issue
   - The location of the affected source code (tag/branch/commit or direct URL)
   - Any special configuration required to reproduce the issue
   - Step-by-step instructions to reproduce the issue
   - Proof-of-concept or exploit code (if possible)
   - Impact of the issue, including how an attacker might exploit the issue

### What to expect:

- You will receive a response within 48 hours
- We will work with you to understand and resolve the issue quickly
- We will credit you for the discovery (unless you prefer to remain anonymous)

## Security Best Practices

This repository follows security best practices for Kubernetes deployments:

### Container Security
- All containers run as non-root users (UID 1000)
- Read-only root filesystem enabled
- All capabilities dropped
- No privilege escalation allowed

### Secret Management
- **Never commit secrets to the repository**
- Use `.example` files for secret templates
- Integrate with external secret management solutions:
  - Sealed Secrets
  - External Secrets Operator
  - HashiCorp Vault
  - Your GitOps tool's secret management

### Network Security
- Services use ClusterIP (internal only)
- All traffic within the cluster namespace
- Health checks for monitoring

### Resource Limits
- CPU and memory limits enforced
- Prevents resource exhaustion attacks

### Namespace Isolation
- All resources deployed to dedicated `mcp-servers` namespace
- Provides logical separation from other workloads

## Security Updates

When security vulnerabilities are discovered:
1. We will create a security advisory
2. Update affected manifests
3. Document the vulnerability and fix in CHANGELOG.md
4. Release updated manifests as soon as possible

## Dependencies

This repository contains Kubernetes manifests only. Security of the underlying MCP server container images is the responsibility of their respective maintainers. Please report vulnerabilities in container images to their respective projects.

## Additional Resources

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [OWASP Container Security](https://owasp.org/www-project-container-security/)
