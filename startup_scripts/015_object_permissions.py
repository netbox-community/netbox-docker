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

    if permission_details.get("object_types", 0):
        object_types = permission_details["object_types"]

        if object_types == "all":
            object_permission.object_types.set(ContentType.objects.all())

        else:
            for app_label, models in object_types.items():
                if models == "all":
                    app_models = ContentType.objects.filter(app_label=app_label)

                    for app_model in app_models:
                        object_permission.object_types.add(app_model.id)
                else:
                    # There is
                    for model in models:
                        object_permission.object_types.add(
                            ContentType.objects.get(app_label=app_label, model=model)
                        )

    print("🔓 Created object permission", object_permission.name)

    if permission_details.get("groups", 0):
        for groupname in permission_details["groups"]:
            group = AdminGroup.objects.filter(name=groupname).first()

            if group:
                object_permission.groups.add(group)
                print(
                    " 👥 Assigned group %s object permission of %s"
                    % (groupname, object_permission.name)
                )

    if permission_details.get("users", 0):
        for username in permission_details["users"]:
            user = AdminUser.objects.filter(username=username).first()

            if user:
                object_permission.users.add(user)
                print(
                    " 👤 Assigned user %s object permission of %s"
                    % (username, object_permission.name)
                )

    object_permission.save()
