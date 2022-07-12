import sys

from dcim.models import PowerFeed, PowerPanel, Rack
from startup_script_utils import (
    load_yaml,
    pop_custom_fields,
    set_custom_fields_values,
    split_params,
)

power_feeds = load_yaml("/opt/netbox/initializers/power_feeds.yml")

if power_feeds is None:
    sys.exit()

match_params = ["name", "power_panel"]
required_assocs = {"power_panel": (PowerPanel, "name")}
optional_assocs = {"rack": (Rack, "name")}

for params in power_feeds:
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
    power_feed, created = PowerFeed.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("⚡ Created Power Feed", power_feed.name)

    set_custom_fields_values(power_feed, custom_field_data)
