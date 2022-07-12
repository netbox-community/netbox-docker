import sys

from circuits.models import CircuitType
from startup_script_utils import (
    load_yaml,
    pop_custom_fields,
    set_custom_fields_values,
    split_params,
)

circuit_types = load_yaml("/opt/netbox/initializers/circuit_types.yml")

if circuit_types is None:
    sys.exit()

for params in circuit_types:
    custom_field_data = pop_custom_fields(params)

    matching_params, defaults = split_params(params)
    circuit_type, created = CircuitType.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("⚡ Created Circuit Type", circuit_type.name)

    set_custom_fields_values(circuit_type, custom_field_data)
