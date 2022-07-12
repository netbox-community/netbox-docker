import sys

from dcim.models import Manufacturer, Platform
from startup_script_utils import load_yaml, split_params

platforms = load_yaml("/opt/netbox/initializers/platforms.yml")

if platforms is None:
    sys.exit()

optional_assocs = {
    "manufacturer": (Manufacturer, "name"),
}

for params in platforms:

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}

            params[assoc] = model.objects.get(**query)

    matching_params, defaults = split_params(params)
    platform, created = Platform.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("💾 Created platform", platform.name)
