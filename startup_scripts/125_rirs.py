from ipam.models import RIR
from ruamel.yaml import YAML
from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/rirs.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml = YAML(typ='safe')
  rirs = yaml.load(stream)

  if rirs is not None:
    for params in rirs:
      rir, created = RIR.objects.get_or_create(**params)

      if created:
        print("Created RIR", rir.name)
