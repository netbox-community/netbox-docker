import sys

from circuits.models import Circuit, CircuitType, Provider
from startup_script_utils import load_yaml, pop_custom_fields, set_custom_fields_values
from tenancy.models import Tenant

circuits = load_yaml("/opt/netbox/initializers/circuits.yml")

if circuits is None:
    sys.exit()

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

    circuit, created = Circuit.objects.get_or_create(**params)

    if created:
        set_custom_fields_values(circuit, custom_field_data)

        print("⚡ Created Circuit", circuit.cid)
