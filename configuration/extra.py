####
## configuration/extra.py
####

# Zusätzliche Status-Felder für IP-Adressen
FIELD_CHOICES = {
    'ipam.IPAddress.status': (
        ('free',       'Free',       'lime'),
        ('deprecated', 'Deprecated', 'red'),
        ('reserved',   'Reserved',   'yellow'),
        ('dhcp',       'DHCP',       'blue'),
        ('active',     'Active',     'cyan'),
        ('gateway',    'Gateway',    'darkkhaki'),
    )
}

# Plugins initialisieren, falls nicht vorhanden
try:
    PLUGINS
except NameError:
    PLUGINS = []

try:
    PLUGINS_CONFIG
except NameError:
    PLUGINS_CONFIG = {}

# Plugins anhängen
PLUGINS += [
    'netbox_topology_views',
    'netbox_device_lifecycle_mgmt',
    'netbox_prometheus_sd',
    'netbox_qrcode',
]

PLUGINS_CONFIG.update({
    'netbox_topology_views': {
        'default_device_bay_parent': True,
        'exclude_virtual_interfaces': True,
    },
    'netbox_device_lifecycle_mgmt': {
        'expiry_notice_days': 180,
    },
    'netbox_prometheus_sd': {
        'path': '/etc/netbox/prometheus-sd',
        'reload_command': None,
    },
    'netbox_qrcode': {
        'qr_code_size': 8,
        'qr_code_border': 4,
        'qr_code_error_correction': 'M',
    },
})
