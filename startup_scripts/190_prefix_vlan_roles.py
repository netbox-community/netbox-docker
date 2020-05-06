from ipam.models import Role
from startup_script_utils import load_yaml
import sys

roles = load_yaml('/opt/netbox/initializers/prefix_vlan_roles.yml')

if not roles is None:

  for params in roles:
    role, created = Role.objects.get_or_create(**params)

    if created:
      print("⛹️‍ Created Prefix/VLAN Role", role.name)
