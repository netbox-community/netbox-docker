import sys

from django.contrib.contenttypes.models import ContentType
from extras.models import Webhook
from startup_script_utils import load_yaml

webhooks = load_yaml("/opt/netbox/initializers/webhooks.yml")

if webhooks is None:
    sys.exit()


def get_content_type_id(hook_name, content_type):
    try:
        return ContentType.objects.get(model=content_type).id
    except ContentType.DoesNotExist as ex:
        print("⚠️ Webhook '{0}': The object_type '{1}' is unknown.".format(hook_name, content_type))
        raise ex


for hook in webhooks:
    obj_types = hook.pop("object_types")

    try:
        obj_type_ids = [get_content_type_id(hook["name"], obj) for obj in obj_types]
    except ContentType.DoesNotExist:
        continue

    webhook, created = Webhook.objects.get_or_create(**hook)
    if created:
        webhook.content_types.set(obj_type_ids)
        webhook.save()

        print("🪝 Created Webhook {0}".format(webhook.name))
