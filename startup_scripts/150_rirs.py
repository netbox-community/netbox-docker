from ipam.models import RIR
from startup_script_utils import load_yaml
import sys

rirs = load_yaml('/opt/netbox/initializers/rirs.yml')

if not rirs is None:

  for params in rirs:
    rir, created = RIR.objects.get_or_create(**params)

    if created:
      print("🗺️ Created RIR", rir.name)
