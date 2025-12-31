# Onboarding - netbox-docker (Dev)

## Visão geral
Este repositório sobe o NetBox em ambiente de desenvolvimento usando Docker Compose.

**Acesso local:** http://localhost:8001  
(Porta `8001` no host → `8080` dentro do container `netbox`)

Serviços principais:
- `postgres` (banco)
- `redis` e `redis-cache` (cache/filas)
- `netbox` (web)
- `netbox-worker` (tarefas assíncronas)

---

## Pré-requisitos
- Docker + Docker Compose (comando `docker compose`)
- `curl` instalado
- Porta `8001` livre no host
- (Opcional) `make` para usar os atalhos do `Makefile`

---

## Arquivos importantes do projeto
- `docker-compose.yml`  
  Define os serviços, volumes, healthchecks e dependências.
- `docker-compose.override.yml`  
  Ajustes locais (ex.: mapeamento `8001:8080`).
- `env/*.env`  
  Variáveis de ambiente por serviço (dev).  
  **Boas práticas:** não reutilizar esses valores em produção; em produção use secrets/variáveis seguras.
- `Makefile`  
  Atalhos para os comandos mais usados.

Atalhos disponíveis no Makefile:
- `make up` / `make down` / `make ps`
- `make logs` / `make logs-netbox`
- `make shell-netbox`
- `make superuser`
- `make restart-netbox`
- `make db-shell`
- `make manage cmd=...`

---

## Subir o ambiente

### O que faz
Sobe Postgres + Redis + Redis-cache + NetBox + Worker em background.

### Quando usar
Primeira vez no dia, após reiniciar a máquina, ou depois de derrubar o ambiente.

### Como rodar
```bash
make up
# ou: dockerup
# ou: docker compose up -d
