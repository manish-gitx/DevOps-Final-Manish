#!/bin/bash
# Script to clean up Kubernetes deployment

set -e

echo "========================================="
echo "Kubernetes Cleanup"
echo "========================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl not found"
    exit 1
fi

# Check if cluster is running
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: Kubernetes cluster not accessible"
    exit 1
fi

# Check if namespace exists
if kubectl get namespace devops-app &> /dev/null; then
    echo "Deleting namespace 'devops-app' and all resources..."
    kubectl delete namespace devops-app
    echo "✓ Namespace deleted"
else
    echo "ℹ Namespace 'devops-app' does not exist"
fi

echo ""
echo "========================================="
echo "✓ Cleanup Complete!"
echo "========================================="
echo ""
echo "To delete the entire local cluster:"
echo ""
echo "For minikube:"
echo "  minikube stop    - Stop the cluster"
echo "  minikube delete  - Delete the cluster"
echo ""
echo "For kind:"
echo "  kind delete cluster --name devops-local"
echo ""
