from dcim.models import Site, Platform, DeviceRole
from virtualization.models import Cluster, VirtualMachine
from tenancy.models import Tenant
from extras.models import CustomField, CustomFieldValue
from startup_script_utils import load_yaml
import sys

virtual_machines = load_yaml('/opt/netbox/initializers/virtual_machines.yml')

if virtual_machines is None:
  sys.exit()

required_assocs = {
  'cluster': (Cluster, 'name')
}

optional_assocs = {
  'tenant': (Tenant, 'name'),
  'platform': (Platform, 'name'),
  'role': (DeviceRole, 'name')
}

for params in virtual_machines:
  custom_fields = params.pop('custom_fields', None)
  # primary ips are handled later in `270_primary_ips.py`
  params.pop('primary_ip4', None)
  params.pop('primary_ip6', None)

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
