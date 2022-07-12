import sys

from startup_script_utils import (
    load_yaml,
    pop_custom_fields,
    set_custom_fields_values,
    split_params,
)
from virtualization.models import VirtualMachine, VMInterface

interfaces = load_yaml("/opt/netbox/initializers/virtualization_interfaces.yml")

if interfaces is None:
    sys.exit()

match_params = ["name", "virtual_machine"]
required_assocs = {"virtual_machine": (VirtualMachine, "name")}

for params in interfaces:
    custom_field_data = pop_custom_fields(params)

    for assoc, details in required_assocs.items():
        model, field = details
        query = {field: params.pop(assoc)}

        params[assoc] = model.objects.get(**query)

    matching_params, defaults = split_params(params, match_params)
    interface, created = VMInterface.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("🧷 Created interface", interface.name, interface.virtual_machine.name)

    set_custom_fields_values(interface, custom_field_data)
