from dcim.models import Site,RackGroup
from ruamel.yaml import YAML

from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/rack_groups.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml=YAML(typ='safe')
  rack_groups= yaml.load(stream)

  required_assocs = {
    'site': (Site, 'name')
  }

  if rack_groups is not None:
    for params in rack_groups:

      for assoc, details in required_assocs.items():
        model, field = details
        query = { field: params.pop(assoc) }
        params[assoc] = model.objects.get(**query)

      rack_group, created = RackGroup.objects.get_or_create(**params)

      if created:
        print("🎨 Created rack group", rack_group.name)

