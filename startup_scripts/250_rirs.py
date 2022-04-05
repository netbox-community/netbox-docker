import sys

from ipam.models import RIR
from startup_script_utils import load_yaml, split_params

rirs = load_yaml("/opt/netbox/initializers/rirs.yml")

if rirs is None:
    sys.exit()

for params in rirs:
    matching_params, defaults = split_params(params)
    rir, created = RIR.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("🗺️ Created RIR", rir.name)
