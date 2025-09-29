PLUGINS = [
    "netbox_topology_views",
    "netbox_lifecycle",
    "netbox_floorplan",
    "netbox_lists",
    "netbox_inventory",
    "netbox_reorder_rack",
    "netbox_diode_plugin",
    # "netbox_proxbox",
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
