import ldap
import os

from django_auth_ldap.config import LDAPSearch, GroupOfNamesType

# Server URI
AUTH_LDAP_SERVER_URI = os.environ.get('AUTH_LDAP_SERVER_URI', '')

# The following may be needed if you are binding to Active Directory.
AUTH_LDAP_CONNECTION_OPTIONS = {
    ldap.OPT_REFERRALS: 0
}

# Set the DN and password for the NetBox service account.
AUTH_LDAP_BIND_DN = os.environ.get('AUTH_LDAP_BIND_DN', '')
AUTH_LDAP_BIND_PASSWORD = os.environ.get('AUTH_LDAP_BIND_PASSWORD', '')

# Set a string template that describes any user’s distinguished name based on the username.
AUTH_LDAP_USER_DN_TEMPLATE = os.environ.get('AUTH_LDAP_USER_DN_TEMPLATE', None)

# Include this setting if you want to ignore certificate errors. This might be needed to accept a self-signed cert.
# Note that this is a NetBox-specific setting which sets:
#     ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_NEVER)
LDAP_IGNORE_CERT_ERRORS = os.environ.get('LDAP_IGNORE_CERT_ERRORS', 'False').lower() == 'true'

AUTH_LDAP_USER_SEARCH_BASEDN = os.environ.get('AUTH_LDAP_USER_SEARCH_BASEDN', '')
AUTH_LDAP_USER_SEARCH_ATTR = os.environ.get('AUTH_LDAP_USER_SEARCH_ATTR', 'sAMAccountName')
AUTH_LDAP_USER_SEARCH = LDAPSearch(AUTH_LDAP_USER_SEARCH_BASEDN,
                                   ldap.SCOPE_SUBTREE,
                                   "(" + AUTH_LDAP_USER_SEARCH_ATTR + "=%(user)s)")

# This search ought to return all groups to which the user belongs. django_auth_ldap uses this to determine group
# heirarchy.
AUTH_LDAP_GROUP_SEARCH_BASEDN = os.environ.get('AUTH_LDAP_GROUP_SEARCH_BASEDN', '')
AUTH_LDAP_GROUP_SEARCH_CLASS = os.environ.get('AUTH_LDAP_GROUP_SEARCH_CLASS', 'group')
AUTH_LDAP_GROUP_SEARCH = LDAPSearch(AUTH_LDAP_GROUP_SEARCH_BASEDN, ldap.SCOPE_SUBTREE,
                                    "(objectClass=" + AUTH_LDAP_GROUP_SEARCH_CLASS + ")")
AUTH_LDAP_GROUP_TYPE = GroupOfNamesType()

# Define a group required to login.
AUTH_LDAP_REQUIRE_GROUP = os.environ.get('AUTH_LDAP_REQUIRE_GROUP_DN', '')

# Define special user types using groups. Exercise great caution when assigning superuser status.
AUTH_LDAP_USER_FLAGS_BY_GROUP = {
    "is_active": os.environ.get('AUTH_LDAP_REQUIRE_GROUP_DN', ''),
    "is_staff": os.environ.get('AUTH_LDAP_IS_ADMIN_DN', ''),
    "is_superuser": os.environ.get('AUTH_LDAP_IS_SUPERUSER_DN', '')
}

# For more granular permissions, we can map LDAP groups to Django groups.
AUTH_LDAP_FIND_GROUP_PERMS = os.environ.get('AUTH_LDAP_FIND_GROUP_PERMS', 'True').lower() == 'true'

# Cache groups for one hour to reduce LDAP traffic
AUTH_LDAP_CACHE_GROUPS = os.environ.get('AUTH_LDAP_CACHE_GROUPS', 'True').lower() == 'true'
AUTH_LDAP_GROUP_CACHE_TIMEOUT = int(os.environ.get('AUTH_LDAP_GROUP_CACHE_TIMEOUT', 3600))

# Populate the Django user from the LDAP directory.
AUTH_LDAP_USER_ATTR_MAP = {
    "first_name": os.environ.get('AUTH_LDAP_ATTR_FIRSTNAME', 'givenName'),
    "last_name": os.environ.get('AUTH_LDAP_ATTR_LASTNAME', 'sn'),
    "email": os.environ.get('AUTH_LDAP_ATTR_MAIL', 'mail')
}
