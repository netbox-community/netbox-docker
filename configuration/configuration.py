####
## We recommend to not edit this file.
## Create separate files to overwrite the settings.
## See `extra.py` as an example.
####

import re
from os import environ
from os.path import abspath, dirname, join
from typing import Any, Callable, Tuple

# For reference see https://docs.netbox.dev/en/stable/configuration/
# Based on https://github.com/netbox-community/netbox/blob/develop/netbox/netbox/configuration_example.py

###
# NetBox-Docker Helper functions
###

# Read secret from file
def _read_secret(secret_name: str, default: str | None = None) -> str | None:
    try:
        f = open('/run/secrets/' + secret_name, 'r', encoding='utf-8')
    except EnvironmentError:
        return default
    else:
        with f:
            return f.readline().strip()

# If the `map_fn` isn't defined, then the value that is read from the environment (or the default value if not found) is returned.
# If the `map_fn` is defined, then `map_fn` is invoked and the value (that was read from the environment or the default value if not found)
# is passed to it as a parameter. The value returned from `map_fn` is then the return value of this function.
# The `map_fn` is not invoked, if the value (that was read from the environment or the default value if not found) is None.
def _environ_get_and_map(variable_name: str, default: str | None = None, map_fn: Callable[[str], Any | None] = None) -> Any | None:
    env_value = environ.get(variable_name, default)

    if env_value == None:
        return env_value

    if not map_fn:
        return env_value
    
    return map_fn(env_value)

_AS_BOOL = lambda value : value.lower() == 'true'
_AS_INT = lambda value : int(value)
_AS_LIST = lambda value : list(filter(None, value.split(' ')))

_BASE_DIR = dirname(dirname(abspath(__file__)))

#########################
#                       #
#   Required settings   #
#                       #
#########################

# This is a list of valid fully-qualified domain names (FQDNs) for the NetBox server. NetBox will not permit write
# access to the server via any other hostnames. The first FQDN in the list will be treated as the preferred name.
#
# Example: ALLOWED_HOSTS = ['netbox.example.com', 'netbox.internal.local']
ALLOWED_HOSTS = environ.get('ALLOWED_HOSTS', '*').split(' ')
# ensure that '*' or 'localhost' is always in ALLOWED_HOSTS (needed for health checks)
if '*' not in ALLOWED_HOSTS and 'localhost' not in ALLOWED_HOSTS:
    ALLOWED_HOSTS.append('localhost')

# PostgreSQL database configuration. See the Django documentation for a complete list of available parameters:
#   https://docs.djangoproject.com/en/stable/ref/settings/#databases
DATABASE = {
    'NAME': environ.get('DB_NAME', 'netbox'),       # Database name
    'USER': environ.get('DB_USER', ''),             # PostgreSQL username
    'PASSWORD': _read_secret('db_password', environ.get('DB_PASSWORD', '')),
                                                    # PostgreSQL password
    'HOST': environ.get('DB_HOST', 'localhost'),    # Database server
    'PORT': environ.get('DB_PORT', ''),             # Database port (leave blank for default)
    'OPTIONS': {'sslmode': environ.get('DB_SSLMODE', 'prefer')},
                                                    # Database connection SSLMODE
    'CONN_MAX_AGE': _environ_get_and_map('DB_CONN_MAX_AGE', '300', _AS_INT),
                                                    # Max database connection age
    'DISABLE_SERVER_SIDE_CURSORS': _environ_get_and_map('DB_DISABLE_SERVER_SIDE_CURSORS', 'False', _AS_BOOL),
                                                    # Disable the use of server-side cursors transaction pooling
}

# Redis database settings. Redis is used for caching and for queuing background tasks such as webhook events. A separate
# configuration exists for each. Full connection details are required in both sections, and it is strongly recommended
# to use two separate database IDs.
REDIS = {
    'tasks': {
        'HOST': environ.get('REDIS_HOST', 'localhost'),
        'PORT': _environ_get_and_map('REDIS_PORT', 6379, _AS_INT),
        'SENTINELS': [tuple(uri.split(':')) for uri in _environ_get_and_map('REDIS_SENTINELS', '', _AS_LIST) if uri != ''],
        'SENTINEL_SERVICE': environ.get('REDIS_SENTINEL_SERVICE', 'default'),
        'SENTINEL_TIMEOUT': _environ_get_and_map('REDIS_SENTINEL_TIMEOUT', 10, _AS_INT),
        'USERNAME': environ.get('REDIS_USERNAME', ''),
        'PASSWORD': _read_secret('redis_password', environ.get('REDIS_PASSWORD', '')),
        'DATABASE': _environ_get_and_map('REDIS_DATABASE', 0, _AS_INT),
        'SSL': _environ_get_and_map('REDIS_SSL', 'False', _AS_BOOL),
        'INSECURE_SKIP_TLS_VERIFY': _environ_get_and_map('REDIS_INSECURE_SKIP_TLS_VERIFY', 'False', _AS_BOOL),
    },
    'caching': {
        'HOST': environ.get('REDIS_CACHE_HOST', environ.get('REDIS_HOST', 'localhost')),
        'PORT': _environ_get_and_map('REDIS_CACHE_PORT', environ.get('REDIS_PORT', '6379'), _AS_INT),
        'SENTINELS': [tuple(uri.split(':')) for uri in _environ_get_and_map('REDIS_CACHE_SENTINELS', '', _AS_LIST) if uri != ''],
        'SENTINEL_SERVICE': environ.get('REDIS_CACHE_SENTINEL_SERVICE', environ.get('REDIS_SENTINEL_SERVICE', 'default')),
        'USERNAME': environ.get('REDIS_CACHE_USERNAME', environ.get('REDIS_USERNAME', '')),
        'PASSWORD': _read_secret('redis_cache_password', environ.get('REDIS_CACHE_PASSWORD', environ.get('REDIS_PASSWORD', ''))),
        'DATABASE': _environ_get_and_map('REDIS_CACHE_DATABASE', '1', _AS_INT),
        'SSL': _environ_get_and_map('REDIS_CACHE_SSL', environ.get('REDIS_SSL', 'False'), _AS_BOOL),
        'INSECURE_SKIP_TLS_VERIFY': _environ_get_and_map('REDIS_CACHE_INSECURE_SKIP_TLS_VERIFY', environ.get('REDIS_INSECURE_SKIP_TLS_VERIFY', 'False'), _AS_BOOL),
    },
}

# This key is used for secure generation of random numbers and strings. It must never be exposed outside of this file.
# For optimal security, SECRET_KEY should be at least 50 characters in length and contain a mix of letters, numbers, and
# symbols. NetBox will not run without this defined. For more information, see
# https://docs.djangoproject.com/en/stable/ref/settings/#std:setting-SECRET_KEY
SECRET_KEY = _read_secret('secret_key', environ.get('SECRET_KEY', ''))


#########################
#                       #
#   Optional settings   #
#                       #
#########################

# # Specify one or more name and email address tuples representing NetBox administrators. These people will be notified of
# # application errors (assuming correct email settings are provided).
# ADMINS = [
#    # ['John Doe', 'jdoe@example.com'],
# ]

if 'ALLOWED_URL_SCHEMES' in environ:
    ALLOWED_URL_SCHEMES = _environ_get_and_map('ALLOWED_URL_SCHEMES', None, _AS_LIST)

# Optionally display a persistent banner at the top and/or bottom of every page. HTML is allowed. To display the same
# content in both banners, define BANNER_TOP and set BANNER_BOTTOM = BANNER_TOP.
if 'BANNER_TOP' in environ:
    BANNER_TOP = environ.get('BANNER_TOP', None)
if 'BANNER_BOTTOM' in environ:
    BANNER_BOTTOM = environ.get('BANNER_BOTTOM', None)

# Text to include on the login page above the login form. HTML is allowed.
if 'BANNER_LOGIN' in environ:
    BANNER_LOGIN = environ.get('BANNER_LOGIN', None)

# Maximum number of days to retain logged changes. Set to 0 to retain changes indefinitely. (Default: 90)
if 'CHANGELOG_RETENTION' in environ:
    CHANGELOG_RETENTION = _environ_get_and_map('CHANGELOG_RETENTION', None, _AS_INT)

# Maximum number of days to retain job results (scripts and reports). Set to 0 to retain job results in the database indefinitely. (Default: 90)
if 'JOB_RETENTION' in environ:
    JOB_RETENTION = _environ_get_and_map('JOB_RETENTION', None, _AS_INT)
# JOBRESULT_RETENTION was renamed to JOB_RETENTION in the v3.5.0 release of NetBox. For backwards compatibility, map JOBRESULT_RETENTION to JOB_RETENTION
elif 'JOBRESULT_RETENTION' in environ:
    JOB_RETENTION = _environ_get_and_map('JOBRESULT_RETENTION', None, _AS_INT)

# API Cross-Origin Resource Sharing (CORS) settings. If CORS_ORIGIN_ALLOW_ALL is set to True, all origins will be
# allowed. Otherwise, define a list of allowed origins using either CORS_ORIGIN_WHITELIST or
# CORS_ORIGIN_REGEX_WHITELIST. For more information, see https://github.com/ottoyiu/django-cors-headers
CORS_ORIGIN_ALLOW_ALL = _environ_get_and_map('CORS_ORIGIN_ALLOW_ALL', 'False', _AS_BOOL)
CORS_ORIGIN_WHITELIST = _environ_get_and_map('CORS_ORIGIN_WHITELIST', 'https://localhost', _AS_LIST)
CORS_ORIGIN_REGEX_WHITELIST = [re.compile(r) for r in _environ_get_and_map('CORS_ORIGIN_REGEX_WHITELIST', '', _AS_LIST)]

# Set to True to enable server debugging. WARNING: Debugging introduces a substantial performance penalty and may reveal
# sensitive information about your installation. Only enable debugging while performing testing.
# Never enable debugging on a production system.
DEBUG = _environ_get_and_map('DEBUG', 'False', _AS_BOOL)

# This parameter serves as a safeguard to prevent some potentially dangerous behavior,
# such as generating new database schema migrations.
# Set this to True only if you are actively developing the NetBox code base.
DEVELOPER = _environ_get_and_map('DEVELOPER', 'False', _AS_BOOL)

# Email settings
EMAIL = {
    'SERVER': environ.get('EMAIL_SERVER', 'localhost'),
    'PORT': _environ_get_and_map('EMAIL_PORT', 25, _AS_INT),
    'USERNAME': environ.get('EMAIL_USERNAME', ''),
    'PASSWORD': _read_secret('email_password', environ.get('EMAIL_PASSWORD', '')),
    'USE_SSL': _environ_get_and_map('EMAIL_USE_SSL', 'False', _AS_BOOL),
    'USE_TLS': _environ_get_and_map('EMAIL_USE_TLS', 'False', _AS_BOOL),
    'SSL_CERTFILE': environ.get('EMAIL_SSL_CERTFILE', ''),
    'SSL_KEYFILE': environ.get('EMAIL_SSL_KEYFILE', ''),
    'TIMEOUT': _environ_get_and_map('EMAIL_TIMEOUT', 10, _AS_INT),  # seconds
    'FROM_EMAIL': environ.get('EMAIL_FROM', ''),
}

# Enforcement of unique IP space can be toggled on a per-VRF basis. To enforce unique IP space within the global table
# (all prefixes and IP addresses not assigned to a VRF), set ENFORCE_GLOBAL_UNIQUE to True.
if 'ENFORCE_GLOBAL_UNIQUE' in environ:
    ENFORCE_GLOBAL_UNIQUE = _environ_get_and_map('ENFORCE_GLOBAL_UNIQUE', None, _AS_BOOL)

# By default, netbox sends census reporting data using a single HTTP request each time a worker starts.
# This data enables the project maintainers to estimate how many NetBox deployments exist and track the adoption of new versions over time.
# The only data reported by this function are the NetBox version, Python version, and a pseudorandom unique identifier.
# To opt out of census reporting, set CENSUS_REPORTING_ENABLED to False.
if 'CENSUS_REPORTING_ENABLED' in environ:
    CENSUS_REPORTING_ENABLED = _environ_get_and_map('CENSUS_REPORTING_ENABLED', None, _AS_BOOL)

# Exempt certain models from the enforcement of view permissions. Models listed here will be viewable by all users and
# by anonymous users. List models in the form `<app>.<model>`. Add '*' to this list to exempt all models.
EXEMPT_VIEW_PERMISSIONS = _environ_get_and_map('EXEMPT_VIEW_PERMISSIONS', '', _AS_LIST)

# HTTP proxies NetBox should use when sending outbound HTTP requests (e.g. for webhooks).
HTTP_PROXIES = {
    'http': environ.get('HTTP_PROXY', None),
    'https': environ.get('HTTPS_PROXY', None),
}

# IP addresses recognized as internal to the system. The debugging toolbar will be available only to clients accessing
# NetBox from an internal IP.
INTERNAL_IPS = _environ_get_and_map('INTERNAL_IPS', '127.0.0.1 ::1', _AS_LIST)

# Enable GraphQL API.
if 'GRAPHQL_ENABLED' in environ:
    GRAPHQL_ENABLED = _environ_get_and_map('GRAPHQL_ENABLED', None, _AS_BOOL)

# # Enable custom logging. Please see the Django documentation for detailed guidance on configuring custom logs:
# #   https://docs.djangoproject.com/en/stable/topics/logging/
# LOGGING = {}

# Automatically reset the lifetime of a valid session upon each authenticated request. Enables users to remain
# authenticated to NetBox indefinitely.
LOGIN_PERSISTENCE = _environ_get_and_map('LOGIN_PERSISTENCE', 'False', _AS_BOOL)

# When enabled, only authenticated users are permitted to access any part of NetBox.
# Disabling this will allow unauthenticated users to access most areas of NetBox (but not make any changes).
LOGIN_REQUIRED = _environ_get_and_map('LOGIN_REQUIRED', 'True', _AS_BOOL)

# The length of time (in seconds) for which a user will remain logged into the web UI before being prompted to
# re-authenticate. (Default: 1209600 [14 days])
LOGIN_TIMEOUT = _environ_get_and_map('LOGIN_TIMEOUT', 1209600, _AS_INT)

# Setting this to True will display a "maintenance mode" banner at the top of every page.
if 'MAINTENANCE_MODE' in environ:
    MAINTENANCE_MODE = _environ_get_and_map('MAINTENANCE_MODE', None, _AS_BOOL)

# Maps provider
if 'MAPS_URL' in environ:
    MAPS_URL = environ.get('MAPS_URL', None)

# An API consumer can request an arbitrary number of objects =by appending the "limit" parameter to the URL (e.g.
# "?limit=1000"). This setting defines the maximum limit. Setting it to 0 or None will allow an API consumer to request
# all objects by specifying "?limit=0".
if 'MAX_PAGE_SIZE' in environ:
    MAX_PAGE_SIZE = _environ_get_and_map('MAX_PAGE_SIZE', None, _AS_INT)

# The file path where uploaded media such as image attachments are stored. A trailing slash is not needed. Note that
# the default value of this setting is derived from the installed location.
MEDIA_ROOT = environ.get('MEDIA_ROOT', join(_BASE_DIR, 'media'))

# Expose Prometheus monitoring metrics at the HTTP endpoint '/metrics'
METRICS_ENABLED = _environ_get_and_map('METRICS_ENABLED', 'False', _AS_BOOL)

# Determine how many objects to display per page within a list. (Default: 50)
if 'PAGINATE_COUNT' in environ:
    PAGINATE_COUNT = _environ_get_and_map('PAGINATE_COUNT', None, _AS_INT)

# # Enable installed plugins. Add the name of each plugin to the list.
# PLUGINS = []

# # Plugins configuration settings. These settings are used by various plugins that the user may have installed.
# # Each key in the dictionary is the name of an installed plugin and its value is a dictionary of settings.
# PLUGINS_CONFIG = {
# }

# When determining the primary IP address for a device, IPv6 is preferred over IPv4 by default. Set this to True to
# prefer IPv4 instead.
if 'PREFER_IPV4' in environ:
    PREFER_IPV4 = _environ_get_and_map('PREFER_IPV4', None, _AS_BOOL)

# The default value for the amperage field when creating new power feeds.
if 'POWERFEED_DEFAULT_AMPERAGE' in environ:
    POWERFEED_DEFAULT_AMPERAGE = _environ_get_and_map('POWERFEED_DEFAULT_AMPERAGE', None, _AS_INT)

# The default value (percentage) for the max_utilization field when creating new power feeds.
if 'POWERFEED_DEFAULT_MAX_UTILIZATION' in environ:
    POWERFEED_DEFAULT_MAX_UTILIZATION = _environ_get_and_map('POWERFEED_DEFAULT_MAX_UTILIZATION', None, _AS_INT)

# The default value for the voltage field when creating new power feeds.
if 'POWERFEED_DEFAULT_VOLTAGE' in environ:
    POWERFEED_DEFAULT_VOLTAGE = _environ_get_and_map('POWERFEED_DEFAULT_VOLTAGE', None, _AS_INT)

# Rack elevation size defaults, in pixels. For best results, the ratio of width to height should be roughly 10:1.
if 'RACK_ELEVATION_DEFAULT_UNIT_HEIGHT' in environ:
    RACK_ELEVATION_DEFAULT_UNIT_HEIGHT = _environ_get_and_map('RACK_ELEVATION_DEFAULT_UNIT_HEIGHT', None, _AS_INT)
if 'RACK_ELEVATION_DEFAULT_UNIT_WIDTH' in environ:
    RACK_ELEVATION_DEFAULT_UNIT_WIDTH = _environ_get_and_map('RACK_ELEVATION_DEFAULT_UNIT_WIDTH', None, _AS_INT)

# Remote authentication support
REMOTE_AUTH_AUTO_CREATE_GROUPS = _environ_get_and_map('REMOTE_AUTH_AUTO_CREATE_GROUPS', 'False', _AS_BOOL)
REMOTE_AUTH_AUTO_CREATE_USER = _environ_get_and_map('REMOTE_AUTH_AUTO_CREATE_USER', 'False', _AS_BOOL)
REMOTE_AUTH_BACKEND = _environ_get_and_map('REMOTE_AUTH_BACKEND', 'netbox.authentication.RemoteUserBackend', _AS_LIST)
REMOTE_AUTH_DEFAULT_GROUPS = _environ_get_and_map('REMOTE_AUTH_DEFAULT_GROUPS', '', _AS_LIST)
# REMOTE_AUTH_DEFAULT_PERMISSIONS = {} # dicts can't be configured via environment variables. See extra.py instead.
REMOTE_AUTH_ENABLED = _environ_get_and_map('REMOTE_AUTH_ENABLED', 'False', _AS_BOOL)
REMOTE_AUTH_GROUP_HEADER = _environ_get_and_map('REMOTE_AUTH_GROUP_HEADER', 'HTTP_REMOTE_USER_GROUP')
REMOTE_AUTH_GROUP_SEPARATOR = _environ_get_and_map('REMOTE_AUTH_GROUP_SEPARATOR', '|')
REMOTE_AUTH_GROUP_SYNC_ENABLED = _environ_get_and_map('REMOTE_AUTH_GROUP_SYNC_ENABLED', 'False', _AS_BOOL)
REMOTE_AUTH_HEADER = environ.get('REMOTE_AUTH_HEADER', 'HTTP_REMOTE_USER')
REMOTE_AUTH_USER_EMAIL = environ.get('REMOTE_AUTH_USER_EMAIL', 'HTTP_REMOTE_USER_EMAIL')
REMOTE_AUTH_USER_FIRST_NAME = environ.get('REMOTE_AUTH_USER_FIRST_NAME', 'HTTP_REMOTE_USER_FIRST_NAME')
REMOTE_AUTH_USER_LAST_NAME = environ.get('REMOTE_AUTH_USER_LAST_NAME', 'HTTP_REMOTE_USER_LAST_NAME')
REMOTE_AUTH_SUPERUSER_GROUPS = _environ_get_and_map('REMOTE_AUTH_SUPERUSER_GROUPS', '', _AS_LIST)
REMOTE_AUTH_SUPERUSERS = _environ_get_and_map('REMOTE_AUTH_SUPERUSERS', '', _AS_LIST)
REMOTE_AUTH_STAFF_GROUPS = _environ_get_and_map('REMOTE_AUTH_STAFF_GROUPS', '', _AS_LIST)
REMOTE_AUTH_STAFF_USERS = _environ_get_and_map('REMOTE_AUTH_STAFF_USERS', '', _AS_LIST)

# This repository is used to check whether there is a new release of NetBox available. Set to None to disable the
# version check or use the URL below to check for release in the official NetBox repository.
RELEASE_CHECK_URL = environ.get('RELEASE_CHECK_URL', None)
# RELEASE_CHECK_URL = 'https://api.github.com/repos/netbox-community/netbox/releases'

# Maximum execution time for background tasks, in seconds.
RQ_DEFAULT_TIMEOUT = _environ_get_and_map('RQ_DEFAULT_TIMEOUT', 300, _AS_INT)

# The name to use for the csrf token cookie.
CSRF_COOKIE_NAME = environ.get('CSRF_COOKIE_NAME', 'csrftoken')

# Cross-Site-Request-Forgery-Attack settings. If Netbox is sitting behind a reverse proxy, you might need to set the CSRF_TRUSTED_ORIGINS flag.
# Django 4.0 requires to specify the URL Scheme in this setting. An example environment variable could be specified like:
# CSRF_TRUSTED_ORIGINS=https://demo.netbox.dev http://demo.netbox.dev
CSRF_TRUSTED_ORIGINS = _environ_get_and_map('CSRF_TRUSTED_ORIGINS', '', _AS_LIST)

# The name to use for the session cookie.
SESSION_COOKIE_NAME = environ.get('SESSION_COOKIE_NAME', 'sessionid')

# If true, the `includeSubDomains` directive will be included in the HTTP Strict Transport Security (HSTS) header.
# This directive instructs the browser to apply the HSTS policy to all subdomains of the current domain.
SECURE_HSTS_INCLUDE_SUBDOMAINS = _environ_get_and_map('SECURE_HSTS_INCLUDE_SUBDOMAINS', 'False', _AS_BOOL)

# If true, the `preload` directive will be included in the HTTP Strict Transport Security (HSTS) header.
# This directive instructs the browser to preload the site in HTTPS. Browsers that use the HSTS preload list will force the
# site to be accessed via HTTPS even if the user types HTTP in the address bar.
SECURE_HSTS_PRELOAD = _environ_get_and_map('SECURE_HSTS_PRELOAD', 'False', _AS_BOOL)

# If set to a non-zero integer value, the SecurityMiddleware sets the HTTP Strict Transport Security (HSTS) header on all
# responses that do not already have it. This will instruct the browser that the website must be accessed via HTTPS,
# blocking any HTTP request.
SECURE_HSTS_SECONDS = _environ_get_and_map('SECURE_HSTS_SECONDS', 0, _AS_INT)

# If true, all non-HTTPS requests will be automatically redirected to use HTTPS.
SECURE_SSL_REDIRECT = _environ_get_and_map('SECURE_SSL_REDIRECT', 'False', _AS_BOOL)

# By default, NetBox will store session data in the database. Alternatively, a file path can be specified here to use
# local file storage instead. (This can be useful for enabling authentication on a standby instance with read-only
# database access.) Note that the user as which NetBox runs must have read and write permissions to this path.
SESSION_FILE_PATH = environ.get('SESSION_FILE_PATH', environ.get('SESSIONS_ROOT', None))

# Time zone (default: UTC)
TIME_ZONE = environ.get('TIME_ZONE', 'UTC')

