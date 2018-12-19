from django.contrib.auth.models import Permission, Group, User
from ruamel.yaml import YAML
from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/groups.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml=YAML(typ='safe')
  groups = yaml.load(stream)

  if groups is not None:
    for groupname, group_details in groups.items():
      group, created = Group.objects.get_or_create(name=groupname)

      if created:
        print("👥 Created group", groupname)

      for username in group_details.get('users', []):
        user = User.objects.get(username=username)

        if user:
          user.groups.add(group)

      group_permissions = group_details.get('permissions', [])
      if group_permissions:
        group.permissions.clear()
        print("Permissions:", group.permissions.all())
        for permission_codename in group_details.get('permissions', []):
          permission = Permission.objects.get(codename=permission_codename)
          group.permissions.add(permission)
