# · NetBox-Docker on Portainer

> **Status:** User forked original netbox docker repository 

## 1) Portainer: Repository-Stack vorbereiten

**Portainer UI → Stacks → Add stack → Repository**

- **Git repository**: Unser geforktes `netbox-docker` Repository eintragen.
- **Repository reference**: Branch wählen (z. B. `main`).
- **Compose path**: `docker-compose.yml` 
- **Enable relative path volumes**: aktivieren.
- **Base path**: `/var/docker` als relative path setzen.

---

## 2) NetBox-Plugins

- `netbox-topology-views` – Interaktive L2/L3-Topologieansicht.
- `netbox-device-lifecycle-mgmt` – Lifecycle-/EoX-Verwaltung für Geräte.
- `netbox-plugin-prometheus-sd` – Service Discovery für Prometheus.
- `netbox-qrcode` – QR-Codes für Objekte (Inventar/Asset-Labels).

### 2.1 Plugin-Installation mit netbox-docker
netbox-docker unterstützt eine separate **`requirements-plugins.txt`**, die beim Image-Build installiert wird.

### 2.2 `requirements-plugins.txt` 
```text
# Versions bewusst pinned
netbox-topology-views>=4.2.0,<5.0.0
netbox-device-lifecycle-mgmt>=1.1.0,<2.0.0
netbox-plugin-prometheus-sd>=0.3.0,<1.0.0
netbox-qrcode>=0.0.17,<1.0.0
```

## 3) Portainer Stack deploy

### 3.1 Admin User erstellen

Um einen ersten **Administrator-Account** (Superuser) anzulegen, kann der Befehl direkt im laufenden NetBox-Container ausgeführt werden.

**Command (copy-fähig):**
```bash
docker compose exec netbox python3 /opt/netbox/netbox/manage.py createsuperuser
```
