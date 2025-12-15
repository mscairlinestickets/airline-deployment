#!/bin/sh

echo "\n🚀 Initializing Airline Tickets Kubernetes cluster...\n"
minikube start --cpus 4 --memory 8g --driver docker --profile airline

echo "\n🔌 Enabling NGINX Ingress Controller...\n"
minikube addons enable ingress --profile airline
sleep 30

echo "\n📦 Deploying PostgreSQL..."
kubectl apply -f kubernetes/platform/development/services/airline-postgres/postgres-configmap.yaml
kubectl apply -f kubernetes/platform/development/services/airline-postgres/postgres-deployment.yaml
kubectl apply -f kubernetes/platform/development/services/airline-postgres/postgres-clusterip.yaml
sleep 5

echo "\n⌛ Waiting for PostgreSQL to be deployed..."
while [ $(kubectl get pod -l app=postgres | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "\n⌛ Waiting for PostgreSQL to be ready..."
kubectl wait \
  --for=condition=ready pod \
  --selector=app=postgres \
  --timeout=300s

echo "\n📦 Deploying Redis..."
kubectl apply -f kubernetes/platform/development/services/redis/redis.yaml
sleep 5

echo "\n⌛ Waiting for Redis to be deployed..."
while [ $(kubectl get pod -l app=redis | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "\n⌛ Waiting for Redis to be ready..."
kubectl wait \
  --for=condition=ready pod \
  --selector=app=redis \
  --timeout=180s

echo "\n📦 Deploying Zookeeper..."
kubectl apply -f kubernetes/platform/development/services/zookeper/deployment.yaml
sleep 5

echo "\n⌛ Waiting for Zookeeper to be deployed..."
while [ $(kubectl get pod -l app=zookeeper | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "\n⌛ Waiting for Zookeeper to be ready..."
kubectl wait \
  --for=condition=ready pod \
  --selector=app=zookeeper \
  --timeout=180s

echo "\n📦 Deploying Kafka..."
kubectl apply -f kubernetes/platform/development/services/kafka-airlines/kafka-envs.yaml
kubectl apply -f kubernetes/platform/development/services/kafka-airlines/kafka-deployment.yaml
kubectl apply -f kubernetes/platform/development/services/kafka-airlines/services-clusterip.yaml
sleep 10

echo "\n⌛ Waiting for Kafka to be deployed..."
while [ $(kubectl get pod -l app=kafka | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "\n⌛ Waiting for Kafka to be ready..."
kubectl wait \
  --for=condition=ready pod \
  --selector=app=kafka \
  --timeout=300s

echo "\n📦 Deploying Kafka UI..."
kubectl apply -f kubernetes/platform/development/services/kafka-ui/kafka-ui.yaml
sleep 5

echo "\n⌛ Waiting for Kafka UI to be deployed..."
while [ $(kubectl get pod -l app=kafka-ui | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "\n⌛ Waiting for Kafka UI to be ready..."
kubectl wait \
  --for=condition=ready pod \
  --selector=app=kafka-ui \
  --timeout=180s

echo "\n📊 Deploying Observability Stack..."

echo "\n   📈 Deploying Tempo..."
kubectl apply -f kubernetes/platform/development/services/observability/tempo/tempo.yaml
sleep 5

echo "\n   📊 Deploying Loki..."
kubectl apply -f kubernetes/platform/development/services/observability/loki/loki.yaml
sleep 5

echo "\n   📋 Deploying Fluent Bit..."
kubectl apply -f kubernetes/platform/development/services/observability/fluent-bit/fluent-bit.yaml
sleep 5

echo "\n   📉 Deploying Grafana..."
kubectl apply -f kubernetes/platform/development/services/observability/grafana/grafana.yaml
sleep 5

echo "\n⌛ Waiting for Observability Stack to be ready..."
kubectl wait \
  --for=condition=ready pod \
  --selector=app=tempo \
  --timeout=180s

kubectl wait \
  --for=condition=ready pod \
  --selector=app=loki \
  --timeout=180s

kubectl wait \
  --for=condition=ready pod \
  --selector=app=grafana \
  --timeout=180s

echo "\n🎯 Creating necessary secrets..."

echo "\n   🔐 Creating PostgreSQL secrets..."
kubectl create secret generic postgres-ticket-credentials \
  --from-literal=username=user \
  --from-literal=password=password \
  --from-literal=database=ticketdb \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic postgres-booking-credentials \
  --from-literal=username=user \
  --from-literal=password=password \
  --from-literal=database=bookingdb \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic postgres-auth-credentials \
  --from-literal=username=user \
  --from-literal=password=password \
  --from-literal=database=authdb \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic postgres-payment-credentials \
  --from-literal=username=user \
  --from-literal=password=password \
  --from-literal=database=paymentdb \
  --dry-run=client -o yaml | kubectl apply -f -

echo "\n   🔐 Creating OAuth2 secrets..."
kubectl create secret generic oauth-resourceserver-secret \
  --from-literal=spring.security.oauth2.resourceserver.jwt.issuer-uri=http://auth-service:9000 \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic oauth-authserver-secret \
  --from-literal=spring.security.oauth2.authorizationserver.client.oidc-client.registration.client-id=edge-service \
  --from-literal=spring.security.oauth2.authorizationserver.client.oidc-client.registration.client-secret=polar-keycloak-secret \
  --dry-run=client -o yaml | kubectl apply -f -

echo "\n   🔐 Creating Redis secrets..."
kubectl create secret generic redis-credentials \
  --from-literal=spring.data.redis.host=redis-service \
  --from-literal=spring.data.redis.port=6379 \
  --dry-run=client -o yaml | kubectl apply -f -

echo "\n   💳 Creating Payment Gateway secrets..."
kubectl create secret generic payment-gateway-secrets \
  --from-literal=stripe-api-key=sk_test_your_stripe_key_here \
  --from-literal=webhook-secret=whsec_your_webhook_secret_here \
  --dry-run=client -o yaml | kubectl apply -f -

echo "\n📋 Cluster Information:"
echo "======================"
kubectl cluster-info

echo "\n📊 Infrastructure Status:"
echo "========================"
kubectl get pods -o wide

echo "\n🌐 Services:"
echo "==========="
kubectl get services

echo "\n🎯 Port Forwarding Commands:"
echo "============================"
echo "   Kafka UI:    kubectl port-forward svc/kafka-ui 8080:8080"
echo "   Grafana:     kubectl port-forward svc/grafana 3000:3000"
echo "   PostgreSQL:  kubectl port-forward svc/postgres-service 5432:5432"
echo "   Redis:       kubectl port-forward svc/redis-service 6379:6379"

echo "\n✈️ Airline Tickets Platform Ready!\n"
echo "🚀 Next steps:"
echo "   1. Deploy services: ./scripts/deploy-production.sh"
echo "   2. Check status: ./scripts/status-production.sh"
echo "   3. Access Kafka UI: kubectl port-forward svc/kafka-ui 8080:8080"
echo "   4. Access Grafana: kubectl port-forward svc/grafana 3000:3000"