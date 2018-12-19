from dcim.models import Manufacturer, Platform
from ruamel.yaml import YAML

from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/platforms.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml = YAML(typ='safe')
  platforms = yaml.load(stream)

  optional_assocs = {
    'manufacturer': (Manufacturer, 'name'),
  }

  if platforms is not None:
    for params in platforms:

      for assoc, details in optional_assocs.items():
        if assoc in params:
          model, field = details
          query = { field: params.pop(assoc) }

          params[assoc] = model.objects.get(**query)

      platform, created = Platform.objects.get_or_create(**params)

      if created:
        print("💾 Created platform", platform.name)
