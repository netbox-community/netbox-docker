from django.contrib.contenttypes.models import ContentType
from extras.models import Webhook
from startup_script_utils import load_yaml
import sys


webhooks = load_yaml('/opt/netbox/initializers/webhooks.yml')

if webhooks is None:
  sys.exit()

def get_content_type_id(content_type_str):
  for type in ContentType.objects.all():
    if type.name == content_type_str:
      return type.id

for hook in webhooks:
  obj_types = hook.pop('object_types')
  obj_type_ids = []
  for obj in obj_types:
    obj_type_ids.append(get_content_type_id(obj))
  if obj_type_ids is None:
    print("⚠️ Error determining content type id for user declared var: {0}".format(obj_type))
  else:
    webhook = Webhook(**hook)
    webhook.save()
    webhook.obj_type.set(obj_type_ids)
    # webhook.save()