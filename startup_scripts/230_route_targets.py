import sys

from ipam.models import RouteTarget
from startup_script_utils import (
    load_yaml,
    pop_custom_fields,
    set_custom_fields_values,
    split_params,
)
from tenancy.models import Tenant

route_targets = load_yaml("/opt/netbox/initializers/route_targets.yml")

if route_targets is None:
    sys.exit()

optional_assocs = {"tenant": (Tenant, "name")}

for params in route_targets:
    custom_field_data = pop_custom_fields(params)

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}

            params[assoc] = model.objects.get(**query)

    matching_params, defaults = split_params(params)
    route_target, created = RouteTarget.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("🎯 Created Route Target", route_target.name)

    set_custom_fields_values(route_target, custom_field_data)
