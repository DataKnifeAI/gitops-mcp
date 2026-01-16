# Grafana MCP Server Deployment

This directory contains the Kubernetes manifests for deploying the Grafana MCP (Model Context Protocol) server.

## Deployment Status

✅ **Deployed and Running**
- Namespace: `mcp-servers`
- Deployment: `grafana-mcp` (3 replicas)
- Service: `grafana-mcp` (ClusterIP on port 8000)
- Ingress: `grafana-mcp.dataknife.net`
- Health Endpoint: `/healthz`

## Configuration

### ConfigMap
- **GRAFANA_URL**: `https://grafana.dataknife.net` (cross-cluster access via ingress)

### Secret (Required)
The secret `grafana-mcp-secrets` must contain:
- **GRAFANA_SERVICE_ACCOUNT_TOKEN**: Service account token for authentication
- **GRAFANA_ORG_ID**: (Optional) Organization ID for multi-org setups

## Creating the Service Account Token

Since automated token creation via API requires admin credentials that may not be accessible, create the token manually:

### Option 1: Via Grafana UI (Recommended)

1. Access Grafana at `https://grafana.dataknife.net`
2. Log in with admin credentials
3. Navigate to **Administration** → **Service Accounts**
4. Click **New service account**
5. Create service account:
   - **Name**: `mcp-server`
   - **Role**: `Editor` (or appropriate role based on your needs)
6. Click **Add service account**
7. In the service account details, click **Add token** → **Add service account token**
8. Name: `mcp-server-token`
9. Copy the generated token

### Option 2: Via Grafana API

If you have admin access to Grafana API:

```bash
# Set variables
GRAFANA_URL="https://grafana.dataknife.net"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="your-admin-password"

# Create service account
SA_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
  "$GRAFANA_URL/api/serviceaccounts" \
  -d '{"name":"mcp-server","role":"Editor","isDisabled":false}')

SA_ID=$(echo "$SA_RESPONSE" | jq -r '.id')

# Create token
TOKEN_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
  "$GRAFANA_URL/api/serviceaccounts/$SA_ID/tokens" \
  -d '{"name":"mcp-server-token","secondsToLive":0}')

TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.key')
echo "Token: $TOKEN"
```

## Updating the Secret

**Important:** The secret is stored on the **prd-apps** cluster, not in git. Never commit secret files.

Once you have the token, update the secret on the prd-apps cluster:

```bash
# Switch to prd-apps cluster
kubectl config use-context prd-apps

# Base64 encode the token
TOKEN_B64=$(echo -n "YOUR_TOKEN_HERE" | base64 -w 0)

# Update the secret
kubectl patch secret grafana-mcp-secrets -n mcp-servers --type='json' \
  -p="[{\"op\":\"replace\",\"path\":\"/data/GRAFANA_SERVICE_ACCOUNT_TOKEN\",\"value\":\"$TOKEN_B64\"}]"

# Restart pods to pick up the new token (on prd-apps cluster)
kubectl rollout restart deployment grafana-mcp -n mcp-servers
```

Or create the secret from scratch:

```bash
# Switch to prd-apps cluster
kubectl config use-context prd-apps

# Create/update the secret
kubectl create secret generic grafana-mcp-secrets \
  --from-literal=GRAFANA_SERVICE_ACCOUNT_TOKEN='YOUR_TOKEN_HERE' \
  --from-literal=GRAFANA_ORG_ID='' \
  -n mcp-servers \
  --dry-run=client -o yaml | kubectl apply -f -

# Label the secret
kubectl label secret grafana-mcp-secrets -n mcp-servers \
  app=grafana-mcp component=mcp-server --overwrite
```

## Verification

Check deployment status:

```bash
# Check pods
kubectl get pods -n mcp-servers -l app=grafana-mcp

# Check logs
kubectl logs -n mcp-servers -l app=grafana-mcp --tail=50

# Test health endpoint
curl http://$(kubectl get svc grafana-mcp -n mcp-servers -o jsonpath='{.spec.clusterIP}'):8000/healthz
```

## Required RBAC Permissions

The service account needs appropriate permissions based on which MCP tools you plan to use. The `Editor` role provides broad access. For more granular control, see the [Grafana MCP documentation](https://github.com/grafana/mcp-grafana) for specific RBAC requirements.

Common permissions needed:
- `datasources:read`, `datasources:query` - For querying Loki, Prometheus, etc.
- `dashboards:read`, `dashboards:write` - For dashboard operations
- `alert.rules:read`, `alert.rules:write` - For alert management
- `folders:*` - For folder operations

## Troubleshooting

### Pods not starting
- Check if the secret exists and contains valid token
- Verify image can be pulled: `kubectl describe pod -n mcp-servers -l app=grafana-mcp`

### Authentication errors
- Verify the service account token is valid
- Check Grafana URL is accessible from the pod
- Ensure service account has required permissions

### Health check failures
- Check pod logs: `kubectl logs -n mcp-servers -l app=grafana-mcp`
- Verify `/healthz` endpoint is responding
