from django.contrib.auth.models import Permission, Group, User
from users.models import Token

from ruamel.yaml import YAML
from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/users.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml=YAML(typ='safe')
  users = yaml.load(stream)

  if users is not None:
    for username, user_details in users.items():
      if not User.objects.filter(username=username):
        user = User.objects.create_user(
          username = username,
          password = user_details.get('password', 0) or User.objects.make_random_password)

        print("👤 Created user ",username)

        if user_details.get('api_token', 0):
          Token.objects.create(user=user, key=user_details['api_token'])

        yaml_permissions = user_details.get('permissions', [])
        permission_object = user
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

          permission_object.save()
