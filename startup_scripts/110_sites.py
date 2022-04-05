import sys

from dcim.models import Region, Site
from startup_script_utils import (
    load_yaml,
    pop_custom_fields,
    set_custom_fields_values,
    split_params,
)
from tenancy.models import Tenant

sites = load_yaml("/opt/netbox/initializers/sites.yml")

if sites is None:
    sys.exit()

optional_assocs = {"region": (Region, "name"), "tenant": (Tenant, "name")}

for params in sites:
    custom_field_data = pop_custom_fields(params)

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}

            params[assoc] = model.objects.get(**query)

    matching_params, defaults = split_params(params)
    site, created = Site.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("📍 Created site", site.name)

    set_custom_fields_values(site, custom_field_data)
