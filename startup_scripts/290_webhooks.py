from django.contrib.contenttypes.models import ContentType
from extras.models import Webhook
from startup_script_utils import load_yaml
import sys


webhooks = load_yaml('/opt/netbox/initializers/webhooks.yml')

if webhooks is None:
  sys.exit()

def get_content_type_id(content_type_str):
  try:
    id = ContentType.objects.get(model=content_type_str).id
    return id
  except ContentType.DoesNotExist:
    print("⚠️ Error determining content type id for user declared var: {0}".format(content_type_str))

for hook in webhooks:
  obj_types = hook.pop('object_types')
  obj_type_ids = [ get_content_type_id(obj) for obj in obj_types ]
  if obj_type_ids is not None:
    webhook = Webhook(**hook)
    if not Webhook.objects.filter(name=webhook.name):
      webhook.save()
      webhook.content_types.set(obj_type_ids)
      print("🖥️  Created Webhook {0}".format(webhook.name))
