import sys

from dcim.models import RackRole
from startup_script_utils import load_yaml, split_params
from utilities.choices import ColorChoices

rack_roles = load_yaml("/opt/netbox/initializers/rack_roles.yml")

if rack_roles is None:
    sys.exit()

for params in rack_roles:
    if "color" in params:
        color = params.pop("color")

        for color_tpl in ColorChoices:
            if color in color_tpl:
                params["color"] = color_tpl[0]

    matching_params, defaults = split_params(params)
    rack_role, created = RackRole.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("🎨 Created rack role", rack_role.name)
