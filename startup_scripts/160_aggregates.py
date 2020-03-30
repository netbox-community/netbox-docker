from ipam.models import Aggregate, RIR

from extras.models import CustomField, CustomFieldValue

from netaddr import IPNetwork
from startup_script_utils import load_yaml
import sys

aggregates = load_yaml('/opt/netbox/initializers/aggregates.yml')

if aggregates is None:
  sys.exit()

required_assocs = {
  'rir': (RIR, 'name')
}

for params in aggregates:
  custom_fields = params.pop('custom_fields', None)
  params['prefix'] = IPNetwork(params['prefix'])

  for assoc, details in required_assocs.items():
    model, field = details
    query = { field: params.pop(assoc) }

    params[assoc] = model.objects.get(**query)

  aggregate, created = Aggregate.objects.get_or_create(**params)

  if created:
    if custom_fields is not None:
      for cf_name, cf_value in custom_fields.items():
        custom_field = CustomField.objects.get(name=cf_name)
        custom_field_value = CustomFieldValue.objects.create(
          field=custom_field,
          obj=aggregate,
          value=cf_value
        )

        aggregate.custom_field_values.add(custom_field_value)

    print("🗞️ Created Aggregate", aggregate.prefix)
