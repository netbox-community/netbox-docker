import sys

from dcim.models import Site
from ipam.models import VLAN, VRF, Prefix, Role
from netaddr import IPNetwork
from startup_script_utils import (
    load_yaml,
    pop_custom_fields,
    set_custom_fields_values,
    split_params,
)
from tenancy.models import Tenant, TenantGroup

prefixes = load_yaml("/opt/netbox/initializers/prefixes.yml")

if prefixes is None:
    sys.exit()

match_params = ["prefix", "site", "vrf", "vlan"]
optional_assocs = {
    "site": (Site, "name"),
    "tenant": (Tenant, "name"),
    "tenant_group": (TenantGroup, "name"),
    "vlan": (VLAN, "name"),
    "role": (Role, "name"),
    "vrf": (VRF, "name"),
}

for params in prefixes:
    custom_field_data = pop_custom_fields(params)

    params["prefix"] = IPNetwork(params["prefix"])

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}
            params[assoc] = model.objects.get(**query)

    matching_params, defaults = split_params(params, match_params)
    prefix, created = Prefix.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("📌 Created Prefix", prefix.prefix)

    set_custom_fields_values(prefix, custom_field_data)
