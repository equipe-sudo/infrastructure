# Evidências — CyberVegas no Kubernetes (Minikube) + ArgoCD

**Entrega 03** · Equipe SUDO · Ambiente: Minikube local (driver Docker)

Aqui está a prova de que a aplicação CyberVegas (FastAPI + Angular + PostgreSQL)
roda integralmente dentro do cluster, com 2 réplicas, balanceamento de carga,
recriação automática de Pod e gerenciamento GitOps via ArgoCD.

---

## 1. Pods em execução (`kubectl get pods -o wide`)

Todos os componentes rodando dentro do cluster. Note as **2 réplicas** do
`backend` e do `frontend` (endereços IP distintos) e o `postgres` com PVC.

```
NAME                        READY   STATUS    RESTARTS       AGE     IP            NODE       NOMINATED NODE   READINESS GATES
backend-59b7bb54cc-6vplg    1/1     Running   0              58s     10.244.0.16   minikube   <none>           <none>
backend-59b7bb54cc-v6np2    1/1     Running   1 (6m5s ago)   6m19s   10.244.0.6    minikube   <none>           <none>
frontend-76b5955f44-jg6d4   1/1     Running   0              6m19s   10.244.0.3    minikube   <none>           <none>
frontend-76b5955f44-r9b5h   1/1     Running   0              6m19s   10.244.0.4    minikube   <none>           <none>
postgres-767dd77bbb-hrz7g   1/1     Running   0              6m19s   10.244.0.7    minikube   <none>           <none>
```

## 2. Services (`kubectl get services`)

```
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
backend      ClusterIP   10.106.26.195    <none>        8000/TCP       6m19s
frontend     NodePort    10.103.152.188   <none>        80:32206/TCP   6m19s
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP        11m
postgres     ClusterIP   10.96.94.60      <none>        5432/TCP       6m19s
```

- `backend` e `postgres` são **ClusterIP** (só acessíveis dentro do cluster).
- `frontend` é **NodePort** (32206) — exposto para acesso pelo navegador.

## 3. Deployments (`kubectl get deployments`)

```
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
backend    2/2     2            2           6m19s
frontend   2/2     2            2           6m19s
postgres   1/1     1            1           6m19s
```

## 4. Persistência (`kubectl get pvc`)

```
NAME            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
postgres-data   Bound    pvc-a8fd8755-af47-419f-8b7b-7c9cbc6defa7   1Gi        RWO            standard       6m19s
```

O PostgreSQL grava em um PersistentVolumeClaim, ou seja, os dados sobrevivem à
recriação do Pod.

## 5. ConfigMap e Secret

```
$ kubectl get configmap cybervegas-config
$ kubectl get secret cybervegas-secrets
```

O `ConfigMap` guarda `SALDO_INICIAL`, `ENVIRONMENT` e `ALLOW_SQLITE_FALLBACK=false`;
o `Secret` guarda as credenciais do PostgreSQL e a `DATABASE_URL`.

## 6. Aplicação funcionando (requisições reais)

Acessada pelo proxy do nginx (frontend → backend → PostgreSQL):

```
GET /api/           → {"status":"online","mensagem":"Cyber Vegas API está no ar 🎰","versao":"1.1.0"}
GET /api/saldo      → {"saldo":100.0,"mensagem":"Saldo consultado com sucesso."}
GET /api/version    → {"api":"Cyber Vegas API","versao":"1.1.0"}
GET /health         → {"status":"ok"}
GET /health/ready   → {"status":"ready","database":"connected"}
```

O `database:"connected"` prova que o backend está no **PostgreSQL** (não no
fallback SQLite). A captura de tela da interface Angular está em
[`app-executando.png`](app-executando.png).

## 7. Balanceamento de carga entre os 2 Pods do backend

```
$ kubectl get endpoints backend
NAME      ENDPOINTS                         AGE
backend   10.244.0.5:8000,10.244.0.6:8000   4m49s
```

30 requisições a `http://backend:8000/saldo` disparadas **de dentro do cluster**
(contra o Service, para o kube-proxy balancear) — distribuição vista nos logs:

```
28  backend-59b7bb54cc-4b677
19  backend-59b7bb54cc-v6np2
```

Os dois Pods atenderam tráfego (round-robin do Service).

## 8. Recriação automática de um Pod

```
$ kubectl delete pod backend-59b7bb54cc-4b677 --grace-period=0 --force

# imediatamente após — o Deployment cria um Pod substituto:
backend-59b7bb54cc-6vplg   0/1   Running   0   2s    10.244.0.16

# segundos depois — novo Pod pronto (IP novo, confirmando que é outro Pod):
backend-59b7bb54cc-6vplg   1/1   Running   0   7s    10.244.0.16
backend-59b7bb54cc-v6np2   1/1   Running   1   5m28s 10.244.0.6
```

O **Deployment** reestabeleceu o estado desejado (2 réplicas) sem intervenção.

## 9. ArgoCD — GitOps

```
$ kubectl -n argocd get application cybervegas
NAME         SYNC STATUS   HEALTH STATUS
cybervegas   Synced        Healthy
```

A `Application` aponta para `equipe-sudo/infrastructure` (diretório `k8s/`).
O ArgoCD clonou o repositório (privado, via Service Token) e confirmou que o
cluster bate com o estado declarado no Git — `Synced` e `Healthy`.

Pods do ArgoCD (todos no namespace `argocd`): `application-controller`,
`applicationset-controller`, `dex-server`, `notifications-controller`, `redis`,
`repo-server` e `server`.

---

## Comandos usados (resumo)

```bash
minikube start --driver=docker
minikube image build -t cybervegas-backend:latest  ../backend
minikube image build -t cybervegas-frontend:latest ../frontend

cd kubernetes && terraform init && terraform apply

kubectl get pods -o wide
kubectl get services
kubectl get deployments
kubectl get endpoints backend
kubectl delete pod -l app=backend
```
