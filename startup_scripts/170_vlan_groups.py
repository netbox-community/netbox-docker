from dcim.models import Site
from ipam.models import VLANGroup
from extras.models import CustomField, CustomFieldValue
from ruamel.yaml import YAML

from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/vlan_groups.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml = YAML(typ='safe')
  vlan_groups = yaml.load(stream)

  optional_assocs = {
    'site': (Site, 'name')
  }

  if vlan_groups is not None:
    for params in vlan_groups:
      custom_fields = params.pop('custom_fields', None)

      for assoc, details in optional_assocs.items():
        if assoc in params:
          model, field = details
          query = { field: params.pop(assoc) }

          params[assoc] = model.objects.get(**query)

      vlan_group, created = VLANGroup.objects.get_or_create(**params)

      if created:
        if custom_fields is not None:
          for cf_name, cf_value in custom_fields.items():
            custom_field = CustomField.objects.get(name=cf_name)
            custom_field_value = CustomFieldValue.objects.create(
              field=custom_field,
              obj=vlan_group,
              value=cf_value
            )

            vlan_group.custom_field_values.add(custom_field_value)

        print("Created VLAN Group", vlan_group.name)
