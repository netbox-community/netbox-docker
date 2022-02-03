import sys

from ipam.models import RIR
from startup_script_utils import load_yaml

rirs = load_yaml("/opt/netbox/initializers/rirs.yml")

if rirs is None:
    sys.exit()

for params in rirs:
    rir, created = RIR.objects.get_or_create(**params)

    if created:
        print("🗺️ Created RIR", rir.name)
