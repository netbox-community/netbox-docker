import sys

from ipam.models import VRF
from startup_script_utils import (
    load_yaml,
    pop_custom_fields,
    set_custom_fields_values,
    split_params,
)
from tenancy.models import Tenant

vrfs = load_yaml("/opt/netbox/initializers/vrfs.yml")

if vrfs is None:
    sys.exit()

match_params = ["name", "rd"]
optional_assocs = {"tenant": (Tenant, "name")}

for params in vrfs:
    custom_field_data = pop_custom_fields(params)

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}

            params[assoc] = model.objects.get(**query)

    matching_params, defaults = split_params(params)
    vrf, created = VRF.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("📦 Created VRF", vrf.name)

    set_custom_fields_values(vrf, custom_field_data)
