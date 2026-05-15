####
## This file contains extra configuration options that can't be configured
## directly through environment variables.
## All vairables set here overwrite any existing found in ldap_config.py
####

# # This Python script inherits all the imports from ldap_config.py
# from django_auth_ldap.config import LDAPGroupQuery # Imported since not in ldap_config.py

# # Sets a base requirement of membetship to netbox-user-ro, netbox-user-rw, or netbox-user-admin.
# AUTH_LDAP_REQUIRE_GROUP = (
#     LDAPGroupQuery("cn=netbox-user-ro,ou=groups,dc=example,dc=com")
#     | LDAPGroupQuery("cn=netbox-user-rw,ou=groups,dc=example,dc=com")
#     | LDAPGroupQuery("cn=netbox-user-admin,ou=groups,dc=example,dc=com")
# )

# # Sets LDAP Flag groups variables with example.
# AUTH_LDAP_USER_FLAGS_BY_GROUP = {
#     "is_staff": (
#         LDAPGroupQuery("cn=netbox-user-ro,ou=groups,dc=example,dc=com")
#         | LDAPGroupQuery("cn=netbox-user-rw,ou=groups,dc=example,dc=com")
#         | LDAPGroupQuery("cn=netbox-user-admin,ou=groups,dc=example,dc=com")
#     ),
#     "is_superuser": "cn=netbox-user-admin,ou=groups,dc=example,dc=com",
# }

# # Sets LDAP Mirror groups variables with example groups
# AUTH_LDAP_MIRROR_GROUPS = ["netbox-user-ro", "netbox-user-rw", "netbox-user-admin"]
