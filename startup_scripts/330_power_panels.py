import sys

from dcim.models import Location, PowerPanel, Site
from startup_script_utils import load_yaml, pop_custom_fields, set_custom_fields_values

power_panels = load_yaml("/opt/netbox/initializers/power_panels.yml")

if power_panels is None:
    sys.exit()

required_assocs = {"site": (Site, "name")}

optional_assocs = {"location": (Location, "name")}

for params in power_panels:
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

    power_panel, created = PowerPanel.objects.get_or_create(**params)

    if created:
        set_custom_fields_values(power_panel, custom_field_data)

        print("⚡ Created Power Panel", power_panel.site, power_panel.name)
