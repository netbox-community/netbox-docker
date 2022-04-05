import sys

from ipam.models import Role
from startup_script_utils import load_yaml, split_params

roles = load_yaml("/opt/netbox/initializers/prefix_vlan_roles.yml")

if roles is None:
    sys.exit()

for params in roles:
    matching_params, defaults = split_params(params)
    role, created = Role.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("⛹️‍ Created Prefix/VLAN Role", role.name)
