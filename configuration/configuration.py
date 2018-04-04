import os
import socket

# For reference see http://netbox.readthedocs.io/en/latest/configuration/mandatory-settings/
# Based on https://github.com/digitalocean/netbox/blob/develop/netbox/netbox/configuration.example.py

# Read secret from file
def read_secret(secret_name):
    try:
        f = open('/run/secrets/' + secret_name, 'r', encoding='utf-8')
    except EnvironmentError:
        return ''
    else:
        with f:
            return f.readline().strip()

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

#########################
#                       #
#   Required settings   #
#                       #
#########################

# This is a list of valid fully-qualified domain names (FQDNs) for the NetBox server. NetBox will not permit write
# access to the server via any other hostnames. The first FQDN in the list will be treated as the preferred name.
#
# Example: ALLOWED_HOSTS = ['netbox.example.com', 'netbox.internal.local']
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', socket.gethostname()).split(' ')

# PostgreSQL database configuration.
DATABASE = {
    'NAME': os.environ.get('DB_NAME', 'netbox'),         # Database name
    'USER': os.environ.get('DB_USER', ''),               # PostgreSQL username
    'PASSWORD': os.environ.get('DB_PASSWORD', read_secret('db_password')),
                                                         # PostgreSQL password
    'HOST': os.environ.get('DB_HOST', 'localhost'),      # Database server
    'PORT': os.environ.get('DB_PORT', ''),               # Database port (leave blank for default)
}

# This key is used for secure generation of random numbers and strings. It must never be exposed outside of this file.
# For optimal security, SECRET_KEY should be at least 50 characters in length and contain a mix of letters, numbers, and
# symbols. NetBox will not run without this defined. For more information, see
# https://docs.djangoproject.com/en/dev/ref/settings/#std:setting-SECRET_KEY
SECRET_KEY = os.environ.get('SECRET_KEY', read_secret('secret_key'))

#########################
#                       #
#   Optional settings   #
#                       #
#########################

# Specify one or more name and email address tuples representing NetBox administrators. These people will be notified of
# application errors (assuming correct email settings are provided).
ADMINS = [
    # ['John Doe', 'jdoe@example.com'],
]

# Optionally display a persistent banner at the top and/or bottom of every page. HTML is allowed. To display the same
# content in both banners, define BANNER_TOP and set BANNER_BOTTOM = BANNER_TOP.
BANNER_TOP = os.environ.get('BANNER_TOP', '')
BANNER_BOTTOM = os.environ.get('BANNER_BOTTOM', '')

# Text to include on the login page above the login form. HTML is allowed.
BANNER_LOGIN = os.environ.get('BANNER_LOGIN', '')

# Base URL path if accessing NetBox within a directory. For example, if installed at http://example.com/netbox/, set:
# BASE_PATH = 'netbox/'
BASE_PATH = os.environ.get('BASE_PATH', '')

# API Cross-Origin Resource Sharing (CORS) settings. If CORS_ORIGIN_ALLOW_ALL is set to True, all origins will be
# allowed. Otherwise, define a list of allowed origins using either CORS_ORIGIN_WHITELIST or
# CORS_ORIGIN_REGEX_WHITELIST. For more information, see https://github.com/ottoyiu/django-cors-headers
CORS_ORIGIN_ALLOW_ALL = os.environ.get('CORS_ORIGIN_ALLOW_ALL', 'False').lower() == 'true'
CORS_ORIGIN_WHITELIST = os.environ.get('CORS_ORIGIN_WHITELIST', '').split(' ')
CORS_ORIGIN_REGEX_WHITELIST = [
    # r'^(https?://)?(\w+\.)?example\.com$',
]

# Set to True to enable server debugging. WARNING: Debugging introduces a substantial performance penalty and may reveal
# sensitive information about your installation. Only enable debugging while performing testing. Never enable debugging
# on a production system.
DEBUG = os.environ.get('DEBUG', 'False').lower() == 'true'

# Email settings
EMAIL = {
    'SERVER': os.environ.get('EMAIL_SERVER', 'localhost'),
    'PORT': int(os.environ.get('EMAIL_PORT', 25)),
    'USERNAME': os.environ.get('EMAIL_USERNAME', ''),
    'PASSWORD': os.environ.get('EMAIL_PASSWORD', read_secret('email_password')),
    'TIMEOUT': int(os.environ.get('EMAIL_TIMEOUT', 10)),  # seconds
    'FROM_EMAIL': os.environ.get('EMAIL_FROM', ''),
}

# Enforcement of unique IP space can be toggled on a per-VRF basis.
# To enforce unique IP space within the global table (all prefixes and IP addresses not assigned to a VRF),
# set ENFORCE_GLOBAL_UNIQUE to True.
ENFORCE_GLOBAL_UNIQUE = os.environ.get('ENFORCE_GLOBAL_UNIQUE', 'False').lower() == 'true'

# Enable custom logging. Please see the Django documentation for detailed guidance on configuring custom logs:
#   https://docs.djangoproject.com/en/1.11/topics/logging/
LOGGING = {}

# Setting this to True will permit only authenticated users to access any part of NetBox. By default, anonymous users
# are permitted to access most data in NetBox (excluding secrets) but not make any changes.
LOGIN_REQUIRED = os.environ.get('LOGIN_REQUIRED', 'False').lower() == 'true'

# Base URL path if accessing NetBox within a directory. For example, if installed at http://example.com/netbox/, set:
# BASE_PATH = 'netbox/'
BASE_PATH = os.environ.get('BASE_PATH', '')

# Setting this to True will display a "maintenance mode" banner at the top of every page.
MAINTENANCE_MODE = os.environ.get('MAINTENANCE_MODE', 'False').lower() == 'true'

# An API consumer can request an arbitrary number of objects =by appending the "limit" parameter to the URL (e.g.
# "?limit=1000"). This setting defines the maximum limit. Setting it to 0 or None will allow an API consumer to request
# all objects by specifying "?limit=0".
MAX_PAGE_SIZE = int(os.environ.get('MAX_PAGE_SIZE', 1000))

# The file path where uploaded media such as image attachments are stored. A trailing slash is not needed. Note that
# the default value of this setting is derived from the installed location.
MEDIA_ROOT = os.environ.get('MEDIA_ROOT', os.path.join(BASE_DIR, 'media'))

# Credentials that NetBox will use to access live devices.
NAPALM_USERNAME = os.environ.get('NAPALM_USERNAME', '')
NAPALM_PASSWORD = os.environ.get('NAPALM_PASSWORD', read_secret('napalm_password'))

# NAPALM timeout (in seconds). (Default: 30)
NAPALM_TIMEOUT = int(os.environ.get('NAPALM_TIMEOUT', 30))

# NAPALM optional arguments (see http://napalm.readthedocs.io/en/latest/support/#optional-arguments). Arguments must
# be provided as a dictionary.
NAPALM_ARGS = {}

# Determine how many objects to display per page within a list. (Default: 50)
PAGINATE_COUNT = int(os.environ.get('PAGINATE_COUNT', 50))

# When determining the primary IP address for a device, IPv6 is preferred over IPv4 by default. Set this to True to
# prefer IPv4 instead.
PREFER_IPV4 = os.environ.get('PREFER_IPV4', 'False').lower() == 'true'

# The file path where custom reports will be stored. A trailing slash is not needed. Note that the default value of
# this setting is derived from the installed location.
REPORTS_ROOT = os.environ.get('REPORTS_ROOT', '/etc/netbox/reports')

# Time zone (default: UTC)
TIME_ZONE = os.environ.get('TIME_ZONE', 'UTC')

# Date/time formatting. See the following link for supported formats:
# https://docs.djangoproject.com/en/dev/ref/templates/builtins/#date
DATE_FORMAT = os.environ.get('DATE_FORMAT', 'N j, Y')
SHORT_DATE_FORMAT = os.environ.get('SHORT_DATE_FORMAT', 'Y-m-d')
TIME_FORMAT = os.environ.get('TIME_FORMAT', 'g:i a')
SHORT_TIME_FORMAT = os.environ.get('SHORT_TIME_FORMAT', 'H:i:s')
DATETIME_FORMAT = os.environ.get('DATETIME_FORMAT', 'N j, Y g:i a')
SHORT_DATETIME_FORMAT = os.environ.get('SHORT_DATETIME_FORMAT', 'Y-m-d H:i')
