#!/bin/bash
# Script to create Grafana service account and token for MCP server
# Usage: ./scripts/create-grafana-mcp-token.sh

set -e

GRAFANA_URL="${GRAFANA_URL:-https://grafana.dataknife.net}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-$(kubectl get secret grafana -n managed-syslog -o jsonpath='{.data.admin-password}' 2>/dev/null | base64 -d || echo '')}"

if [ -z "$GRAFANA_PASSWORD" ]; then
    echo "Error: GRAFANA_PASSWORD not set and could not retrieve from secret"
    echo "Please set GRAFANA_PASSWORD environment variable or ensure grafana secret exists"
    exit 1
fi

echo "Connecting to Grafana at $GRAFANA_URL..."

# Check if service account already exists
SA_ID=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    "$GRAFANA_URL/api/serviceaccounts/search?query=mcp-server" \
    | jq -r '.serviceAccounts[]? | select(.name=="mcp-server") | .id // empty')

if [ -z "$SA_ID" ]; then
    echo "Creating service account 'mcp-server' with Editor role..."
    SA_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        "$GRAFANA_URL/api/serviceaccounts" \
        -d '{"name":"mcp-server","role":"Editor","isDisabled":false}')
    
    SA_ID=$(echo "$SA_RESPONSE" | jq -r '.id // empty')
    
    if [ -z "$SA_ID" ] || [ "$SA_ID" = "null" ]; then
        echo "Error creating service account:"
        echo "$SA_RESPONSE" | jq '.'
        exit 1
    fi
    
    echo "Service account created with ID: $SA_ID"
else
    echo "Service account 'mcp-server' already exists with ID: $SA_ID"
fi

# Create token
echo "Creating service account token..."
TOKEN_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    "$GRAFANA_URL/api/serviceaccounts/$SA_ID/tokens" \
    -d '{"name":"mcp-server-token","secondsToLive":0}')

TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.key // empty')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "Error creating token:"
    echo "$TOKEN_RESPONSE" | jq '.'
    exit 1
fi

echo ""
echo "=========================================="
echo "Service Account Token created successfully!"
echo "=========================================="
echo ""
echo "Token: $TOKEN"
echo ""
echo "To update the secret, run:"
echo "  kubectl create secret generic grafana-mcp-secrets \\"
echo "    --from-literal=GRAFANA_SERVICE_ACCOUNT_TOKEN='$TOKEN' \\"
echo "    --from-literal=GRAFANA_ORG_ID='' \\"
echo "    -n mcp-servers \\"
echo "    --dry-run=client -o yaml | kubectl apply -f -"
echo ""
echo "Or update the existing secret:"
echo "  kubectl patch secret grafana-mcp-secrets -n mcp-servers \\"
echo "    --type='json' \\"
echo "    -p='[{\"op\":\"replace\",\"path\":\"/data/GRAFANA_SERVICE_ACCOUNT_TOKEN\",\"value\":\"'$(echo -n "$TOKEN" | base64 -w 0)'\"}]'"
echo ""
