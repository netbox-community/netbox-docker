PLUGINS = [
    "netbox_topology_views",
    "netbox_lifecycle",
    "netbox_prometheus_sd",
    "netbox_qrcode",
    "netbox_floorplan",
    "netbox_proxbox",
    "netbox_otp",
    "netbox_lists",
    "netbox_inventory",
    "netbox_dns",
    "netbox_reorder_rack",
]

PLUGINS_CONFIG = {
    "netbox_inventory": {
        "sync_serial_to_device": True,
        "sync_asset_tag_to_device": True,
    },
    "netbox_otp": {
        # "enforce_otp": False,  # ggf. global erzwingen
    },
}
