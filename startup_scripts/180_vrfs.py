from ipam.models import VRF
from tenancy.models import Tenant
from ruamel.yaml import YAML
from extras.models import CustomField, CustomFieldValue

from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/vrfs.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml = YAML(typ='safe')
  vrfs = yaml.load(stream)

  optional_assocs = {
    'tenant': (Tenant, 'name')
  }

  if vrfs is not None:
    for params in vrfs:
      custom_fields = params.pop('custom_fields', None)

      for assoc, details in optional_assocs.items():
        if assoc in params:
          model, field = details
          query = { field: params.pop(assoc) }

          params[assoc] = model.objects.get(**query)

      vrf, created = VRF.objects.get_or_create(**params)

      if created:
        if custom_fields is not None:
          for cf_name, cf_value in custom_fields.items():
            custom_field = CustomField.objects.get(name=cf_name)
            custom_field_value = CustomFieldValue.objects.create(
              field=custom_field,
              obj=vrf,
              value=cf_value
            )

            vrf.custom_field_values.add(custom_field_value)

        print("📦 Created VRF", vrf.name)
