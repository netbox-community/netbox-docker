import sys

from dcim.models import Device
from ipam.models import Service
from startup_script_utils import load_yaml
from virtualization.models import VirtualMachine

services = load_yaml("/opt/netbox/initializers/services.yml")

if services is None:
    sys.exit()

optional_assocs = {
    "device": (Device, "name"),
    "virtual_machine": (VirtualMachine, "name"),
}

for params in services:

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}

            params[assoc] = model.objects.get(**query)

    service, created = Service.objects.get_or_create(**params)

    if created:
        print("🧰 Created Service", service.name)
