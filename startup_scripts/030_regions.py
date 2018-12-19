from dcim.models import Region
from ruamel.yaml import YAML
from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/regions.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml=YAML(typ='safe')
  regions = yaml.load(stream)

  optional_assocs = {
    'parent': (Region, 'name')
  }

  if regions is not None:
    for params in regions:

      for assoc, details in optional_assocs.items():
        if assoc in params:
          model, field = details
          query = { field: params.pop(assoc) }

          params[assoc] = model.objects.get(**query)

      region, created = Region.objects.get_or_create(**params)

      if created:
        print("🌐 Created region", region.name)
