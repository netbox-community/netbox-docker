# Specify one or more name and email address tuples representing NetBox administrators. These people will be notified of
# application errors (assuming correct email settings are provided).
# ADMINS = [
#     # ['John Doe', 'jdoe@example.com'],
# ]


# URL schemes that are allowed within links in NetBox
# ALLOWED_URL_SCHEMES = (
#     'file', 'ftp', 'ftps', 'http', 'https', 'irc', 'mailto', 'sftp', 'ssh', 'tel', 'telnet', 'tftp', 'vnc', 'xmpp',
# )


# NAPALM optional arguments (see http://napalm.readthedocs.io/en/latest/support/#optional-arguments). Arguments must
# be provided as a dictionary.
# NAPALM_ARGS = {}


# Enable installed plugins. Add the name of each plugin to the list.
# from netbox.configuration.configuration import PLUGINS
# PLUGINS.append('my_plugin')

# Plugins configuration settings. These settings are used by various plugins that the user may have installed.
# Each key in the dictionary is the name of an installed plugin and its value is a dictionary of settings.
# from netbox.configuration.configuration import PLUGINS_CONFIG
# PLUGINS_CONFIG['my_plugin'] = {
#   'foo': 'bar',
#   'buzz': 'bazz'
# }


# Remote authentication support
# REMOTE_AUTH_ENABLED = False
# REMOTE_AUTH_BACKEND = 'netbox.authentication.RemoteUserBackend'
# REMOTE_AUTH_HEADER = 'HTTP_REMOTE_USER'
# REMOTE_AUTH_AUTO_CREATE_USER = True
# REMOTE_AUTH_DEFAULT_GROUPS = []
# REMOTE_AUTH_DEFAULT_PERMISSIONS = {}


# By default uploaded media is stored on the local filesystem. Using Django-storages is also supported. Provide the
# class path of the storage driver in STORAGE_BACKEND and any configuration options in STORAGE_CONFIG. For example:
# STORAGE_BACKEND = 'storages.backends.s3boto3.S3Boto3Storage'
# STORAGE_CONFIG = {
#     'AWS_ACCESS_KEY_ID': 'Key ID',
#     'AWS_SECRET_ACCESS_KEY': 'Secret',
#     'AWS_STORAGE_BUCKET_NAME': 'netbox',
#     'AWS_S3_REGION_NAME': 'eu-west-1',
# }
