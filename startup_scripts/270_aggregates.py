import sys

from ipam.models import RIR, Aggregate
from netaddr import IPNetwork
from startup_script_utils import (
    load_yaml,
    pop_custom_fields,
    set_custom_fields_values,
    split_params,
)
from tenancy.models import Tenant

aggregates = load_yaml("/opt/netbox/initializers/aggregates.yml")

if aggregates is None:
    sys.exit()

match_params = ["prefix", "rir"]
required_assocs = {"rir": (RIR, "name")}
optional_assocs = {
    "tenant": (Tenant, "name"),
}

for params in aggregates:
    custom_field_data = pop_custom_fields(params)

    params["prefix"] = IPNetwork(params["prefix"])

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
    aggregate, created = Aggregate.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("🗞️ Created Aggregate", aggregate.prefix)

    set_custom_fields_values(aggregate, custom_field_data)
