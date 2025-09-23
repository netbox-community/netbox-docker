# README-INSTALL · NetBox-Docker on Portainer

> **Status:** Factory Reset durchgeführt – frischer Fork vom Original-Repo, Deployment neu gestartet. 

## 1) Portainer: Repository-Stack vorbereiten

**Portainer UI → Stacks → Add stack → Repository**

* **Git repository**: Unser geforktes `netbox-docker` Repository eintragen.
* **Repository reference**: Haupt-Branch wählen (z. B. `main`).
* **Compose path**: `docker-compose.yml` (oder gewünschtes Compose-File) setzen.
* **Enable relative path volumes**: aktivieren.
* **Base path**: `/var/docker` setzen.

---

Weitere Schritte folgen …
