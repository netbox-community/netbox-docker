from dcim.models import DeviceRole
from ruamel.yaml import YAML
from utilities.forms import COLOR_CHOICES

from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/device_roles.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml=YAML(typ='safe')
  device_roles = yaml.load(stream)

  if device_roles is not None:
    for params in device_roles:

      if 'color' in params:
        color = params.pop('color')

        for color_tpl in COLOR_CHOICES:
          if color in color_tpl:
            params['color'] = color_tpl[0]

      device_role, created = DeviceRole.objects.get_or_create(**params)

      if created:
        print("🎨 Created device role", device_role.name)
