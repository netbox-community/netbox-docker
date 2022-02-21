import sys

from ipam.models import VRF
from startup_script_utils import load_yaml, pop_custom_fields, set_custom_fields_values
from tenancy.models import Tenant

vrfs = load_yaml("/opt/netbox/initializers/vrfs.yml")

if vrfs is None:
    sys.exit()

optional_assocs = {"tenant": (Tenant, "name")}

for params in vrfs:
    custom_field_data = pop_custom_fields(params)

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}

            params[assoc] = model.objects.get(**query)

    vrf, created = VRF.objects.get_or_create(**params)

    if created:
        set_custom_fields_values(vrf, custom_field_data)

        print("📦 Created VRF", vrf.name)
