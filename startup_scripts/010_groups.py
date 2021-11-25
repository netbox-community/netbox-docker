import sys

from startup_script_utils import load_yaml
from users.models import AdminGroup, AdminUser

groups = load_yaml("/opt/netbox/initializers/groups.yml")
if groups is None:
    sys.exit()

for groupname, group_details in groups.items():
    group, created = AdminGroup.objects.get_or_create(name=groupname)

    if created:
        print("👥 Created group", groupname)

    for username in group_details.get("users", []):
        user = AdminUser.objects.get(username=username)

        if user:
            group.user_set.add(user)
            print(" 👤 Assigned user %s to group %s" % (username, group.name))

    group.save()
