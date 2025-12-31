.PHONY: up down ps logs logs-netbox shell-netbox superuser restart-netbox

up:
	 docker compose up -d

down:
	 docker compose down

ps:
	 docker compose ps

logs:
	 docker compose logs -f --tail=200

logs-netbox:
	 docker compose logs -f --tail=200 netbox

shell-netbox:
	 docker compose exec netbox bash

superuser:
	 docker compose exec netbox python /opt/netbox/netbox/manage.py createsuperuser

restart-netbox:
	 docker compose restart netbox netbox-worker
