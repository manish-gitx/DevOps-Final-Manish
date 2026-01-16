#!/bin/bash
# Script to set up local Kubernetes cluster for CD deployment
# Supports both minikube and kind

set -e

echo "========================================="
echo "Local Kubernetes Cluster Setup"
echo "========================================="

# Detect which local K8s tool is available
if command -v minikube &> /dev/null; then
    K8S_TOOL="minikube"
    echo "✓ Detected: minikube"
elif command -v kind &> /dev/null; then
    K8S_TOOL="kind"
    echo "✓ Detected: kind"
else
    echo "❌ Error: Neither minikube nor kind found."
    echo ""
    echo "Please install one of the following:"
    echo "  - minikube: https://minikube.sigs.k8s.io/docs/start/"
    echo "  - kind: https://kind.sigs.k8s.io/docs/user/quick-start/"
    exit 1
fi

# Check for kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl not found."
    echo "Please install kubectl: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

echo "✓ kubectl is installed"

# Create/Start cluster
echo ""
echo "Setting up $K8S_TOOL cluster..."

if [ "$K8S_TOOL" = "minikube" ]; then
    # Check if cluster already exists
    if minikube status &> /dev/null; then
        echo "✓ Minikube cluster already running"
    else
        echo "Starting new minikube cluster..."
        minikube start --driver=docker --cpus=2 --memory=4096
        echo "✓ Minikube cluster started"
    fi
    
    # Enable addons for better local development
    echo "Enabling minikube addons..."
    minikube addons enable metrics-server
    minikube addons enable ingress
    
    # Set docker env to use minikube's docker daemon (optional)
    echo ""
    echo "To use minikube's Docker daemon (optional):"
    echo "  eval \$(minikube docker-env)"
    
elif [ "$K8S_TOOL" = "kind" ]; then
    CLUSTER_NAME="devops-local"
    
    # Check if cluster already exists
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        echo "✓ Kind cluster '$CLUSTER_NAME' already exists"
    else
        echo "Creating new kind cluster '$CLUSTER_NAME'..."
        cat <<EOF | kind create cluster --name=$CLUSTER_NAME --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
EOF
        echo "✓ Kind cluster created"
    fi
    
    # Set kubectl context
    kubectl cluster-info --context kind-$CLUSTER_NAME
fi

# Verify cluster is working
echo ""
echo "Verifying cluster..."
kubectl cluster-info
kubectl get nodes

echo ""
echo "========================================="
echo "✓ Local Kubernetes cluster is ready!"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Pull/build your Docker image"
echo "  2. Run: ./scripts/deploy-to-k8s.sh <dockerhub-username>"
echo ""

if [ "$K8S_TOOL" = "minikube" ]; then
    echo "Useful minikube commands:"
    echo "  minikube dashboard    - Open Kubernetes dashboard"
    echo "  minikube stop         - Stop the cluster"
    echo "  minikube delete       - Delete the cluster"
    echo "  minikube service list - List services and URLs"
elif [ "$K8S_TOOL" = "kind" ]; then
    echo "Useful kind commands:"
    echo "  kind get clusters              - List clusters"
    echo "  kind delete cluster --name=$CLUSTER_NAME - Delete cluster"
    echo "  kubectl get all -n devops-app  - View all resources"
fi

echo ""
