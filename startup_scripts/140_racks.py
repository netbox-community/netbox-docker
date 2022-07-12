import sys

from dcim.models import Location, Rack, RackRole, Site
from startup_script_utils import (
    load_yaml,
    pop_custom_fields,
    set_custom_fields_values,
    split_params,
)
from tenancy.models import Tenant

racks = load_yaml("/opt/netbox/initializers/racks.yml")

if racks is None:
    sys.exit()

match_params = ["name", "site"]
required_assocs = {"site": (Site, "name")}
optional_assocs = {
    "role": (RackRole, "name"),
    "tenant": (Tenant, "name"),
    "location": (Location, "name"),
}

for params in racks:
    custom_field_data = pop_custom_fields(params)

    for assoc, details in required_assocs.items():
        model, field = details
        query = {field: params.pop(assoc)}

        params[assoc] = model.objects.get(**query)

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}

            params[assoc] = model.objects.get(**query)

    matching_params, defaults = split_params(params, match_params)
    rack, created = Rack.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("🔳 Created rack", rack.site, rack.name)

    set_custom_fields_values(rack, custom_field_data)
