import sys

from dcim.models import Site
from ipam.models import VLAN, Role, VLANGroup
from startup_script_utils import (
    load_yaml,
    pop_custom_fields,
    set_custom_fields_values,
    split_params,
)
from tenancy.models import Tenant, TenantGroup

vlans = load_yaml("/opt/netbox/initializers/vlans.yml")

if vlans is None:
    sys.exit()

match_params = ["name", "vid"]
optional_assocs = {
    "site": (Site, "name"),
    "tenant": (Tenant, "name"),
    "tenant_group": (TenantGroup, "name"),
    "group": (VLANGroup, "name"),
    "role": (Role, "name"),
}

for params in vlans:
    custom_field_data = pop_custom_fields(params)

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}

            params[assoc] = model.objects.get(**query)

    matching_params, defaults = split_params(params, match_params)
    vlan, created = VLAN.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("🏠 Created VLAN", vlan.name)

    set_custom_fields_values(vlan, custom_field_data)
