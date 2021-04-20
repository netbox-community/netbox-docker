import sys

from users.models import ObjectPermission, AdminGroup, AdminUser
from startup_script_utils import load_yaml
from django.contrib.contenttypes.models import ContentType

object_permissions = load_yaml("/opt/netbox/initializers/object_permissions.yml")

if object_permissions is None:
    sys.exit()


for params in object_permissions:

    object_permission, created = ObjectPermission.objects.get_or_create(
        name=params['name'],
        description=params['description'],
        enabled=params['enabled'],
        actions=params['actions']
    )

# Need to try to pass a list of model_name and app_label for more than just the current all objects.
    #object_types = ContentType.objects.filter(app_label__in=params.pop("object_types"))
    #object_permission.object_types.set(ContentType.objects.filter(app_label__in=params.pop("object_types")))
    object_permission.object_types.set(ContentType.objects.all())
    object_permission.save()

    print("🔓 Created object permission", object_permission.name)

    for groupname in params.get("groups", []):
        group = AdminGroup.objects.get(name=groupname)

        if group:
            object_permission.groups.add(group)
            print(" 👥 Assigned group %s object permission of %s" % (groupname, object_permission.name))

    for username in params.get("users", []):
        user = AdminUser.objects.get(username=username)

        if user:
            object_permission.users.add(user)
            print(" 👤 Assigned user %s object permission of %s" % (username, object_permission.name))

    object_permission.save()
