import sys

from dcim.models import Manufacturer
from startup_script_utils import load_yaml, split_params

manufacturers = load_yaml("/opt/netbox/initializers/manufacturers.yml")

if manufacturers is None:
    sys.exit()

for params in manufacturers:
    matching_params, defaults = split_params(params)
    manufacturer, created = Manufacturer.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("🏭 Created Manufacturer", manufacturer.name)
