# · NetBox-Docker on Portainer

> **Status:** User forked original netbox docker repository 

## 1) Portainer: Repository-Stack vorbereiten

**Portainer UI → Stacks → Add stack → Repository**

- **Git repository**: Unser geforktes `netbox-docker` Repository eintragen.
- **Repository reference**: Branch wählen (z. B. `main`).
- **Compose path**: `docker-compose.yml` 
- **Additional paths +Add file**: `docker-compose.override.yml`
- **Enable relative path volumes**: aktivieren.
- **Base path**: `/var/docker` als relative path setzen.

---

## 2) NetBox-Plugins

- `netbox-topology-views` (≥4.2.0, <5.0.0) – Interaktive L2/L3-Topologieansicht.
- `netbox-lifecycle` (≥1.1.0, <2.0.0) – Lifecycle-/EoX-Verwaltung für Geräte.
- `netbox-floorplan-plugin` (≥0.8.0) – Visualisierung von Racks/Assets in 2D-Gebäudeplänen.
- `pynetbox` (≥7.0.0) – Python-Client für die NetBox-API (benötigt für einige Plugins).
- `netbox-lists` – Flexible Listen-/Tabellenansichten für Objekte.
- `netbox-inventory` – Inventar- und Asset-Verwaltung in NetBox.
- `netbox-reorder-rack` – Intuitive Drag-and-Drop Reorganisation von Racks.
- `netboxlabs-diode-netbox-plugin` (z. B. v1.3.1 oder aktuellste Version) – Daten-Ingestion via Diode (vereinfacht Hinzufügen/Aktualisieren von Netzwerkdaten) :contentReference[oaicite:0]{index=0}  

**Temporär deaktiviert da Versionskonflikt (auskommentiert in `requirements-plugins.txt`):**
- `netbox-proxbox` (≥0.0.6b2) – Integration von Proxmox Clustern in NetBox.
- `proxbox-api` (≥0.0.2) – API-Helper für Proxbox.


### 2.1 Plugin-Installation mit netbox-docker
netbox-docker unterstützt eine separate **`requirements-plugins.txt`**, die beim Image-Build installiert wird.

### 2.2 `requirements-plugins.txt` 
```text
netbox-topology-views>=4.2.0,<5.0.0
netbox-lifecycle>=1.1.0,<2.0.0
netbox-floorplan-plugin>=0.8.0
pynetbox>=7.0.0
netbox-initializers>=4.4.0
netbox-lists
netbox-inventory
netbox-reorder-rack
# netbox-proxbox>=0.0.6b2
# proxbox-api>=0.0.2
```

### 2.3 `\configuration\plugin.py`
Die Plugins werden hier hinterlegt und konfiguriert.
```python
PLUGINS = [
    "netbox_inventory",
    "netbox_diode_plugin",
]

PLUGINS_CONFIG = {
    "netbox_inventory": {
        "sync_serial_to_device": True,
        "sync_asset_tag_to_device": True,
    },
    "netbox_diode_plugin": {
        "diode_target_override": "grpc://<dein-diode-server:port>/diode",
        "diode_username": "diode",
        "netbox_to_diode_client_secret": "changeme",
    },
}
```

## 3) Portainer Stack deploy

### 3.1 Admin User erstellen

Um einen ersten **Administrator-Account** (Superuser) anzulegen, kann der Befehl direkt im laufenden NetBox-Container ausgeführt werden.

**Command**
```bash
docker exec -it netbox-docker-netbox-1 \
  /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py createsuperuser
```

### 3.2 Defaults initialisieren

Der hinterlegte default value stack für netbox_initializers plugin

**Command**
```bash
docker exec -it netbox-docker-netbox-1   /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py   load_initializer_data --path /etc/netbox/config/initializers/extras
```