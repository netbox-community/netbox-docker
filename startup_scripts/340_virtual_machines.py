import sys

from dcim.models import DeviceRole, Platform
from startup_script_utils import load_yaml, pop_custom_fields, set_custom_fields_values
from tenancy.models import Tenant
from virtualization.models import Cluster, VirtualMachine

virtual_machines = load_yaml("/opt/netbox/initializers/virtual_machines.yml")

if virtual_machines is None:
    sys.exit()

required_assocs = {"cluster": (Cluster, "name")}

optional_assocs = {
    "tenant": (Tenant, "name"),
    "platform": (Platform, "name"),
    "role": (DeviceRole, "name"),
}

for params in virtual_machines:
    custom_field_data = pop_custom_fields(params)

    # primary ips are handled later in `270_primary_ips.py`
    params.pop("primary_ip4", None)
    params.pop("primary_ip6", None)

    for assoc, details in required_assocs.items():
        model, field = details
        query = {field: params.pop(assoc)}

        params[assoc] = model.objects.get(**query)

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}

            params[assoc] = model.objects.get(**query)

    virtual_machine, created = VirtualMachine.objects.get_or_create(**params)

    if created:
        set_custom_fields_values(virtual_machine, custom_field_data)

        print("🖥️ Created virtual machine", virtual_machine.name)
