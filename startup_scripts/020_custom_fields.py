from extras.models import CustomField, CustomFieldChoice

from startup_script_utils import load_yaml
import sys

def get_class_for_class_path(class_path):
  import importlib
  from django.contrib.contenttypes.models import ContentType

  module_name, class_name = class_path.rsplit(".", 1)
  module = importlib.import_module(module_name)
  clazz = getattr(module, class_name)
  return ContentType.objects.get_for_model(clazz)

customfields = load_yaml('/opt/netbox/initializers/custom_fields.yml')

if customfields is None:
  sys.exit()

for cf_name, cf_details in customfields.items():
  custom_field, created = CustomField.objects.get_or_create(name = cf_name)

  if created:
    if cf_details.get('default', 0):
      custom_field.default = cf_details['default']

    if cf_details.get('description', 0):
      custom_field.description = cf_details['description']

    if cf_details.get('label', 0):
      custom_field.label = cf_details['label']

    for object_type in cf_details.get('on_objects', []):
      custom_field.obj_type.add(get_class_for_class_path(object_type))

    if cf_details.get('required', 0):
      custom_field.required = cf_details['required']

    if cf_details.get('type', 0):
      custom_field.type = cf_details['type']

    if cf_details.get('weight', 0):
      custom_field.weight = cf_details['weight']

    custom_field.save()

    for idx, choice_details in enumerate(cf_details.get('choices', [])):
      choice, _ = CustomFieldChoice.objects.get_or_create(
        field=custom_field,
        value=choice_details['value'],
        defaults={'weight': idx * 10}
      )

    print("🔧 Created custom field", cf_name)
