import sys

from dcim.models import Device, Interface
from startup_script_utils import (
    load_yaml,
    pop_custom_fields,
    set_custom_fields_values,
    split_params,
)

interfaces = load_yaml("/opt/netbox/initializers/dcim_interfaces.yml")

if interfaces is None:
    sys.exit()

match_params = ["device", "name"]
required_assocs = {"device": (Device, "name")}

for params in interfaces:
    custom_field_data = pop_custom_fields(params)

    for assoc, details in required_assocs.items():
        model, field = details
        query = {field: params.pop(assoc)}

        params[assoc] = model.objects.get(**query)

    matching_params, defaults = split_params(params, match_params)
    interface, created = Interface.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("🧷 Created interface", interface.name, interface.device.name)

    set_custom_fields_values(interface, custom_field_data)
