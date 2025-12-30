# Onboarding - netbox-docker (Dev)

## Pré-requisitos
- Docker + Docker Compose instalados
- NetBox exposto em: **http://localhost:8001** (8001 -> 8080 no container)

## Subir o ambiente
### O que faz
Sobe Postgres + Redis/Cache + NetBox + Worker.

### Como rodar
```bash
docker compose up -d
