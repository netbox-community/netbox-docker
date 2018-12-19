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

        user_permissions = user_details.get('permissions', [])
        if user_permissions:
          user.user_permissions.clear()
          for permission_codename in user_details.get('permissions', []):
            permission = Permission.objects.get(codename=permission_codename)
            user.user_permissions.add(permission)
          user.save()
