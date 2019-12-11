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

      yaml_permissions = group_details.get('permissions', [])
      permission_object = group
      if yaml_permissions:
        permission_object.permissions.clear()
        for yaml_permission in yaml_permissions:
          if '*' in yaml_permission:
            permission_codename_function = 'codename__iregex'
            permission_codename = '^' + yaml_permission.replace('*','.*') + '$'
          else:
            permission_codename_function = 'codename'
            permission_codename = yaml_permission
          
          # supports non-unique permission codenames
          for permission in eval('Permission.objects.filter(' + permission_codename_function + '=permission_codename)'):
            permission_object.permissions.add(permission)
