import sys

from extras.models import Tag
from startup_script_utils import load_yaml, split_params
from utilities.choices import ColorChoices

tags = load_yaml("/opt/netbox/initializers/tags.yml")

if tags is None:
    sys.exit()

for params in tags:
    if "color" in params:
        color = params.pop("color")

        for color_tpl in ColorChoices:
            if color in color_tpl:
                params["color"] = color_tpl[0]

    matching_params, defaults = split_params(params)
    tag, created = Tag.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("🎨 Created Tag", tag.name)
