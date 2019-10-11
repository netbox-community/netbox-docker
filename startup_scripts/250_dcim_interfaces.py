from dcim.models import Interface, Device
from dcim.constants import IFACE_TYPE_CHOICES
from extras.models import CustomField, CustomFieldValue
from ruamel.yaml import YAML

from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/dcim_interfaces.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml = YAML(typ='safe')
  interfaces = yaml.load(stream)

  required_assocs = {
    'device': (Device, 'name')
  }

  if interfaces is not None:
    for params in interfaces:
      custom_fields = params.pop('custom_fields', None)

      for assoc, details in required_assocs.items():
        model, field = details
        query = { field: params.pop(assoc) }

        params[assoc] = model.objects.get(**query)

      if 'type' in params:
        for outer_list in IFACE_TYPE_CHOICES:
          for type_choices in outer_list[1]:
            if params['type'] in type_choices:
              params['type'] = type_choices[0]
              break
          else:
            continue
          break

      interface, created = Interface.objects.get_or_create(**params)

      if created:
        if custom_fields is not None:
          for cf_name, cf_value in custom_fields.items():
            custom_field = CustomField.objects.get(name=cf_name)
            custom_field_value = CustomFieldValue.objects.create(
              field=custom_field,
              obj=interface,
              value=cf_value
            )

            interface.custom_field_values.add(custom_field_value)

        print("🧷 Created interface", interface.name, interface.device.name)
