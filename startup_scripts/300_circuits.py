from circuits.models import Circuit, Provider, CircuitType
from startup_script_utils import *
import sys

circuits = load_yaml('/opt/netbox/initializers/circuits.yml')

if circuits is None:
  sys.exit()

required_assocs = {
  'provider': (Provider, 'name'),
  'circuit_type': (CircuitType, 'name')
}

for params in circuits:
  custom_field_data = pop_custom_fields(params)

  for assoc, details in required_assocs.items():
    model, field = details
    query = { field: params.pop(assoc) }

    params[assoc] = model.objects.get(**query)

  circuit, created = Circuit.objects.get_or_create(**params)

  if created:
    set_custom_fields_values(cid, custom_field_data)

    print("⚡ Created Circuit", circuit.cid)
