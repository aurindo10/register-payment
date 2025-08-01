# Deploy em Single VM com K3s

## Pré-requisitos na VM

- Ubuntu 20.04+ ou similar
- 4GB+ RAM recomendado
- Usuário com privilégios sudo
- Conexão com internet

**Nota**: Java 21, Maven e Docker serão instalados automaticamente pelo script

## 1. Setup Inicial da VM

```bash
# 1. Clonar o projeto
git clone <seu-repositorio>
cd register-payment

# 2. Executar setup completo (instala Java 21, Maven, Docker, K3s + registry local)
sudo chmod +x k3s-setup.sh
./k3s-setup.sh

# 3. Reiniciar sessão para aplicar grupos Docker (se necessário)
# logout && login  # ou usar 'newgrp docker'
```

## 2. Deploy da Aplicação

```bash
# 1. Entrar no diretório K8s
cd k8s

# 2. Executar deploy (build + push + deploy)
sudo chmod +x deploy.sh
./deploy.sh
```

## 3. Verificar Deploy

```bash
# Verificar pods
sudo k3s kubectl get pods -n payment-system

# Verificar services
sudo k3s kubectl get services -n payment-system

# Verificar logs
sudo k3s kubectl logs -f deployment/gateway-service -n payment-system
sudo k3s kubectl logs -f deployment/consumer-service -n payment-system
```

## 4. Acessar Aplicação

### Gateway Service (API)
```bash
# Descobrir IP do LoadBalancer ou NodePort
sudo k3s kubectl get services -n payment-system

# Testar API
curl http://<VM_IP>:<PORT>/api/v1/gateway/health
```

### RabbitMQ Management
```bash
# Port-forward para acessar RabbitMQ Management
sudo k3s kubectl port-forward service/rabbitmq-service 15672:15672 -n payment-system

# Acessar: http://<VM_IP>:15672
# User: guest, Password: guest
```

## 5. Comandos Úteis

### Monitoring
```bash
# Status do cluster
sudo k3s kubectl get nodes

# Status de todos os recursos
sudo k3s kubectl get all -n payment-system

# Logs de um pod específico
sudo k3s kubectl logs <pod-name> -n payment-system

# Exec em um pod
sudo k3s kubectl exec -it <pod-name> -n payment-system -- /bin/bash
```

### Troubleshooting
```bash
# Verificar registry local
docker ps | grep registry

# Reiniciar registry se necessário
docker restart registry

# Verificar imagens no registry
curl http://localhost:5000/v2/_catalog

# Deletar e recriar deployment
sudo k3s kubectl delete deployment gateway-service -n payment-system
sudo k3s kubectl apply -f gateway-service.yaml
```

### Scaling
```bash
# Escalar serviços
sudo k3s kubectl scale deployment gateway-service --replicas=3 -n payment-system
sudo k3s kubectl scale deployment consumer-service --replicas=2 -n payment-system
```

## 6. Persistência de Dados

Os dados do PostgreSQL e RabbitMQ são persistidos usando PersistentVolumes do K3s:

- PostgreSQL: `/var/lib/rancher/k3s/storage/`
- RabbitMQ: `/var/lib/rancher/k3s/storage/`

## 7. Backup e Restore

### Backup PostgreSQL
```bash
# Exec no pod do PostgreSQL
sudo k3s kubectl exec -it deployment/postgres -n payment-system -- pg_dump -U postgres optica-db > backup.sql
```

### Backup RabbitMQ
```bash
# Export definitions
sudo k3s kubectl exec -it deployment/rabbitmq -n payment-system -- rabbitmqctl export_definitions /tmp/definitions.json
```

## 8. Atualizações

Para atualizar a aplicação:

```bash
# 1. Build novas imagens
./build-images.sh

# 2. Tag e push para registry local
docker tag optica/gateway-service:latest localhost:5000/optica/gateway-service:latest
docker tag optica/consumer-service:latest localhost:5000/optica/consumer-service:latest
docker push localhost:5000/optica/gateway-service:latest
docker push localhost:5000/optica/consumer-service:latest

# 3. Restart deployments
sudo k3s kubectl rollout restart deployment/gateway-service -n payment-system
sudo k3s kubectl rollout restart deployment/consumer-service -n payment-system
```

## 9. Desinstalação

```bash
# Remover aplicação
sudo k3s kubectl delete namespace payment-system

# Remover K3s (opcional)
/usr/local/bin/k3s-uninstall.sh

# Remover registry (opcional)
docker stop registry && docker rm registry
```