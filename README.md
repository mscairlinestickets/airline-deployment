# ✈️ Airline Tickets - Kubernetes Deployment

Sistema de deployment para a plataforma de tickets aéreos usando Kubernetes, ArgoCD e observabilidade completa.

## 🏗️ Arquitetura

### Microserviços
- **🎫 Ticket Service** - Gerenciamento de tickets e voos
- **📋 Booking Service** - Sistema de reservas
- **🔐 Auth Service** - Autenticação e autorização OAuth2
- **💳 Payment Service** - Processamento de pagamentos
- **🌐 Edge Service** - API Gateway (Spring Cloud Gateway)

### Infraestrutura
- **🐘 PostgreSQL** - Banco de dados principal
- **🔴 Redis** - Cache e sessões
- **📨 Apache Kafka** - Mensageria assíncrona
- **📊 Stack de Observabilidade** - Grafana, Tempo, Loki, Fluent Bit

## 🚀 Quick Start

### Pré-requisitos
- Docker
- Minikube
- kubectl
- ArgoCD (opcional para produção)

### 1. Setup do Ambiente de Desenvolvimento
```bash
# Inicializar cluster completo com infraestrutura
./scripts/setup-development.sh

# Verificar status da infraestrutura
kubectl get pods
```

### 2. Deploy dos Microserviços
```bash
# Deploy de todos os serviços em produção
./scripts/deploy-production.sh

# Verificar status dos deployments
./scripts/status-production.sh
```

### 3. Acessar Serviços
```bash
# Kafka UI
kubectl port-forward svc/kafka-ui 8080:8080
# http://localhost:8080

# Grafana (Observabilidade)
kubectl port-forward svc/grafana 3000:3000
# http://localhost:3000

# PostgreSQL (para debug)
kubectl port-forward svc/postgres-service 5432:5432
```

## 📁 Estrutura do Projeto

```
airline-deployment/
├── kubernetes/
│   ├── applications/           # Configurações dos microserviços
│   │   ├── auth-service/
│   │   ├── booking-service/
│   │   ├── edge-service/
│   │   ├── payment-service/
│   │   └── ticket-service/
│   └── platform/
│       └── development/
│           └── services/       # Infraestrutura (DB, Cache, etc.)
├── docker/                     # Configurações Docker Compose
│   └── observability/         # Stack de monitoramento
└── scripts/                   # Scripts de automação
    ├── setup-development.sh   # Setup completo do ambiente
    ├── deploy-production.sh   # Deploy dos serviços
    ├── destroy-production.sh  # Cleanup dos serviços
    ├── status-production.sh   # Status dos deployments
    └── teardown-development.sh # Destruir ambiente completo
```

## 🔧 Configuração dos Serviços

### Recursos por Serviço
| Serviço | CPU Request | Memory Request | Min Replicas | Max Replicas |
|---------|-------------|----------------|--------------|--------------|
| Edge Service | 200m | 756Mi | 3 | 15 |
| Auth Service | 200m | 756Mi | 3 | 10 |
| Payment Service | 150m | 756Mi | 2 | 8 |
| Booking Service | 100m | 756Mi | 2 | 10 |
| Ticket Service | 100m | 756Mi | 2 | 10 |

### Variáveis de Ambiente por Serviço

#### Edge Service
```yaml
- BPL_JVM_THREAD_COUNT: "200"  # Gateway precisa de mais threads
- BOOKING_SERVICE_URI: http://booking-service:9002
- TICKET_SERVICE_URI: http://ticket-service:9001
- AUTH_SERVICE_URI: http://auth-service:9000
```

#### Auth Service
```yaml
- BPL_JVM_THREAD_COUNT: "100"
- JWT_ISSUER_URI: http://auth-service:9000
- REDIS_URI: redis://redis-service:6379
```

#### Payment Service
```yaml
- BPL_JVM_THREAD_COUNT: "100"
- STRIPE_API_KEY: (from secret)
- PAYMENT_WEBHOOK_SECRET: (from secret)
- MESSAGE_TOPIC: payment-processed
```

## 🔐 Secrets Management

### Secrets Criados Automaticamente
```bash
# PostgreSQL por serviço
postgres-ticket-credentials
postgres-booking-credentials
postgres-auth-credentials
postgres-payment-credentials

# OAuth2
oauth-resourceserver-secret
oauth-authserver-secret

# Cache
redis-credentials

# Payment Gateway
payment-gateway-secrets
```

## 📊 Observabilidade

### Stack Completa
- **📈 Grafana** - Dashboards e visualização
- **🔍 Tempo** - Distributed tracing
- **📋 Loki** - Agregação de logs
- **🚀 Fluent Bit** - Coleta de logs

### Dashboards Disponíveis
- Circuit Breaker metrics
- JVM performance
- Spring Cloud Gateway metrics
- Custom application metrics

### Tracing
Todos os serviços estão configurados com OpenTelemetry:
```yaml
JAVA_TOOL_OPTIONS: "-javaagent:/workspace/BOOT-INF/lib/opentelemetry-javaagent-1.33.3.jar"
OTEL_EXPORTER_OTLP_ENDPOINT: http://tempo.observability-stack.svc.cluster.local:4317
```

## 🔄 CI/CD com ArgoCD

### Aplicações ArgoCD
Cada serviço tem sua aplicação ArgoCD configurada:
- `ticket-service-prod`
- `booking-service-prod`
- `auth-service-prod`
- `payment-service-prod`
- `edge-service-prod`

### Sync Policy
```yaml
syncPolicy:
  automated:
    prune: true      # Remove recursos órfãos
    selfHeal: true   # Auto-correção de drift
```

## 🛠️ Comandos Úteis

### Desenvolvimento
```bash
# Logs de um serviço
kubectl logs -f deployment/ticket-service

# Escalar manualmente
kubectl scale deployment ticket-service --replicas=5

# Port forward para debug
kubectl port-forward svc/ticket-service 9001:9001

# Executar comando em pod
kubectl exec -it deployment/ticket-service -- /bin/bash
```

### Troubleshooting
```bash
# Verificar eventos
kubectl get events --sort-by=.metadata.creationTimestamp

# Verificar HPA
kubectl get hpa

# Verificar recursos
kubectl top pods
kubectl top nodes

# Verificar secrets
kubectl get secrets
```

### ArgoCD
```bash
# Acessar ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Sync manual de uma aplicação
kubectl patch application ticket-service-prod -n argocd --type merge -p '{"operation":{"sync":{}}}'
```

## 🔒 Segurança

### Práticas Implementadas
- **Secrets separados** por serviço e função
- **Resource limits** para evitar resource exhaustion
- **OAuth2** para autenticação entre serviços
- **Network policies** (recomendado implementar)
- **Pod Security Standards** (recomendado implementar)

### Melhorias Recomendadas
```bash
# Implementar Network Policies
kubectl apply -f security/network-policies.yaml

# Pod Security Standards
kubectl label namespace default pod-security.kubernetes.io/enforce=restricted
```

## 📈 Monitoramento e Alertas

### Métricas Importantes
- **CPU/Memory utilization** por serviço
- **Request rate** e **latency** no gateway
- **Database connections** e **query performance**
- **Payment processing** success rate
- **Circuit breaker** status

### Alertas Sugeridos
- Pod restart rate > threshold
- Memory usage > 80%
- Response time > 2s
- Error rate > 5%
- Payment failures > 1%

## 🚨 Disaster Recovery

### Backup Strategy
```bash
# Backup PostgreSQL
kubectl exec deployment/postgres -- pg_dump -U user ticketdb > backup.sql

# Backup secrets
kubectl get secrets -o yaml > secrets-backup.yaml
```

### Recovery
```bash
# Restore from backup
kubectl apply -f secrets-backup.yaml
kubectl exec -i deployment/postgres -- psql -U user ticketdb < backup.sql
```

## 🤝 Contribuição

### Adicionando Novo Serviço
1. Criar pasta em `kubernetes/applications/novo-service/production/`
2. Copiar estrutura de um serviço existente
3. Ajustar configurações específicas
4. Adicionar ao script de deploy
5. Testar em ambiente de desenvolvimento

### Padrões de Configuração
- **Naming**: `service-name` (kebab-case)
- **Resources**: Sempre definir requests, limits opcionais
- **Secrets**: Um secret por função/integração
- **HPA**: Configurar baseado no perfil de carga
- **Tracing**: Sempre habilitar OpenTelemetry

## 📞 Suporte

### Logs Importantes
```bash
# Aplicações
kubectl logs -f deployment/edge-service
kubectl logs -f deployment/auth-service

# Infraestrutura
kubectl logs -f deployment/postgres
kubectl logs -f deployment/kafka

# ArgoCD
kubectl logs -f deployment/argocd-application-controller -n argocd
```

### Contatos
- **DevOps Team**: devops@airline-tickets.com
- **Platform Team**: platform@airline-tickets.com

---

## 📝 Changelog

### v1.0.0 (2024-12-15)
- ✅ Setup inicial com 5 microserviços
- ✅ Infraestrutura completa (PostgreSQL, Redis, Kafka)
- ✅ Observabilidade com Grafana stack
- ✅ ArgoCD para CI/CD
- ✅ Scripts de automação
- ✅ Configurações de produção

---

**🎯 Airline Tickets Platform - Ready for Takeoff!** ✈️