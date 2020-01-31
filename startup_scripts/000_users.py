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

        print("👤 Created user",username)

        if user_details.get('api_token', 0):
          Token.objects.create(user=user, key=user_details['api_token'])

        yaml_permissions = user_details.get('permissions', [])
        subject = user.user_permissions
        if yaml_permissions:
          subject.clear()
          for yaml_permission in yaml_permissions:
            if '*' in yaml_permission:
              permission_filter = '^' + yaml_permission.replace('*','.*') + '$'
              permissions = Permission.objects.filter(codename__iregex=permission_filter)
              print("  ⚿ Granting", permissions.count(), "permissions matching '" + yaml_permission + "'")
            else:
              permissions = Permission.objects.filter(codename=yaml_permission)
              print("  ⚿ Granting permission", yaml_permission)
            
            for permission in permissions:
              subject.add(permission)
