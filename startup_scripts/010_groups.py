import sys

from users.models import AdminGroup, AdminUser
from startup_script_utils import load_yaml

groups = load_yaml("/opt/netbox/initializers/groups.yml")
if groups is None:
    sys.exit()

for params in groups:
    groupname = params["name"]

    group, created = AdminGroup.objects.get_or_create(name=groupname)

    if created:
        print("👥 Created group", groupname)

    for username in params.get("users", []):
        user = AdminUser.objects.get(username=username)

        if user:
            group.user_set.add(user)
            print(" 👤 Assigned user %s to group %s" % (username, AdminGroup.name))

    group.save()
