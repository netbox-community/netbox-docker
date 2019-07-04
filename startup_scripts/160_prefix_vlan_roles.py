from ipam.models import Role
from ruamel.yaml import YAML
from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/prefix_vlan_roles.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml = YAML(typ='safe')
  roles = yaml.load(stream)

  if roles is not None:
    for params in roles:
      role, created = Role.objects.get_or_create(**params)

      if created:
        print("Created Prefix/VLAN Role", role.name)
