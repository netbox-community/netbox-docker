import sys

from dcim.models import Location, Site
from startup_script_utils import load_yaml, split_params

rack_groups = load_yaml("/opt/netbox/initializers/locations.yml")

if rack_groups is None:
    sys.exit()

match_params = ["name", "slug", "site"]
required_assocs = {"site": (Site, "name")}

for params in rack_groups:

    for assoc, details in required_assocs.items():
        model, field = details
        query = {field: params.pop(assoc)}
        params[assoc] = model.objects.get(**query)

    matching_params, defaults = split_params(params, match_params)
    location, created = Location.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("🎨 Created location", location.name)
