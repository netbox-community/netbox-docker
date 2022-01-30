import sys

from startup_script_utils import load_yaml, pop_custom_fields, set_custom_fields_values
from virtualization.models import VirtualMachine, VMInterface

interfaces = load_yaml("/opt/netbox/initializers/virtualization_interfaces.yml")

if interfaces is None:
    sys.exit()

required_assocs = {"virtual_machine": (VirtualMachine, "name")}

for params in interfaces:
    custom_field_data = pop_custom_fields(params)

    for assoc, details in required_assocs.items():
        model, field = details
        query = {field: params.pop(assoc)}

        params[assoc] = model.objects.get(**query)

    interface, created = VMInterface.objects.get_or_create(**params)

    if created:
        set_custom_fields_values(interface, custom_field_data)

        print("🧷 Created interface", interface.name, interface.virtual_machine.name)
