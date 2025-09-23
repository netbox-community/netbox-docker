# README-INSTALL · NetBox-Docker on Portainer

> **Status:** Factory Reset durchgeführt – frischer Fork vom Original-Repo, Deployment neu gestartet. 

## 1) Portainer: Repository-Stack vorbereiten

**Portainer UI → Stacks → Add stack → Repository**

* **Git repository**: User forked `netbox-docker` Repository 
* **Repository reference**: main branch
* **Compose path**: `docker-compose.yml` 
* **Enable relative path volumes**: aktivieren.
* **Base path**: `/var/docker` als relative path setzen.

---