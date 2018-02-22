from django.contrib.auth.models import Group, User
from ruamel.yaml import YAML

with open('/opt/netbox/initializers/groups.yml', 'r') as stream:
  yaml=YAML(typ='safe')
  groups = yaml.load(stream)

  if groups is not None:
    for groupname, group_details in groups.items():
      group, created = Group.objects.get_or_create(name=groupname)

      if created:
        print("👥 Created group", groupname)

      for username in group_details['users']:
        user = User.objects.get(username=username)

        if user:
          user.groups.add(group)
