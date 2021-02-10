import sys

from dcim.models import Device
from ipam.models import IPAddress
from startup_script_utils import load_yaml
from virtualization.models import VirtualMachine


def link_primary_ip(assets, asset_model):
    for params in assets:
        primary_ip_fields = set(params) & {"primary_ip4", "primary_ip6"}
        if not primary_ip_fields:
            continue

        for assoc, details in optional_assocs.items():
            if assoc in params:
                model, field = details
                query = {field: params.pop(assoc)}

                try:
                    params[assoc] = model.objects.get(**query)
                except model.DoesNotExist:
                    primary_ip_fields -= {assoc}
                    print(f"⚠️ IP Address '{query[field]}' not found")

        asset = asset_model.objects.get(name=params["name"])
        for field in primary_ip_fields:
            if getattr(asset, field) != params[field]:
                setattr(asset, field, params[field])
                print(f"🔗 Define primary IP '{params[field].address}' on '{asset.name}'")
        asset.save()


devices = load_yaml("/opt/netbox/initializers/devices.yml")
virtual_machines = load_yaml("/opt/netbox/initializers/virtual_machines.yml")

optional_assocs = {
    "primary_ip4": (IPAddress, "address"),
    "primary_ip6": (IPAddress, "address"),
}

if devices is None and virtual_machines is None:
    sys.exit()
if devices is not None:
    link_primary_ip(devices, Device)
if virtual_machines is not None:
    link_primary_ip(virtual_machines, VirtualMachine)
