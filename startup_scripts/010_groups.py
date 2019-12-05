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
          if isinstance(yaml_permission,dict):
            # assume this is the specific codename filter function instead of an exact codename
            permission_codename_function = list(yaml_permission.keys())[0]
            permission_codenames = yaml_permission[permission_codename_function]
          else:
            permission_codename_function = 'codename'
            permission_codenames = list({yaml_permission})

          # supports either one codename from the permissions list, or multiple codenames in a codename_function dict
          for permission_codename in permission_codenames:
            # supports non-unique permission codenames
            for permission in eval('Permission.objects.filter(' + permission_codename_function + '=permission_codename)'):
              permission_object.permissions.add(permission)
