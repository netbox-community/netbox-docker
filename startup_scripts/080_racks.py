from dcim.models import Site, RackRole, Rack, RackGroup
from tenancy.models import Tenant
from extras.models import CustomField, CustomFieldValue
from startup_script_utils import load_yaml
import sys

racks = load_yaml('/opt/netbox/initializers/racks.yml')

if racks is None:
  sys.exit()

required_assocs = {
  'site': (Site, 'name')
}

optional_assocs = {
  'role': (RackRole, 'name'),
  'tenant': (Tenant, 'name'),
  'group': (RackGroup, 'name')
}

for params in racks:
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

  rack, created = Rack.objects.get_or_create(**params)

  if created:
    if custom_fields is not None:
      for cf_name, cf_value in custom_fields.items():
        custom_field = CustomField.objects.get(name=cf_name)
        custom_field_value = CustomFieldValue.objects.create(
          field=custom_field,
          obj=rack,
          value=cf_value
        )

        rack.custom_field_values.add(custom_field_value)

    print("🔳 Created rack", rack.site, rack.name)
