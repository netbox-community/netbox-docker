from dcim.models import DeviceRole
from utilities.forms import COLOR_CHOICES
from startup_script_utils import load_yaml
import sys

device_roles = load_yaml('/opt/netbox/initializers/device_roles.yml')

if not device_roles is None:

  for params in device_roles:

    if 'color' in params:
      color = params.pop('color')

      for color_tpl in COLOR_CHOICES:
        if color in color_tpl:
          params['color'] = color_tpl[0]

    device_role, created = DeviceRole.objects.get_or_create(**params)

    if created:
      print("🎨 Created device role", device_role.name)
