#!/bin/sh

echo "\n🔥 Tearing down Airline Tickets Kubernetes cluster...\n"

echo "⚠️  This will destroy the entire development environment!"
echo "   - Minikube cluster will be deleted"
echo "   - All data will be lost"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "\n❌ Teardown cancelled\n"
    exit 0
fi

echo "\n🗑️  Deleting all resources..."

echo "\n   📦 Removing application services..."
kubectl delete all --all --grace-period=0 --force

echo "\n   🔐 Removing secrets..."
kubectl delete secrets --all --grace-period=0 --force

echo "\n   📋 Removing configmaps..."
kubectl delete configmaps --all --grace-period=0 --force

echo "\n   💾 Removing persistent volumes..."
kubectl delete pvc --all --grace-period=0 --force
kubectl delete pv --all --grace-period=0 --force

echo "\n   🌐 Removing ingress..."
kubectl delete ingress --all --grace-period=0 --force

echo "\n🔥 Stopping and deleting Minikube cluster..."
minikube stop --profile airline
minikube delete --profile airline

echo "\n🧹 Cleaning up Docker resources..."
docker system prune -f

echo "\n💥 Development environment destroyed!\n"
echo "🚀 To recreate: ./scripts/setup-development.sh"