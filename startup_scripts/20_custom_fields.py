from extras.constants import CF_TYPE_TEXT, CF_TYPE_INTEGER, CF_TYPE_BOOLEAN, CF_TYPE_DATE, CF_TYPE_URL, CF_TYPE_SELECT
from extras.models import CustomField, CustomFieldChoice

from ruamel.yaml import YAML

text_to_fields = {
  'boolean': CF_TYPE_BOOLEAN,
  'date': CF_TYPE_DATE,
  'integer': CF_TYPE_INTEGER,
  'selection': CF_TYPE_SELECT,
  'text': CF_TYPE_TEXT,
  'url': CF_TYPE_URL,
}

def get_class_for_class_path(class_path):
  import importlib
  from django.contrib.contenttypes.models import ContentType

  module_name, class_name = class_path.rsplit(".", 1)
  module = importlib.import_module(module_name)
  clazz = getattr(module, class_name)
  return ContentType.objects.get_for_model(clazz)

with open('/opt/netbox/initializers/custom_fields.yml', 'r') as stream:
  yaml = YAML(typ='safe')
  customfields = yaml.load(stream)

  if customfields is not None:
    for cf_name, cf_details in customfields.items():
      custom_field, created = CustomField.objects.get_or_create(name = cf_name)

      if created:
        if cf_details.get('default', 0):
          custom_field.default = cf_details['default']

        if cf_details.get('description', 0):
          custom_field.description = cf_details['description']

        if cf_details.get('filterable', 0):
          custom_field.is_filterables = cf_details['filterable']

        if cf_details.get('label', 0):
          custom_field.label = cf_details['label']

        for object_type in cf_details.get('on_objects', []):
          custom_field.obj_type.add(get_class_for_class_path(object_type))

        if cf_details.get('required', 0):
          custom_field.required = cf_details['required']

        if cf_details.get('type', 0):
          custom_field.type = text_to_fields[cf_details['type']]

        if cf_details.get('weight', 0):
          custom_field.weight = cf_details['weight']

        custom_field.save()

        for choice_details in cf_details.get('choices', []):
          choice = CustomFieldChoice.objects.create(
            field=custom_field,
            value=choice_details['value'])

          if choice_details.get('weight', 0):
            choice.weight = choice_details['weight']
            choice.save()

        print("🔧 Created custom field", cf_name)
