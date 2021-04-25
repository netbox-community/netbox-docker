import sys

from django.contrib.contenttypes.models import ContentType
from startup_script_utils import load_yaml
from users.models import AdminGroup, AdminUser, ObjectPermission

object_permissions = load_yaml("/opt/netbox/initializers/object_permissions.yml")

if object_permissions is None:
    sys.exit()


for permission_name, permission_details in object_permissions.items():

    object_permission, created = ObjectPermission.objects.get_or_create(
        name=permission_name,
        description=permission_details["description"], 
        enabled=permission_details["enabled"],
        actions=permission_details["actions"],
    )

    # Need to try to pass a list of model_name and app_label for more than the current ALL
    # object_types = ContentType.objects.filter(app_label__in=permission_details["object_types"])
    # object_permission.object_types.set(ContentType.objects.filter(app_label__in=permission_details"object_types"]))
    object_permission.object_types.set(ContentType.objects.all())
    object_permission.save()

    print("🔓 Created object permission", object_permission.name)
    
    if permission_details.get("groups", 0):
        for groupname in permission_details["groups"]:
            group = AdminGroup.objects.get(name=groupname)

            if group:
                object_permission.groups.add(group)
                print(
                    " 👥 Assigned group %s object permission of %s" % (groupname, object_permission.name)
                )

    if permission_details.get("users", 0):
        for username in permission_details["users"]:
            user = AdminUser.objects.get(username=username)

            if user:
                object_permission.users.add(user)
                print(
                    " 👤 Assigned user %s object permission of %s" % (username, object_permission.name)
                )

    object_permission.save()
