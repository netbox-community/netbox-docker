from virtualization.models import VirtualMachine, VMInterface
from extras.models import CustomField, CustomFieldValue
from startup_script_utils import load_yaml
import sys

interfaces = load_yaml('/opt/netbox/initializers/virtualization_interfaces.yml')

if interfaces is None:
  sys.exit()

required_assocs = {
  'virtual_machine': (VirtualMachine, 'name')
}

for params in interfaces:
  custom_fields = params.pop('custom_fields', None)

  for assoc, details in required_assocs.items():
    model, field = details
    query = { field: params.pop(assoc) }

    params[assoc] = model.objects.get(**query)

  interface, created = VMInterface.objects.get_or_create(**params)

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

    print("🧷 Created interface", interface.name, interface.virtual_machine.name)
