from dcim.models import Site, Platform, DeviceRole
from virtualization.models import Cluster, VirtualMachine
from tenancy.models import Tenant
from extras.models import CustomField, CustomFieldValue
from ruamel.yaml import YAML

from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/virtual_machines.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml = YAML(typ='safe')
  virtual_machines = yaml.load(stream)

  required_assocs = {
    'cluster': (Cluster, 'name')
  }

  optional_assocs = {
    'tenant': (Tenant, 'name'),
    'platform': (Platform, 'name'),
    'role': (DeviceRole, 'name')
  }

  if virtual_machines is not None:
    for params in virtual_machines:
      custom_fields = params.pop('custom_fields', None)

      for assoc, details in required_assocs.items():
        model, field = details
        query = { field: params.pop(assoc) }

        params[assoc] = model.objects.get(**query)

      for assoc, details in optional_assocs.items():
        if assoc in params:
          model, field = details
          query = { field: params.pop(assoc) }

          params[assoc] = model.objects.get(**query)

      virtual_machine, created = VirtualMachine.objects.get_or_create(**params)

      if created:
        if custom_fields is not None:
          for cf_name, cf_value in custom_fields.items():
            custom_field = CustomField.objects.get(name=cf_name)
            custom_field_value = CustomFieldValue.objects.create(
              field=custom_field,
              obj=virtual_machine,
              value=cf_value
            )

            virtual_machine.custom_field_values.add(custom_field_value)

        print("🖥️ Created virtual machine", virtual_machine.name)
