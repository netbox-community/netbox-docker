import os

PLUGINS = [
    "netbox_topology_views",
    "netbox_lifecycle",
    "netbox_floorplan",
    "netbox_lists",
    "netbox_inventory",
    "netbox_reorder_rack",
    "netbox_diode_plugin",
    "netbox_initializers",
    # "netbox_proxbox",
    "netbox_bgp",
    "netbox_dns",
]

# Hilfsvariable
diode_target = os.getenv("DIODE_GRPC_TARGET")

PLUGINS_CONFIG = {
    "netbox_inventory": {
        "sync_serial_to_device": True,
        "sync_asset_tag_to_device": True,
    },
    "netbox_diode_plugin": {
        "diode_target_override": diode_target,
        "diode_username": os.getenv("DIODE_USERNAME", "diode"),
        "netbox_to_diode_client_secret": os.getenv("NETBOX_TO_DIODE_CLIENT_SECRET"),
        "auth": {
            "issuer": diode_target.replace("grpc://", "http://") + "/auth",
        },
    },
    "netbox_bgp": {
        "top_level_menu": True,
    },
    "netbox_dns": {
        # Beispiele: IPAM-DNSsync o. Templates später konfigurierbar
    }
}
