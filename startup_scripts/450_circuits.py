import sys

from circuits.models import Circuit, CircuitType, Provider
from startup_script_utils import (
    load_yaml,
    pop_custom_fields,
    set_custom_fields_values,
    split_params,
)
from tenancy.models import Tenant

circuits = load_yaml("/opt/netbox/initializers/circuits.yml")

if circuits is None:
    sys.exit()

match_params = ["cid", "provider", "type"]
required_assocs = {"provider": (Provider, "name"), "type": (CircuitType, "name")}
optional_assocs = {"tenant": (Tenant, "name")}

for params in circuits:
    custom_field_data = pop_custom_fields(params)

    for assoc, details in required_assocs.items():
        model, field = details
        query = {field: params.pop(assoc)}

        params[assoc] = model.objects.get(**query)

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}

            params[assoc] = model.objects.get(**query)

    matching_params, defaults = split_params(params, match_params)
    circuit, created = Circuit.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("⚡ Created Circuit", circuit.cid)

    set_custom_fields_values(circuit, custom_field_data)
