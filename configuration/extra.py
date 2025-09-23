####
## This file contains extra configuration options that can't be configured
## directly through environment variables.
####

## Specify one or more name and email address tuples representing NetBox administrators. These people will be notified of
## application errors (assuming correct email settings are provided).
# ADMINS = [
#     # ['John Doe', 'jdoe@example.com'],
# ]


## URL schemes that are allowed within links in NetBox
# ALLOWED_URL_SCHEMES = (
#     'file', 'ftp', 'ftps', 'http', 'https', 'irc', 'mailto', 'sftp', 'ssh', 'tel', 'telnet', 'tftp', 'vnc', 'xmpp',
# )

## Enable installed plugins. Add the name of each plugin to the list.
# from netbox.configuration.configuration import PLUGINS
# PLUGINS.append('my_plugin')

## Plugins configuration settings. These settings are used by various plugins that the user may have installed.
## Each key in the dictionary is the name of an installed plugin and its value is a dictionary of settings.
# from netbox.configuration.configuration import PLUGINS_CONFIG
# PLUGINS_CONFIG['my_plugin'] = {
#   'foo': 'bar',
#   'buzz': 'bazz'
# }


## Remote authentication support
# REMOTE_AUTH_DEFAULT_PERMISSIONS = {}


## By default uploaded media is stored on the local filesystem. Using Django-storages is also supported. Provide the
## class path of the storage driver in STORAGE_BACKEND and any configuration options in STORAGE_CONFIG. For example:
# STORAGE_BACKEND = 'storages.backends.s3boto3.S3Boto3Storage'
# STORAGE_CONFIG = {
#     'AWS_ACCESS_KEY_ID': 'Key ID',
#     'AWS_SECRET_ACCESS_KEY': 'Secret',
#     'AWS_STORAGE_BUCKET_NAME': 'netbox',
#     'AWS_S3_REGION_NAME': 'eu-west-1',
# }


## This file can contain arbitrary Python code, e.g.:
# from datetime import datetime
# now = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
# BANNER_TOP = f'<marquee width="200px">This instance started on {now}.</marquee>'

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

from netbox.configuration.configuration import PLUGINS, PLUGINS_CONFIG

PLUGINS += [
    'netbox_topology_views',
    'netbox_device_lifecycle_mgmt',
    'netbox_prometheus_sd',
    'netbox_qrcode',
]

PLUGINS_CONFIG.update({
    # NetBox Topology Views
    'netbox_topology_views': {
        # Beispiel: Standard-Layout für Graphen
        'default_device_bay_parent': True,
        'exclude_virtual_interfaces': True,
    },

    # Device Lifecycle Management
    'netbox_device_lifecycle_mgmt': {
        # Tage vor EoX-Benachrichtigung
        'expiry_notice_days': 180,
    },

    # Prometheus Service Discovery
    'netbox_prometheus_sd': {
        # Export-Path (innerhalb des Containers erreichbar)
        'path': '/etc/netbox/prometheus-sd',
        'reload_command': None,  # oder z. B. 'systemctl reload prometheus'
    },

    # QRCode
    'netbox_qrcode': {
        'qr_code_size': 8,  # 1–10, bestimmt Pixelgröße
        'qr_code_border': 4,
        'qr_code_error_correction': 'M',  # L, M, Q, H
    },
})
