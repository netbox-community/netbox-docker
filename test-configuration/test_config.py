LOGGING = {
    'version': 1,
    'disable_existing_loggers': True
}

PLUGINS = [
    'netbox.tests.dummy_plugin',
]

ALLOW_TOKEN_RETRIEVAL = True

DEFAULT_PERMISSIONS = {}

API_TOKEN_PEPPERS = {
    1: 'TEST-VALUE-DO-NOT-USE-TEST-VALUE-DO-NOT-USE-TEST-VALUE-DO-NOT-USE',
}
