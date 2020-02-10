from django.contrib.auth.models import Permission, Group, User
from startup_script_utils import load_yaml
import sys

groups = load_yaml('/opt/netbox/initializers/groups.yml')
if groups is None:
  sys.exit()

for groupname, group_details in groups.items():
  group, created = Group.objects.get_or_create(name=groupname)

  if created:
    print("👥 Created group", groupname)

  for username in group_details.get('users', []):
    user = User.objects.get(username=username)

    if user:
      user.groups.add(group)

  yaml_permissions = group_details.get('permissions', [])
  if yaml_permissions:
    subject = group.permissions
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
