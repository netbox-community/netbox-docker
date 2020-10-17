import sys

from ipam.models import Aggregate, RIR
from netaddr import IPNetwork
from startup_script_utils import *

aggregates = load_yaml('/opt/netbox/initializers/aggregates.yml')

if aggregates is None:
  sys.exit()

required_assocs = {
  'rir': (RIR, 'name')
}

for params in aggregates:
  custom_field_data = pop_custom_fields(params)

  params['prefix'] = IPNetwork(params['prefix'])

  for assoc, details in required_assocs.items():
    model, field = details
    query = { field: params.pop(assoc) }

    params[assoc] = model.objects.get(**query)

  aggregate, created = Aggregate.objects.get_or_create(**params)

  if created:
    set_custom_fields_values(aggregate, custom_field_data)

    print("🗞️ Created Aggregate", aggregate.prefix)
