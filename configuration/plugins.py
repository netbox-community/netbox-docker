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
]

PLUGINS_CONFIG = {
    "netbox_inventory": {
        "sync_serial_to_device": True,
        "sync_asset_tag_to_device": True,
    },
    "netbox_diode_plugin": {
        "diode_target_override": os.getenv("DIODE_GRPC_TARGET"),
        "diode_username": os.getenv("DIODE_USERNAME", "diode"),
        "netbox_to_diode_client_secret": os.getenv("NETBOX_TO_DIODE_CLIENT_SECRET"),
    },
}
