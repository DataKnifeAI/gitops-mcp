#!/bin/bash
#
# Restart RKE2 services on cluster nodes to apply Harbor certificate configuration
#
# This script SSHes to each node and restarts the appropriate RKE2 service
# (rke2-server on control-plane nodes, rke2-agent on worker nodes)
#
# Usage:
#   ./scripts/restart-rke2-services.sh [context] [ssh-user]
#
# Example:
#   ./scripts/restart-rke2-services.sh prd-apps root
#   ./scripts/restart-rke2-services.sh prd-apps ubuntu

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTEXT="${1:-prd-apps}"
SSH_USER="${2:-root}"
NAMESPACE="${K8S_NAMESPACE:-mcp-servers}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if context exists
if ! kubectl config get-contexts "$CONTEXT" &> /dev/null; then
    echo -e "${RED}❌ Error: Kubernetes context '$CONTEXT' not found${NC}"
    exit 1
fi

echo -e "${BLUE}🔧 RKE2 Service Restart Script${NC}"
echo "=================================="
echo "Context: $CONTEXT"
echo "SSH User: $SSH_USER"
echo "Namespace: $NAMESPACE"
echo ""

# Wait for DaemonSet to be ready
echo -e "${BLUE}📋 Checking DaemonSet status...${NC}"
if ! kubectl get daemonset containerd-harbor-cert-config -n "$NAMESPACE" --context="$CONTEXT" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Warning: containerd-harbor-cert-config DaemonSet not found in namespace $NAMESPACE${NC}"
    echo "Please ensure the DaemonSet is deployed first."
    exit 1
fi

READY=$(kubectl get daemonset containerd-harbor-cert-config -n "$NAMESPACE" --context="$CONTEXT" -o jsonpath='{.status.numberReady}')
DESIRED=$(kubectl get daemonset containerd-harbor-cert-config -n "$NAMESPACE" --context="$CONTEXT" -o jsonpath='{.status.desiredNumberScheduled}')

if [ "$READY" != "$DESIRED" ]; then
    echo -e "${YELLOW}⚠️  Warning: DaemonSet not fully ready ($READY/$DESIRED pods ready)${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✅ DaemonSet is ready ($READY/$DESIRED pods)${NC}"
fi

echo ""
echo -e "${BLUE}📋 Getting node list...${NC}"

# Get nodes and determine their roles
NODES=$(kubectl get nodes --context="$CONTEXT" -o json | jq -r '.items[] | "\(.metadata.name)|\(.metadata.labels."node-role.kubernetes.io/control-plane" // "none")|\(.metadata.labels."node-role.kubernetes.io/worker" // "none")"')

if [ -z "$NODES" ]; then
    echo -e "${RED}❌ Error: No nodes found in cluster${NC}"
    exit 1
fi

# Process each node
SUCCESS_COUNT=0
FAILED_NODES=()

while IFS='|' read -r NODE_NAME CONTROL_PLANE WORKER; do
    # Determine service name
    if [ "$CONTROL_PLANE" != "none" ]; then
        SERVICE="rke2-server"
        NODE_TYPE="control-plane"
    else
        SERVICE="rke2-agent"
        NODE_TYPE="worker"
    fi

    echo ""
    echo -e "${BLUE}🔄 Processing node: ${NODE_NAME} (${NODE_TYPE})${NC}"
    echo "  Service: $SERVICE"

    # Try to get node IP
    NODE_IP=$(kubectl get node "$NODE_NAME" --context="$CONTEXT" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "")
    
    if [ -z "$NODE_IP" ]; then
        # Fallback: try ExternalIP
        NODE_IP=$(kubectl get node "$NODE_NAME" --context="$CONTEXT" -o jsonpath='{.status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null || echo "")
    fi

    if [ -z "$NODE_IP" ]; then
        echo -e "${YELLOW}⚠️  Warning: Could not determine node IP, using hostname: $NODE_NAME${NC}"
        SSH_TARGET="$NODE_NAME"
    else
        SSH_TARGET="$NODE_IP"
        echo "  IP: $NODE_IP"
    fi

    # SSH and restart service
    echo -e "${BLUE}  SSH to $SSH_TARGET and restart $SERVICE...${NC}"
    
    if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_USER@$SSH_TARGET" "sudo systemctl restart $SERVICE && sudo systemctl status $SERVICE --no-pager -l" 2>&1; then
        echo -e "${GREEN}  ✅ Successfully restarted $SERVICE on $NODE_NAME${NC}"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo -e "${RED}  ❌ Failed to restart $SERVICE on $NODE_NAME${NC}"
        FAILED_NODES+=("$NODE_NAME")
    fi

done <<< "$NODES"

echo ""
echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo "=================================="
echo "Total nodes processed: $(echo "$NODES" | wc -l)"
echo -e "${GREEN}Successful: $SUCCESS_COUNT${NC}"
if [ ${#FAILED_NODES[@]} -gt 0 ]; then
    echo -e "${RED}Failed: ${#FAILED_NODES[@]}${NC}"
    echo "Failed nodes:"
    for node in "${FAILED_NODES[@]}"; do
        echo "  - $node"
    done
    exit 1
else
    echo -e "${GREEN}✅ All nodes processed successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Wait a few minutes for RKE2 services to fully restart"
    echo "2. Check pod status: kubectl get pods -n $NAMESPACE --context=$CONTEXT"
    echo "3. Verify image pulls are working"
fi
